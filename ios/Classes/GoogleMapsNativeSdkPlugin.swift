import Flutter
import UIKit
import GoogleMaps
import CoreLocation
import MapKit

public class GoogleMapsNativeSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = MapViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "google_maps_native_sdk/map_view")

    // Heading EventChannel
    let headingHandler = HeadingStreamHandler()
    let headingChannel = FlutterEventChannel(name: "google_maps_native_sdk/heading", binaryMessenger: registrar.messenger())
    headingChannel.setStreamHandler(headingHandler)

    // Navigation UI bridge
    let navCh = FlutterMethodChannel(name: "google_maps_native_sdk/nav_ui", binaryMessenger: registrar.messenger())
    let navBridge = NavUiBridge(registrar: registrar)
    navCh.setMethodCallHandler(navBridge.handle)
  }
}

class HeadingStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  override init() {
    super.init()
    manager.delegate = self
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    if CLLocationManager.headingAvailable() {
      manager.startUpdatingHeading()
    } else {
      sink?(FlutterError(code: "no_heading", message: "Heading not available", details: nil))
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    sink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    var deg = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    if deg < 0 { deg = 0 }
    sink?(deg)
  }
}

/// Bridge for launching a native Navigation UI when Navigation SDK is available.
class NavUiBridge: NSObject {
  private weak var registrar: FlutterPluginRegistrar?
  private static weak var presented: UIViewController?

  init(registrar: FlutterPluginRegistrar) { self.registrar = registrar }

  private func colorFromARGB(_ v: UInt) -> UIColor {
    let a = CGFloat((v >> 24) & 0xFF) / 255.0
    let r = CGFloat((v >> 16) & 0xFF) / 255.0
    let g = CGFloat((v >> 8) & 0xFF) / 255.0
    let b = CGFloat(v & 0xFF) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "nav_ui#isAvailable":
      // Reflection-like check using NSClassFromString to avoid hard dependency
      let available = (NSClassFromString("GMSNavigationViewController") != nil) || (NSClassFromString("GMNavigationViewController") != nil)
      result(available)
    case "nav_ui#start":
      guard let root = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else { result(false); return }
      // Extract args
      var apiKey: String = ""
      var oLat: Double = 0, oLng: Double = 0, dLat: Double = 0, dLng: Double = 0
      var mapId: String? = nil
      var language: String = ""
      var themeMode: String = "auto"
      var colorPrimary: UInt = 0, colorOnPrimary: UInt = 0, colorSurface: UInt = 0, colorOnSurface: UInt = 0
      if let args = call.arguments as? [String: Any] {
        apiKey = args["apiKey"] as? String ?? ""
        language = args["languageCode"] as? String ?? ""
        themeMode = args["themeMode"] as? String ?? "auto"
        mapId = args["mapId"] as? String
        colorPrimary = (args["colorPrimary"] as? UInt) ?? 0
        colorOnPrimary = (args["colorOnPrimary"] as? UInt) ?? 0
        colorSurface = (args["colorSurface"] as? UInt) ?? 0
        colorOnSurface = (args["colorOnSurface"] as? UInt) ?? 0
        if let o = args["origin"] as? [String: Any] { oLat = (o["lat"] as? Double) ?? 0; oLng = (o["lng"] as? Double) ?? 0 }
        if let d = args["destination"] as? [String: Any] { dLat = (d["lat"] as? Double) ?? 0; dLng = (d["lng"] as? Double) ?? 0 }
      }

      if let navServicesClass: AnyClass = NSClassFromString("GMSNavigationServices"),
         let navVCClass: UIViewController.Type = NSClassFromString("GMSNavigationViewController") as? UIViewController.Type {
        // Try to call +[GMSNavigationServices provideAPIKey:]
        let sel = NSSelectorFromString("provideAPIKey:")
        if (navServicesClass as? NSObject.Type)?.responds(to: sel) == true {
          _ = (navServicesClass as AnyObject).perform(sel, with: apiKey)
        }

        // Instantiate nav VC via assumed init and set destination; fall back to presenting Google Maps URL
        let navVC = navVCClass.init()
        // Try to set mapId via KVC if supported
        if let mapIdStr = mapId {
          navVC.setValue(mapIdStr, forKey: "mapID")
        }
        // Try to set language and theme via KVC if supported by SDK
        navVC.setValue(language, forKey: "languageCode")
        navVC.setValue(themeMode, forKey: "themeMode")
        // Set colors via KVC if supported
        navVC.setValue(colorFromARGB(colorPrimary), forKey: "colorPrimary")
        navVC.setValue(colorFromARGB(colorOnPrimary), forKey: "colorOnPrimary")
        navVC.setValue(colorFromARGB(colorSurface), forKey: "colorSurface")
        navVC.setValue(colorFromARGB(colorOnSurface), forKey: "colorOnSurface")
        // Destination via KVC
        let dest = CLLocationCoordinate2D(latitude: dLat, longitude: dLng)
        navVC.setValue(NSValue(mkCoordinate: dest), forKey: "destinationCoordinate")

        Self.presented = navVC
        root.present(navVC, animated: true)
        result(true)
      } else {
        // Fallback: placeholder screen
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "Navigation SDK não disponível. Adicione a dependência e chaves."
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
          label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
          label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
          label.leadingAnchor.constraint(greaterThanOrEqualTo: vc.view.leadingAnchor, constant: 24),
          label.trailingAnchor.constraint(lessThanOrEqualTo: vc.view.trailingAnchor, constant: -24)
        ])
        Self.presented = vc
        root.present(vc, animated: true)
        result(true)
      }
    case "nav_ui#stop":
      if let vc = Self.presented {
        vc.dismiss(animated: true)
        Self.presented = nil
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
