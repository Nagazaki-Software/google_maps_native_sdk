import Flutter
import UIKit
import GoogleMaps
import GoogleMapsUtils

class MapViewController: NSObject, FlutterPlatformView, GMSMapViewDelegate {
  private let mapView: GMSMapView
  private let channel: FlutterMethodChannel
  private let iconCache = NSCache<NSString, UIImage>()
  private let iconDiskCacheURL: URL
  private var markers: [String: GMSMarker] = [:]
  private var polylines: [String: GMSPolyline] = [:]

  init(frame: CGRect, viewId: Int64, args: [String: Any]?, messenger: FlutterBinaryMessenger) {
    let camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 14)
    mapView = GMSMapView(frame: frame, camera: camera)
    channel = FlutterMethodChannel(name: "google_maps_native_sdk/\(viewId)", binaryMessenger: messenger)
    super.init()

    // Disk cache dir
    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    self.iconDiskCacheURL = caches.appendingPathComponent("gmns_icons", isDirectory: true)
    try? FileManager.default.createDirectory(at: self.iconDiskCacheURL, withIntermediateDirectories: true)

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
      let zoom = (cam["zoom"] as? Double) ?? 14
      mapView.camera = GMSCameraPosition(latitude: lat, longitude: lng, zoom: Float(zoom))
    }
    if let traffic = params["trafficEnabled"] as? Bool { mapView.isTrafficEnabled = traffic }
    if let buildings = params["buildingsEnabled"] as? Bool { mapView.buildingsEnabled = buildings }
    if let myLoc = params["myLocationEnabled"] as? Bool { mapView.isMyLocationEnabled = myLoc }
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
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "map#moveCamera":
      if let args = call.arguments as? [String: Any],
         let t = args["target"] as? [String: Any],
         let lat = t["lat"] as? CLLocationDegrees,
         let lng = t["lng"] as? CLLocationDegrees {
        let zoom = (args["zoom"] as? Double)
        if let zoom = zoom { mapView.camera = GMSCameraPosition(latitude: lat, longitude: lng, zoom: Float(zoom)) }
        else { mapView.camera = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: lat, longitude: lng), zoom: mapView.camera.zoom) }
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
      if let m = call.arguments as? [String: Any] { addMarker(m) }
      result(nil)
    case "markers#update":
      if let m = call.arguments as? [String: Any], let id = m["id"] as? String, let marker = markers[id] {
        if let pos = m["position"] as? [String: Any], let lat = pos["lat"] as? CLLocationDegrees, let lng = pos["lng"] as? CLLocationDegrees { marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lng) }
        if let rotation = m["rotation"] as? Double { marker.rotation = rotation }
      }
      result(nil)
    case "markers#remove":
      if let id = call.arguments as? String, let marker = markers.removeValue(forKey: id) { marker.map = nil }
      result(nil)
    case "markers#clear":
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
      if let cached = iconCache.object(forKey: iconUrl as NSString) { mk.icon = cached; }
      else { loadIcon(url: iconUrl) { [weak self, weak mk] img in if let img = img { self?.iconCache.setObject(img, forKey: iconUrl as NSString); mk?.icon = img } } }
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
  private func loadIcon(url: String, done: @escaping (UIImage?) -> Void) {
    let name = djb2(url) + ".png"
    let fileURL = iconDiskCacheURL.appendingPathComponent(name)
    if let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) {
      done(img)
      return
    }
    guard let u = URL(string: url) else { done(nil); return }
    let task = URLSession.shared.dataTask(with: u) { data, _, _ in
      var img: UIImage? = nil
      if let data = data, let decoded = UIImage(data: data) {
        img = decoded
        if let png = decoded.pngData() { try? png.write(to: fileURL) }
      }
      DispatchQueue.main.async { done(img) }
    }
    task.resume()
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
