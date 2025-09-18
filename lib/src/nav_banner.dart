part of 'package:google_maps_native_sdk/google_maps_native_sdk.dart';

/// Simple navigation instruction banner widget.
/// Shows a maneuver icon, instruction text and remaining distance.
class NavInstructionBanner extends StatelessWidget {
  final NavInstruction? instruction;
  final Color? background;
  final Color? foreground;
  final EdgeInsets padding;
  final double iconSize;
  final TextStyle? textStyle;

  const NavInstructionBanner({
    super.key,
    required this.instruction,
    this.background,
    this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.iconSize = 28,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (instruction == null) return const SizedBox.shrink();
    final i = instruction!;
    final icon = _iconForManeuver(i.maneuver);
    final dist = _formatDistance(i.distanceMeters);
    final fg = foreground ?? const Color(0xFFFAFAFA);
    final bg = background ?? const Color(0xCC263238);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  i.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle ?? TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(dist, style: TextStyle(color: fg.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForManeuver(String? m) {
  switch ((m ?? '').toUpperCase()) {
    case 'TURN_LEFT':
    case 'SHARP_LEFT':
    case 'SLIGHT_LEFT':
    case 'FORK_LEFT':
    case 'RAMP_LEFT':
    case 'ROUNDABOUT_LEFT':
    case 'MERGE_LEFT':
    case 'U_TURN_LEFT':
      return Icons.turn_left;
    case 'TURN_RIGHT':
    case 'SHARP_RIGHT':
    case 'SLIGHT_RIGHT':
    case 'FORK_RIGHT':
    case 'RAMP_RIGHT':
    case 'ROUNDABOUT_RIGHT':
    case 'MERGE_RIGHT':
    case 'U_TURN_RIGHT':
      return Icons.turn_right;
    case 'STRAIGHT':
    case 'KEEP_STRAIGHT':
      return Icons.straight;
    case 'MERGE':
      return Icons.merge_type;
    default:
      return Icons.navigation;
  }
}

String _formatDistance(int meters) {
  if (meters < 1000) return '$meters m';
  final km = meters / 1000.0;
  return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
}
