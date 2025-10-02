import Flutter
import UIKit
import GoogleMaps
import GoogleMapsUtils
import QuartzCore

class MapViewController: NSObject, FlutterPlatformView, GMSMapViewDelegate, GMUClusterRendererDelegate {
  private let mapView: GMSMapView
  private let channel: FlutterMethodChannel
  private let iconCache = NSCache<NSString, UIImage>()
  private let iconDiskCacheURL: URL
  private var markers: [String: GMSMarker] = [:]
  private var polylines: [String: GMSPolyline] = [:]
  private var clusterManager: GMUClusterManager?
  private var clusteringEnabled: Bool = false
  private var clusterItems: [String: GmnsClusterItem] = [:]
  private var heatmap: GMUHeatmapTileLayer?
  private var tileOverlays: [String: GMSTileLayer] = [:]

  // Cluster item model
  class GmnsClusterItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    let id: String
    let title: String?
    let snippet: String?
    let iconUrl: String?
    let iconDp: CGFloat
    let anchorU: CGFloat
    let anchorV: CGFloat
    let rotation: Double
    let zIndex: Double
    let draggable: Bool

    init(id: String, position: CLLocationCoordinate2D, title: String?, snippet: String?, iconUrl: String?, iconDp: CGFloat, anchorU: CGFloat, anchorV: CGFloat, rotation: Double, zIndex: Double, draggable: Bool) {
      self.id = id
      self.position = position
      self.title = title
      self.snippet = snippet
      self.iconUrl = iconUrl
      self.iconDp = iconDp
      self.anchorU = anchorU
      self.anchorV = anchorV
      self.rotation = rotation
      self.zIndex = zIndex
      self.draggable = draggable
    }
  }

  init(frame: CGRect, viewId: Int64, args: [String: Any]?, messenger: FlutterBinaryMessenger) {
    let camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 14)
    mapView = GMSMapView(frame: frame, camera: camera)
    mapView.alpha = 0
    channel = FlutterMethodChannel(name: "google_maps_native_sdk/\(viewId)", binaryMessenger: messenger)
    // Disk cache dir (initialize before super.init)
    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let iconDir = caches.appendingPathComponent("gmns_icons", isDirectory: true)
    self.iconDiskCacheURL = iconDir
    try? FileManager.default.createDirectory(at: iconDir, withIntermediateDirectories: true)

    super.init()

    channel.setMethodCallHandler(handle)
    mapView.delegate = self
    if let params = args { applyInitial(params: params) }
  }

  func view() -> UIView { mapView }

  private func applyInitial(params: [String: Any]) {
    if let cam = params["initialCameraPosition"] as? [String: Any],
       let t = cam["target"] as? [String: Any],
       let lat = t["lat"] as? CLLocationDegrees,
       let lng = t["lng"] as? CLLocationDegrees {
      let current = mapView.camera
      let zoom = (cam["zoom"] as? Double).map { Float($0) } ?? current.zoom
      let tilt = (cam["tilt"] as? Double) ?? current.viewingAngle
      let bearing = (cam["bearing"] as? Double).map { CLLocationDirection($0) } ?? current.bearing
      mapView.camera = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: lat, longitude: lng), zoom: zoom, bearing: bearing, viewingAngle: tilt)
    }
    if let traffic = params["trafficEnabled"] as? Bool { mapView.isTrafficEnabled = traffic }
    if let buildings = params["buildingsEnabled"] as? Bool { mapView.isBuildingsEnabled = buildings }
    if let myLoc = params["myLocationEnabled"] as? Bool { mapView.isMyLocationEnabled = myLoc }
    if let indoor = params["indoorEnabled"] as? Bool { mapView.isIndoorEnabled = indoor }
    if let mapId = params["mapId"] as? String, !mapId.isEmpty { mapView.mapID = GMSMapID(mapID: mapId) }
    if let pad = params["padding"] as? [String: Any] {
      let l = (pad["left"] as? CGFloat) ?? 0
      let t = (pad["top"] as? CGFloat) ?? 0
      let r = (pad["right"] as? CGFloat) ?? 0
      let b = (pad["bottom"] as? CGFloat) ?? 0
      mapView.padding = UIEdgeInsets(top: t, left: l, bottom: b, right: r)
    }
    if let style = params["mapStyle"] as? String, !style.isEmpty {
      do { try mapView.mapStyle = GMSMapStyle(jsonString: style) } catch { print("GMNS: invalid style") }
    }
    if let ce = params["clusterEnabled"] as? Bool, ce { setClusteringEnabled(true) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "map#setClusteringEnabled":
      if let enabled = call.arguments as? Bool { setClusteringEnabled(enabled) }
      result(nil)
    case "map#setIndoorEnabled":
      if let enabled = call.arguments as? Bool { mapView.isIndoorEnabled = enabled }
      result(nil)
    case "map#setIndoorLevelPickerEnabled":
      // iOS does not expose indoor level picker toggle separately
      result(FlutterMethodNotImplemented)
    case "map#setMapId":
      if let mapId = call.arguments as? String { mapView.mapID = GMSMapID(mapID: mapId) }
      result(nil)
    case "heatmap#set":
      if let args = call.arguments as? [String: Any], let pts = args["points"] as? [[String: Any]] {
        var data: [GMUWeightedLatLng] = []
        for pt in pts {
          if let lat = pt["lat"] as? CLLocationDegrees, let lng = pt["lng"] as? CLLocationDegrees {
            data.append(GMUWeightedLatLng(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), intensity: 1))
          }
        }
        if heatmap == nil { heatmap = GMUHeatmapTileLayer() }
        heatmap!.weightedData = data
        if let radius = args["radius"] as? UInt { heatmap!.radius = radius }
        if let opacity = args["opacity"] as? Double { heatmap!.opacity = Float(opacity) }
        heatmap!.map = mapView
      }
      result(nil)
    case "heatmap#clear":
      heatmap?.map = nil
      heatmap = nil
      result(nil)
    case "tiles#add":
      if let args = call.arguments as? [String: Any], let id = args["id"] as? String, let template = args["template"] as? String {
        let tile = GMSTileLayer()
        tile.tileSize = (args["tileSize"] as? UInt32) ?? 256
        let opacity = (args["opacity"] as? Double) ?? 1.0
        tile.opacity = Float(opacity)
        let z = (args["zIndex"] as? Double) ?? 0
        tile.zIndex = Int32(z)
        tile.tileURLConstructor = { (x, y, zoom) -> URL? in
          var url = template.replacingOccurrences(of: "{x}", with: String(x))
          url = url.replacingOccurrences(of: "{y}", with: String(y))
          url = url.replacingOccurrences(of: "{z}", with: String(zoom))
          return URL(string: url)
        }
        tile.map = self.mapView
        if let old = tileOverlays[id] { old.map = nil }
        tileOverlays[id] = tile
      }
      result(nil)
    case "tiles#remove":
      if let id = call.arguments as? String, let t = tileOverlays.removeValue(forKey: id) { t.map = nil }
      result(nil)
    case "tiles#clear":
      for (_, t) in tileOverlays { t.map = nil }
      tileOverlays.removeAll()
      result(nil)
    case "map#animateCamera":
      if let args = call.arguments as? [String: Any],
         let t = args["target"] as? [String: Any],
         let lat = t["lat"] as? CLLocationDegrees,
         let lng = t["lng"] as? CLLocationDegrees {
        let current = mapView.camera
        let zoom = (args["zoom"] as? Double).map { Float($0) } ?? current.zoom
        let tilt = (args["tilt"] as? Double) ?? current.viewingAngle
        let bearing = (args["bearing"] as? Double).map { CLLocationDirection($0) } ?? current.bearing
        let cam = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: lat, longitude: lng), zoom: zoom, bearing: bearing, viewingAngle: tilt)
        if let durationMs = args["durationMs"] as? Int, durationMs > 0 {
          CATransaction.begin()
          CATransaction.setAnimationDuration(Double(durationMs) / 1000.0)
          mapView.animate(to: cam)
          CATransaction.commit()
        } else {
          mapView.animate(to: cam)
        }
      }
      result(nil)
    case "map#moveCamera":
      if let args = call.arguments as? [String: Any],
         let t = args["target"] as? [String: Any],
         let lat = t["lat"] as? CLLocationDegrees,
         let lng = t["lng"] as? CLLocationDegrees {
        let current = mapView.camera
        let zoom = (args["zoom"] as? Double).map { Float($0) } ?? current.zoom
        let tilt = (args["tilt"] as? Double) ?? current.viewingAngle
        let bearing = (args["bearing"] as? Double).map { CLLocationDirection($0) } ?? current.bearing
        mapView.camera = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: lat, longitude: lng), zoom: zoom, bearing: bearing, viewingAngle: tilt)
      }
      result(nil)
    case "map#animateToBounds":
      if let args = call.arguments as? [String: Any],
         let ne = args["ne"] as? [String: Any], let sw = args["sw"] as? [String: Any],
         let neLat = ne["lat"] as? CLLocationDegrees, let neLng = ne["lng"] as? CLLocationDegrees,
         let swLat = sw["lat"] as? CLLocationDegrees, let swLng = sw["lng"] as? CLLocationDegrees {
        let bounds = GMSCoordinateBounds(coordinate: CLLocationCoordinate2D(latitude: swLat, longitude: swLng),
                                         coordinate: CLLocationCoordinate2D(latitude: neLat, longitude: neLng))
        let pad = (args["padding"] as? CGFloat) ?? 50
        mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: pad))
      }
      result(nil)
    case "map#setTrafficEnabled":
      if let enabled = call.arguments as? Bool { mapView.isTrafficEnabled = enabled }
      result(nil)
    case "map#setMyLocationEnabled":
      if let enabled = call.arguments as? Bool { mapView.isMyLocationEnabled = enabled }
      result(nil)
    case "map#setPadding":
      if let pad = call.arguments as? [String: Any] {
        let l = (pad["left"] as? CGFloat) ?? 0
        let t = (pad["top"] as? CGFloat) ?? 0
        let r = (pad["right"] as? CGFloat) ?? 0
        let b = (pad["bottom"] as? CGFloat) ?? 0
        mapView.padding = UIEdgeInsets(top: t, left: l, bottom: b, right: r)
      }
      result(nil)
    case "map#setStyle":
      if let style = call.arguments as? String, !style.isEmpty { do { try mapView.mapStyle = GMSMapStyle(jsonString: style) } catch {} }
      result(true)
    case "markers#add":
      if let m = call.arguments as? [String: Any] {
        if clusteringEnabled { addClusterItem(m); clusterManager?.cluster() }
        else { addMarker(m) }
      }
      result(nil)
    case "markers#update":
      if let m = call.arguments as? [String: Any], let id = m["id"] as? String {
        if clusteringEnabled {
          // Rebuild item map and re-cluster
          if let item = clusterItems[id] {
            if let pos = m["position"] as? [String: Any], let lat = pos["lat"] as? CLLocationDegrees, let lng = pos["lng"] as? CLLocationDegrees { item.position = CLLocationCoordinate2D(latitude: lat, longitude: lng) }
            if let rotation = m["rotation"] as? Double { item.rotation = rotation }
          }
          recluster()
        } else if let marker = markers[id] {
          if let pos = m["position"] as? [String: Any], let lat = pos["lat"] as? CLLocationDegrees, let lng = pos["lng"] as? CLLocationDegrees { marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lng) }
          if let rotation = m["rotation"] as? Double { marker.rotation = rotation }
        }
      }
      result(nil)
    case "markers#setIconBytes":
      if let m = call.arguments as? [String: Any], let id = m["id"] as? String, let marker = markers[id] {
        if let data = m["bytes"] as? FlutterStandardTypedData {
          if let img = UIImage(data: data.data) {
            let resized = self.resize(img, maxPoints: 48)
            marker.icon = resized
          }
        }
        if let au = m["anchorU"] as? CGFloat, let av = m["anchorV"] as? CGFloat {
          marker.groundAnchor = CGPoint(x: au, y: av)
        }
      }
      result(nil)
    case "markers#remove":
      if let id = call.arguments as? String {
        if clusteringEnabled {
          clusterItems.removeValue(forKey: id)
          recluster()
        } else if let marker = markers.removeValue(forKey: id) { marker.map = nil }
      }
      result(nil)
    case "markers#clear":
      if clusteringEnabled {
        clusterItems.removeAll()
        recluster()
      }
      markers.values.forEach { $0.map = nil }
      markers.removeAll()
      result(nil)
    case "polylines#add":
      if let p = call.arguments as? [String: Any] { addPolyline(p) }
      result(nil)
    case "polylines#remove":
      if let id = call.arguments as? String, let poly = polylines.removeValue(forKey: id) { poly.map = nil }
      result(nil)
    case "polylines#clear":
      polylines.values.forEach { $0.map = nil }
      polylines.removeAll()
      result(nil)
    case "polylines#updatePoints":
      if let p = call.arguments as? [String: Any], let id = p["id"] as? String, let pts = p["points"] as? [[String: Any]], let poly = polylines[id] {
        let path = GMSMutablePath()
        for pt in pts {
          if let lat = pt["lat"] as? CLLocationDegrees, let lng = pt["lng"] as? CLLocationDegrees {
            path.add(CLLocationCoordinate2D(latitude: lat, longitude: lng))
          }
        }
        poly.path = path
      }
      result(nil)
    case "map#takeSnapshot":
      let renderer = UIGraphicsImageRenderer(bounds: mapView.bounds)
      let img = renderer.image { ctx in mapView.layer.render(in: ctx.cgContext) }
      if let data = img.pngData() { result(FlutterStandardTypedData(bytes: data)) } else { result(nil) }
    case "map#dispose":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setClusteringEnabled(_ enabled: Bool) {
    clusteringEnabled = enabled
    if enabled {
      if clusterManager == nil {
        let iconGen = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGen)
        renderer.delegate = self
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        clusterManager?.setMapDelegate(self)
      }
      // Migrate existing markers to cluster items
      if !markers.isEmpty {
        for (id, marker) in markers {
          let item = GmnsClusterItem(
            id: id,
            position: marker.position,
            title: marker.title,
            snippet: marker.snippet,
            iconUrl: nil,
            iconDp: 48,
            anchorU: marker.groundAnchor.x,
            anchorV: marker.groundAnchor.y,
            rotation: marker.rotation,
            zIndex: Double(marker.zIndex),
            draggable: marker.isDraggable
          )
          clusterItems[id] = item
        }
        markers.values.forEach { $0.map = nil }
        markers.removeAll()
        recluster()
      } else {
        recluster()
      }
    } else {
      // Disable clustering: render items as normal markers
      if let mgr = clusterManager { mgr.clearItems() }
      clusterManager = nil
      for (_, item) in clusterItems {
        let m: [String: Any] = [
          "id": item.id,
          "position": ["lat": item.position.latitude, "lng": item.position.longitude],
          "title": item.title as Any,
          "snippet": item.snippet as Any,
          "iconUrl": item.iconUrl as Any,
          "anchorU": item.anchorU,
          "anchorV": item.anchorV,
          "rotation": item.rotation,
          "draggable": item.draggable,
          "zIndex": item.zIndex,
        ]
        addMarker(m)
      }
      clusterItems.removeAll()
    }
  }

  private func addClusterItem(_ m: [String: Any]) {
    guard let id = m["id"] as? String,
          let pos = m["position"] as? [String: Any],
          let lat = pos["lat"] as? CLLocationDegrees,
          let lng = pos["lng"] as? CLLocationDegrees else { return }
    let item = GmnsClusterItem(
      id: id,
      position: CLLocationCoordinate2D(latitude: lat, longitude: lng),
      title: m["title"] as? String,
      snippet: m["snippet"] as? String,
      iconUrl: (m["iconUrl"] as? String),
      iconDp: (m["iconDp"] as? CGFloat) ?? 48,
      anchorU: (m["anchorU"] as? CGFloat) ?? 0.5,
      anchorV: (m["anchorV"] as? CGFloat) ?? 0.62,
      rotation: (m["rotation"] as? Double) ?? 0,
      zIndex: (m["zIndex"] as? Double) ?? 0,
      draggable: (m["draggable"] as? Bool) ?? false
    )
    clusterItems[id] = item
  }

  private func recluster() {
    guard let mgr = clusterManager else { return }
    mgr.clearItems()
    for (_, item) in clusterItems { mgr.add(item) }
    mgr.cluster()
  }

  // GMUClusterRendererDelegate
  func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
    if let item = marker.userData as? GmnsClusterItem {
      if let iconUrl = item.iconUrl, !iconUrl.isEmpty {
        let key = "\(iconUrl)#dp=\(Int(round(item.iconDp)))" as NSString
        if let cached = iconCache.object(forKey: key) {
          marker.icon = cached
        } else {
          loadIcon(url: iconUrl, maxPoints: item.iconDp) { [weak self, weak marker] img in
            if let img = img { self?.iconCache.setObject(img, forKey: key); marker?.icon = img }
          }
        }
      }
      marker.groundAnchor = CGPoint(x: item.anchorU, y: item.anchorV)
      marker.rotation = item.rotation
      marker.isDraggable = item.draggable
      marker.zIndex = Int32(item.zIndex)
      marker.title = item.title
      marker.snippet = item.snippet
      markers[item.id] = marker
    }
  }

  private func addMarker(_ m: [String: Any]) {
    guard let id = m["id"] as? String,
          let pos = m["position"] as? [String: Any],
          let lat = pos["lat"] as? CLLocationDegrees,
          let lng = pos["lng"] as? CLLocationDegrees else { return }

    markers[id]?.map = nil

    let mk = GMSMarker(position: CLLocationCoordinate2D(latitude: lat, longitude: lng))
    if let title = m["title"] as? String { mk.title = title }
    if let snippet = m["snippet"] as? String { mk.snippet = snippet }
    if let rotation = m["rotation"] as? Double { mk.rotation = rotation }
    if let draggable = m["draggable"] as? Bool { mk.isDraggable = draggable }
    if let zIndex = m["zIndex"] as? Double { mk.zIndex = Int32(zIndex) }

    if let anchorU = m["anchorU"] as? CGFloat, let anchorV = m["anchorV"] as? CGFloat { mk.groundAnchor = CGPoint(x: anchorU, y: anchorV) }

    if let iconUrl = m["iconUrl"] as? String, !iconUrl.isEmpty {
      let iconDp = (m["iconDp"] as? CGFloat) ?? 48
      let key = "\(iconUrl)#dp=\(Int(round(iconDp)))" as NSString
      if let cached = iconCache.object(forKey: key) { mk.icon = cached }
      else {
        loadIcon(url: iconUrl, maxPoints: iconDp) { [weak self, weak mk] img in
          if let img = img {
            self?.iconCache.setObject(img, forKey: key)
            mk?.icon = img
          }
        }
      }
    }
    mk.map = mapView
    markers[id] = mk
  }

  private func addPolyline(_ p: [String: Any]) {
    guard let id = p["id"] as? String, let pts = p["points"] as? [[String: Any]] else { return }
    polylines[id]?.map = nil
    let path = GMSMutablePath()
    for pt in pts { if let lat = pt["lat"] as? CLLocationDegrees, let lng = pt["lng"] as? CLLocationDegrees { path.add(CLLocationCoordinate2D(latitude: lat, longitude: lng)) } }
    let poly = GMSPolyline(path: path)
    if let colorVal = p["color"] as? UInt { poly.strokeColor = UIColor(rgb: colorVal) }
    if let width = p["width"] as? CGFloat { poly.strokeWidth = width }
    if let geodesic = p["geodesic"] as? Bool { poly.geodesic = geodesic }
    if let dotted = p["dotted"] as? Bool, dotted { poly.spans = [GMSStyleSpan(style: GMSStrokeStyle.solidColor(.clear)), GMSStyleSpan(style: GMSStrokeStyle.solidColor(poly.strokeColor))] }
    poly.map = mapView
    polylines[id] = poly
  }

  // Marker tap
  func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
    if let entry = markers.first(where: { $0.value == marker }) { channel.invokeMethod("event#onMarkerTap", arguments: entry.key) }
    return false
  }

  // Helpers
  private func loadIcon(url: String, maxPoints: CGFloat = 48, done: @escaping (UIImage?) -> Void) {
    // data: URL support
    if url.hasPrefix("data:") {
      if let comma = url.firstIndex(of: ",") {
        let meta = String(url[url.index(url.startIndex, offsetBy: 5)..<comma])
        let dataPart = String(url[url.index(after: comma)...])
        var data: Data? = nil
        if meta.contains("base64") { data = Data(base64Encoded: dataPart) }
        else { data = dataPart.data(using: .utf8) }
        if let d = data, let decoded = UIImage(data: d) {
          let resized = self.resize(decoded, maxPoints: maxPoints)
          DispatchQueue.main.async { done(resized) }
          return
        }
      }
      DispatchQueue.main.async { done(nil) }
      return
    }

    // asset:// support (Flutter assets)
    if url.hasPrefix("asset://") {
      let assetPath = String(url.dropFirst("asset://".count))
      let key = FlutterDartProject.lookupKey(forAsset: assetPath)
      if let path = Bundle.main.path(forResource: key, ofType: nil),
         let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
         let img = UIImage(data: data) {
        let resized = self.resize(img, maxPoints: maxPoints)
        DispatchQueue.main.async { done(resized) }
      } else {
        DispatchQueue.main.async { done(nil) }
      }
      return
    }

    // Disk-cached network image
    let name = djb2(url + "#dp=\(Int(round(maxPoints)))") + ".png"
    let fileURL = iconDiskCacheURL.appendingPathComponent(name)
    if let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) {
      done(img)
      return
    }
    guard let u = URL(string: url) else { done(nil); return }
    let task = URLSession.shared.dataTask(with: u) { data, _, _ in
      var img: UIImage? = nil
      if let data = data, let decoded = UIImage(data: data) {
        let resized = self.resize(decoded, maxPoints: maxPoints)
        img = resized
        if let png = resized.pngData() { try? png.write(to: fileURL) }
      }
      DispatchQueue.main.async { done(img) }
    }
    task.resume()
  }

  private func resize(_ image: UIImage, maxPoints: CGFloat) -> UIImage {
    let scale = UIScreen.main.scale
    let maxPx = maxPoints * scale
    let w = image.size.width * image.scale
    let h = image.size.height * image.scale
    let maxSide = max(w, h)
    if maxSide <= maxPx { return image }
    let factor = maxPx / maxSide
    let newPxW = max(1, Int(round(w * factor)))
    let newPxH = max(1, Int(round(h * factor)))
    let newSize = CGSize(width: CGFloat(newPxW) / scale, height: CGFloat(newPxH) / scale)
    UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let out = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return out ?? image
  }

  private func djb2(_ s: String) -> String {
    var hash: UInt64 = 5381
    for u in s.utf8 { hash = ((hash << 5) &+ hash) &+ UInt64(u) }
    return String(format: "%016llx", hash)
  }
}

private extension UIColor {
  convenience init(rgb: UInt) {
    let a = CGFloat((rgb >> 24) & 0xFF) / 255.0
    let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let b = CGFloat(rgb & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b, alpha: a)
  }
}

// Map reveal when content is ready
extension MapViewController {
  func mapViewSnapshotReady(_ mapView: GMSMapView) {
    self.mapView.alpha = 1
    channel.invokeMethod("event#onMapLoaded", arguments: nil)
  }
}
