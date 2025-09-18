import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

class RoutesTbtDemoPage extends StatefulWidget {
  const RoutesTbtDemoPage({super.key});
  @override
  State<RoutesTbtDemoPage> createState() => _RoutesTbtDemoPageState();
}

class _RoutesTbtDemoPageState extends State<RoutesTbtDemoPage> {
  GoogleMapController? controller;
  NavigationSession? session;
  final origin = const LatLng(-23.561, -46.656);
  final destination = const LatLng(-23.570, -46.650);
  String apiKey = 'YOUR_ROUTES_API_KEY';
  StreamSubscription<NavProgress>? _pSub;
  StreamSubscription<NavInstruction>? _iSub;
  StreamSubscription<NavState>? _sSub;
  String _status = 'idle';
  String _inst = '';
  String _eta = '';

  @override
  void dispose() {
    _pSub?.cancel();
    _iSub?.cancel();
    _sSub?.cancel();
    session?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routes + TBT Demo')),
      body: Stack(children: [
        GoogleMapView(
          initialCameraPosition: CameraPosition(target: origin, zoom: 13),
          trafficEnabled: true,
          padding: const MapPadding(bottom: 160),
          onMapCreated: (c) async {
            controller = c;
            GmnsNavHub.setController(c);
            await c.setMapColor(Colors.indigo, dark: false);
            await c.addMarker(MarkerOptions(id: 'o', position: origin, title: 'Origin'));
            await c.addMarker(MarkerOptions(id: 'd', position: destination, title: 'Destination'));
            await c.animateToBounds(origin, destination, padding: 60);
          },
        ),
        Positioned(
          bottom: 16,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $_status'),
                      const SizedBox(height: 4),
                      Text('ETA: $_eta'),
                      const SizedBox(height: 4),
                      Text('Instruction: $_inst'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final count = await GmnsNavHub.computeRoutesAndDraw(
                        apiKey: apiKey,
                        origin: origin,
                        destination: destination,
                        alternatives: true,
                        modifiers: const RouteModifiers(avoidHighways: false, avoidTolls: false),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Routes: $count')));
                    },
                    child: const Text('Compute Routes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Choose route 0 as active
                      await GmnsNavHub.chooseActiveRoute(0);
                    },
                    child: const Text('Use Route #0'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      session = await MapNavigator.start(
                        controller: controller!,
                        options: NavigationOptions(
                          apiKey: apiKey,
                          origin: origin,
                          destination: destination,
                          language: 'pt-BR',
                          voiceGuidance: true,
                          ttsRate: 0.95,
                        ),
                      );
                      _bindSession();
                    },
                    child: const Text('Start TBT'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await session?.stop();
                    },
                    child: const Text('Stop TBT'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => session?.recenter(),
                    child: const Text('Recenter'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => session?.overview(),
                    child: const Text('Overview'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  void _bindSession() {
    _pSub?.cancel();
    _iSub?.cancel();
    _sSub?.cancel();
    final s = session;
    if (s == null) return;
    _pSub = s.onProgress.listen((e) {
      setState(() {
        final km = (e.distanceRemainingMeters / 1000).toStringAsFixed(2);
        final eta = e.etaSeconds == null ? '--' : '${(e.etaSeconds! / 60).toStringAsFixed(0)} min';
        _eta = '$km km • $eta';
      });
    });
    _iSub = s.onInstruction.listen((e) {
      setState(() {
        _inst = e.text;
      });
    });
    _sSub = s.onState.listen((st) {
      setState(() {
        _status = st.name;
      });
    });
  }
}
