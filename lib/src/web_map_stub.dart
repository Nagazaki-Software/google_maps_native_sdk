import 'package:flutter/widgets.dart';

Widget buildWebGoogleMapView({
  required dynamic initialCameraPosition,
  required bool trafficEnabled,
  required bool buildingsEnabled,
  required bool myLocationEnabled,
  required String? mapStyleJson,
  required dynamic padding,
  required String? webApiKey,
  required void Function(dynamic host) onHostReady,
}) {
  // Non-web fallback
  return const SizedBox.shrink();
}
