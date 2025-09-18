import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_native_sdk/google_maps_native_sdk.dart';
import 'routes_tbt_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const _Home(),
      routes: {
        '/basic': (context) => const DemoPage(),
        '/routesTbt': (context) => const RoutesTbtDemoPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Maps Native SDK - Samples')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Basic Map / Markers / Polylines'),
            subtitle: const Text('Markers, polylines, camera, style, events'),
            onTap: () => Navigator.of(context).pushNamed('/basic'),
          ),
          ListTile(
            title: const Text('Routes + TBT Demo'),
            subtitle: const Text('Routes API + turn-by-turn + event streams'),
            onTap: () => Navigator.of(context).pushNamed('/routesTbt'),
          ),
        ],
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});
  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  GoogleMapController? controller;
  final pickup = const LatLng(-23.563099, -46.654387); // SP Av. Paulista
  final dropoff = const LatLng(-23.55052, -46.633308); // SP Centro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic Map Demo')),
      body: Stack(
        children: [
          GoogleMapView(
            initialCameraPosition: CameraPosition(target: pickup, zoom: 13),
            trafficEnabled: true,
            myLocationEnabled: false,
            padding: const MapPadding(bottom: 120),
            onMapCreated: (c) async {
              controller = c;
              // Resolve Messenger before awaits to avoid context across async gaps
              final messenger = ScaffoldMessenger.maybeOf(context);
              // Apply a single-color map tint (custom color)
              await c.setMapColor(Colors.indigo, dark: false);
              await c.addMarker(
                MarkerOptions(id: 'pickup', position: pickup, title: 'Origem'),
              );
              await c.addMarker(
                MarkerOptions(
                  id: 'dropoff',
                  position: dropoff,
                  title: 'Destino',
                ),
              );
              await c.animateToBounds(pickup, dropoff, padding: 80);

              // Polyline mock (encoded polyline ou pontos)
              final route = [
                pickup,
                const LatLng(-23.558, -46.649),
                const LatLng(-23.555, -46.642),
                dropoff,
              ];
              await c.addPolyline(
                PolylineOptions(
                  id: 'route',
                  points: route,
                  color: Colors.blueAccent,
                  width: 6,
                ),
              );

              c.onMarkerTap.listen((id) {
                messenger?.showSnackBar(SnackBar(content: Text('Marker: $id')));
              });
            },
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final me = LatLng(
                        pickup.latitude + (Random().nextDouble() - 0.5) / 1000,
                        pickup.longitude + (Random().nextDouble() - 0.5) / 1000,
                      );
                      await controller?.addMarker(
                        MarkerOptions(
                          id: 'driver',
                          position: me,
                          title: 'Motorista',
                          iconUrl:
                              'https://img.icons8.com/emoji/48/red-car.png',
                        ),
                      );
                    },
                    child: const Text('Adicionar motorista'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller?.clearMarkers();
                    },
                    child: const Text('Limpar markers'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
