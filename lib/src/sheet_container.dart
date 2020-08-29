import 'package:flutter/material.dart';

class SheetContainer extends StatelessWidget {
  final Duration duration;
  final double borderRadius;
  final double elevation;
  final Border border;
  final BorderRadius customBorders;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final List<BoxShadow> boxShadows;
  final AlignmentGeometry alignment;
  final BoxConstraints constraints;
  const SheetContainer({
    Key key,
    this.duration,
    this.borderRadius = 0.0,
    this.elevation = 0.0,
    this.border,
    this.customBorders,
    this.margin,
    this.padding = const EdgeInsets.all(0),
    this.child,
    this.color = Colors.transparent,
    this.shadowColor = Colors.black12,
    this.boxShadows,
    this.alignment,
    this.constraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final br = customBorders ?? BorderRadius.circular(borderRadius);

    final decoration = BoxDecoration(
      color: color,
      borderRadius: br,
      border: border,
      boxShadow: boxShadows ??
          (elevation > 0.0
              ? [
                  BoxShadow(
                    color: shadowColor ?? Colors.black12,
                    blurRadius: elevation,
                    spreadRadius: 0,
                  )
                ]
              : const []),
    );

    final child = br != BorderRadius.zero
        ? ClipRRect(borderRadius: br, child: this.child)
        : this.child;

    if (duration == null || duration == Duration.zero) {
      return Container(
        margin: margin,
        padding: padding,
        alignment: alignment,
        constraints: constraints,
        decoration: decoration,
        child: child,
      );
    } else {
      return AnimatedContainer(
        duration: duration,
        padding: padding,
        alignment: alignment,
        constraints: constraints,
        decoration: decoration,
        child: child,
      );
    }
  }
}
