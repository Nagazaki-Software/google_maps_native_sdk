part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Callback with the created [GoogleMapController].
typedef MapCreatedCallback = void Function(GoogleMapController controller);

/// A Flutter widget that renders a native Google Map view.
class GoogleMapView extends StatefulWidget {
  const GoogleMapView({
    super.key,
    required this.initialCameraPosition,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.myLocationEnabled = false,
    this.mapStyleJson,
    this.padding = const MapPadding(),
    this.clusterEnabled = false,
    this.liteMode = false,
    this.indoorEnabled = false,
    this.indoorLevelPicker = false,
    this.mapId,
    this.onMapCreated,
    this.webApiKey,
  });

  /// Initial camera position when the map is first shown.
  final CameraPosition initialCameraPosition;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool myLocationEnabled;

  /// Optional custom JSON style to apply.
  final String? mapStyleJson;

  /// Padding to apply around the map viewport.
  final MapPadding padding;

  /// Enables Google Maps Utils clustering (Android/iOS only).
  final bool clusterEnabled;

  /// Android only: use Lite Mode for better performance in mini-maps.
  final bool liteMode;

  /// Enables indoor maps (iOS/Android). On Android, also pair with [indoorLevelPicker].
  final bool indoorEnabled;

  /// Android UI: show indoor level picker control.
  final bool indoorLevelPicker;

  /// Cloud Map styling via Map ID.
  final String? mapId;

  /// Called when the underlying platform view is created.
  final MapCreatedCallback? onMapCreated;

  /// Web only: API key for the Google Maps JavaScript API. If null, you must
  /// include the script manually in web/index.html.
  final String? webApiKey;

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    const viewType = 'google_maps_native_sdk/map_view';
    final creationParams = <String, dynamic>{
      'initialCameraPosition': widget.initialCameraPosition.toMap(),
      'trafficEnabled': widget.trafficEnabled,
      'buildingsEnabled': widget.buildingsEnabled,
      'myLocationEnabled': widget.myLocationEnabled,
      'mapStyle': widget.mapStyleJson,
      'padding': widget.padding.toMap(),
      'clusterEnabled': widget.clusterEnabled,
      'liteMode': widget.liteMode,
      'indoorEnabled': widget.indoorEnabled,
      'indoorLevelPicker': widget.indoorLevelPicker,
      if (widget.mapId != null) 'mapId': widget.mapId,
    };

    if (kIsWeb) {
      return webmap.buildWebGoogleMapView(
        initialCameraPosition: widget.initialCameraPosition,
        trafficEnabled: widget.trafficEnabled,
        buildingsEnabled: widget.buildingsEnabled,
        myLocationEnabled: widget.myLocationEnabled,
        mapStyleJson: widget.mapStyleJson,
        padding: widget.padding,
        webApiKey: widget.webApiKey,
        onHostReady: (host) {
          final ctrl = GoogleMapController.web(host);
          // Wire event sinks from host into controller
          host.setOnMarkerTap((id) => ctrl.handleWebMarkerTap(id));
          host.setOnMapLoaded(() => ctrl.handleWebMapLoaded());
          _controller = ctrl;
          widget.onMapCreated?.call(ctrl);
        },
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: viewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _onPlatformViewCreated(int id) {
    final controller = GoogleMapController._(id);
    controller._bindCallbacks();
    _controller = controller;
    widget.onMapCreated?.call(controller);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
