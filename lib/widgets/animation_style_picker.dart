import 'package:flutter/material.dart';

import 'package:expensetracker_reloaded/routes/animation_variants.dart';
import 'package:expensetracker_reloaded/routes/predictive_back.dart';

/// Settings > Route Animations. Collapsed: the current style with a small
/// looping preview. Tap to expand the full list, grouped
/// (Slides / Zooms / Reveals / Springs).
class AnimationStylePicker extends StatefulWidget {
  const AnimationStylePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AnimationType value;
  final ValueChanged<AnimationType> onChanged;

  @override
  State<AnimationStylePicker> createState() => _AnimationStylePickerState();
}

class _AnimationStylePickerState extends State<AnimationStylePicker> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = motionStyles[widget.value]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('anim-picker-header'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                StylePreview(type: widget.value),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        current.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.expand_more, color: cs.primary),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubicEmphasized,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Column(
                  key: const Key('anim-picker-list'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final g in MotionGroup.values) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                        child: Text(
                          g.label,
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: cs.primary),
                        ),
                      ),
                      for (final e in motionStyles.entries)
                        if (e.value.group == g)
                          RadioListTile<AnimationType>(
                            key: Key('anim-style-${e.key.name}'),
                            dense: true,
                            secondary: Icon(e.value.icon),
                            title: Text(e.value.name),
                            subtitle: Text(
                              e.value.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: e.key,
                            groupValue: widget.value,
                            onChanged: (v) {
                              if (v != null) widget.onChanged(v);
                            },
                          ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// A tiny phone-shaped box that plays [type] once (replays on change; tap
/// the box to replay; static when animations are off).
class StylePreview extends StatefulWidget {
  const StylePreview({super.key, required this.type});
  final AnimationType type;

  @override
  State<StylePreview> createState() => _StylePreviewState();
}

class _StylePreviewState extends State<StylePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Plays once (not looping: no battery drain, tests can settle).
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(StylePreview old) {
    super.didUpdateWidget(old);
    if (old.type != widget.type && !reduceMotion(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const size = Size(40, 64);
    final t = _c;
    return ExcludeSemantics(
      child: GestureDetector(
        onTap: reduceMotion(context) ? null : () => _c.forward(from: 0),
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: size),
            child: buildMotion(
              widget.type,
              t,
              kAlwaysDismissedAnimation,
              Container(
                color: cs.primary,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.all(6),
                child: Container(
                  height: 8,
                  color: cs.onPrimary.withValues(alpha: 0.6),
                ),
              ),
              gesture: () => false,
            ),
          ),
        ),
      ),
    );
  }
}
