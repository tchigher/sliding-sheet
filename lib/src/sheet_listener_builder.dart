import 'package:flutter/material.dart';

import 'sheet.dart';

class SheetListenerBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, SheetState state) builder;
  final bool Function(SheetState oldState, SheetState newState) buildWhen;
  const SheetListenerBuilder({
    Key key,
    @required this.builder,
    this.buildWhen,
  }) : super(key: key);

  @override
  _SheetListenerBuilderState createState() => _SheetListenerBuilderState();
}

class _SheetListenerBuilderState extends State<SheetListenerBuilder> {
  SheetState _state = SheetState.inital();
  ValueNotifier<SheetState> _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _notifier = SheetState.notifier(
      context,
    )..addListener(_listener);

    _state = _notifier.value;
  }

  void _listener() {
    final newState = _notifier.value;
    final shouldRebuild = _state == null ||
        widget.buildWhen == null ||
        widget.buildWhen(_state, newState) == true;

    if (shouldRebuild) {
      _state = newState;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);

  @override
  void dispose() {
    _notifier.removeListener(_listener);
    super.dispose();
  }
}
