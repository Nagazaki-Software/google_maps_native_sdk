import Flutter
import UIKit
import GoogleMaps
import CoreLocation

public class GoogleMapsNativeSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = MapViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "google_maps_native_sdk/map_view")

    // Heading EventChannel
    let headingHandler = HeadingStreamHandler()
    let headingChannel = FlutterEventChannel(name: "google_maps_native_sdk/heading", binaryMessenger: registrar.messenger())
    headingChannel.setStreamHandler(headingHandler)
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
