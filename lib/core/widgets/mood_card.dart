import 'package:flutter/material.dart';

import '../../features/mood_entry/domain/enums/mood.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'mood_face.dart';

class MoodCard extends StatefulWidget {
  const MoodCard({
    super.key,
    required this.mood,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.size = 64,
  });

  final Mood mood;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  @override
  State<MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final moodColor = colors.moodColor(widget.mood);
    final selected = widget.isSelected;
    final bg = selected ? moodColor : colors.surface;
    final fg = selected ? colors.onPrimary : colors.onSurface;
    final border = selected ? moodColor : colors.outline;

    final scale = _pressed ? 0.96 : (selected ? 1.05 : 1.0);

    return Semantics(
      button: true,
      label: widget.label,
      selected: selected,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: Curves.easeOut,
            width: widget.size,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.cardBR,
              border: Border.all(color: border, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoodFace(mood: widget.mood, color: fg, size: widget.size * 0.6),
                const SizedBox(height: AppSpacing.xxs),
                Text(widget.label, style: AppTextStyles.label.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
