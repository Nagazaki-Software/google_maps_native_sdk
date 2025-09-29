part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Device heading (compass/rotation vector) broadcast stream.
///
/// Values are degrees [0,360), where 0 = North, 90 = East.
/// On iOS uses Core Location heading; on Android uses TYPE_ROTATION_VECTOR.
class DeviceHeading {
  static const EventChannel _channel = EventChannel('google_maps_native_sdk/heading');

  static Stream<double>? _cached;

  /// Returns a broadcast stream of heading degrees. Starts sensors on listen,
  /// and stops them when the last listener cancels.
  static Stream<double> get stream {
    _cached ??= _channel
        .receiveBroadcastStream()
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .asBroadcastStream();
    return _cached!;
  }
}

/// Simple circular (angle) smoothing helper using exponential moving average
/// on the unit circle to handle 0/360 wrap-around gracefully.
class _AngleSmoother {
  _AngleSmoother(this.alpha);
  final double alpha; // 0..1 (higher = more reactive)
  double? _cx;
  double? _sy;

  double update(double angleDeg) {
    final rad = angleDeg * math.pi / 180.0;
    final x = math.cos(rad);
    final y = math.sin(rad);
    if (_cx == null || _sy == null) {
      _cx = x;
      _sy = y;
    } else {
      _cx = alpha * x + (1 - alpha) * _cx!;
      _sy = alpha * y + (1 - alpha) * _sy!;
    }
    final out = math.atan2(_sy!, _cx!) * 180.0 / math.pi;
    return out < 0 ? out + 360.0 : out;
  }
}

