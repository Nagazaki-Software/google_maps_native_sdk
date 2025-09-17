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
    this.onMapCreated,
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
  /// Called when the underlying platform view is created.
  final MapCreatedCallback? onMapCreated;

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
    };

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
