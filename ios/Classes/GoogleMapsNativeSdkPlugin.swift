import Flutter
import UIKit
import GoogleMaps

public class GoogleMapsNativeSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = MapViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "google_maps_native_sdk/map_view")
  }
}

