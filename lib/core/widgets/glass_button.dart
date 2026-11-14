import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// iOS-27-Liquid-Glass-Button. Ohne [tint] klares Glas, mit [tint] eingefärbt.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 44,
    this.width,
    this.tint,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double height;

  /// Null = so breit wie der Inhalt (mit [padding]).
  final double? width;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings.ios27Regular(
              brightness: brightness, tintAmount: 1),
          appearance: LiquidGlassAppearance.ios27Regular(
              brightness: brightness, tint: Colors.transparent),
          shape: LiquidRoundedSuperellipse(borderRadius: height / 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: (tint ?? Colors.white)
                  .withValues(alpha: tint == null ? 0.08 : 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: padding,
              child:
                  Center(widthFactor: width == null ? 1 : null, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Auswahl aus getrennten Liquid-Glass-Buttons. Der gewählte ist heller
/// hinterlegt und fett.
class GlassSegmented extends StatelessWidget {
  const GlassSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.inactiveColor,
    required this.tint,
    this.height = 44,
    this.gap = 10,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color inactiveColor;
  final Color tint;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: GlassButton(
              width: double.infinity,
              height: height,
              tint: i == selected ? tint : null,
              onTap: () => onChanged(i),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                  color: inactiveColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
