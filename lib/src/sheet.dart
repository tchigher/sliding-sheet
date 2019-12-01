import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'util.dart';

typedef SheetBuilder = Widget Function(BuildContext, SheetState);

typedef SheetListener = void Function(SheetState);

/// How the snaps will be positioned.
enum SnapPositioning {
  /// Positions the snaps relative to the total
  /// available space (that is, the maximum height the widget can expand to).
  relativeToAvailableSpace,

  /// Positions the snaps relative to the total height
  /// of the sheet itself.
  relativeToSheetHeight,

  /// Positions the snaps at the given pixel offset. If the
  /// sheet is smaller than the offset, it will snap to the max possible offset.
  pixelOffset,
}

/// Defines how a [SlidingSheet] should snap, or if it should at all.
class SnapSpec {
  /// If true, the [SlidingSheet] will snap to the provided [snappings].
  /// If false, the [SlidingSheet] will slide from minExtent to maxExtent
  /// and then begin to scroll.
  final bool snap;

  /// The snap extents for a [SlidingSheet].
  ///
  /// The minimum and maximum values will represent the thresholds in which
  /// the [SlidingSheet] will slide. When the child of the sheet is bigger
  /// than the available space defined by the minimum and maximum extent,
  /// it will begin to scroll.
  final List<double> snappings;

  /// How the snaps will be positioned:
  /// - [SnapPositioning.relativeToAvailableSpace] positions the snaps relative to the total
  /// available space (that is, the maximum height the widget can expand to). All values must be between 0 and 1.
  /// - [SnapPositioning.relativeToSheetHeight] positions the snaps relative to the total size
  /// of the sheet itself. All values must be between 0 and 1.
  /// - [SnapPositioning.pixelOffset] positions the snaps at the given pixel offset. If the
  /// sheet is smaller than the offset, it will snap to the max possible offset.
  final SnapPositioning positioning;

  /// A callback function that gets called when the [SlidingSheet] snaps to an extent.
  final void Function(SheetState, double snap) onSnap;
  const SnapSpec({
    this.snap = true,
    this.snappings = const [0.4, 1.0],
    this.positioning = SnapPositioning.relativeToAvailableSpace,
    this.onSnap,
  })  : assert(snap != null),
        assert(snappings != null),
        assert(positioning != null);

  SnapSpec copyWith({
    bool snap,
    List<double> snappings,
    SnapPositioning position,
  }) {
    return SnapSpec(
      snap: snap ?? this.snap,
      snappings: snappings ?? this.snappings,
      positioning: position ?? this.positioning,
    );
  }
}

/// Defines the scroll effects, physics and more.
class ScrollSpec {
  /// Whether the containing ScrollView should overscroll.
  final bool overscroll;

  /// The color of the overscroll when [overscroll] is true.
  final Color overscrollColor;

  /// The physics of the containing ScrollView.
  final ScrollPhysics physics;
  const ScrollSpec({
    this.overscroll = true,
    this.overscrollColor,
    this.physics,
  });

  factory ScrollSpec.overscroll({Color color}) => ScrollSpec(overscrollColor: color);

  factory ScrollSpec.bouncingScroll() => ScrollSpec(physics: BouncingScrollPhysics());
}

/// A widget that can be dragged and scrolled in a single gesture and snapped
/// to a list of extents.
///
/// The [builder] parameter must not be null.
class SlidingSheet extends StatefulWidget {
  /// The [SnapSpec] that defines how the sheet should snap or if it should at all.
  final SnapSpec snapSpec;

  /// The base animation duration for the sheet. Swipes and flings may have a different duration.
  final Duration duration;

  /// The background color of the sheet.
  final Color color;

  /// The color of the shadow that is displayed behind the sheet.
  final Color backdropColor;

  /// The color of the drop shadow of the sheet when [elevation] is > 0.
  final Color shadowColor;

  /// The elevation of the sheet.
  final double elevation;

  /// The amount to inset the children of the sheet.
  final EdgeInsets padding;

  /// The amount of the empty space surrounding the sheet.
  final EdgeInsets margin;

  /// A border that will be drawn around the sheet.
  final Border border;

  /// The radius of the corners of this sheet.
  final double cornerRadius;

  /// If true, will collapse the sheet when the sheets backdrop was tapped.
  final bool closeOnBackdropTap;

  /// The builder for the main content of the sheet that will be scrolled if
  /// the content is bigger than the height that the sheet can expand to.
  final SheetBuilder builder;

  /// The builder for a header that will be displayed at the top of the sheet
  /// that wont be scrolled.
  final SheetBuilder headerBuilder;

  /// The builder for a footer that will be displayed at the bottom of the sheet
  /// that wont be scrolled.
  final SheetBuilder footerBuilder;

  /// A callback that will be invoked when the sheet gets dragged or scrolled
  /// with current state information.
  final SheetListener listener;

  /// A controller to control the state of the sheet.
  final SheetController controller;

  /// The route of the sheet when used in a bottom sheet dialog. This parameter
  /// is assigned internally and should not be explicitly assigned.
  final _TransparentRoute route;

  /// The [ScrollSpec] of the containing ScrollView.
  final ScrollSpec scrollSpec;

  /// The maximum width of the sheet.
  /// Usually set for large screens. By default the [SlidingSheet]
  /// expands to the total available width.
  final double maxWidth;
  const SlidingSheet({
    Key key,
    @required this.builder,
    this.duration = const Duration(milliseconds: 800),
    this.snapSpec = const SnapSpec(),
    this.padding,
    this.margin,
    this.border,
    this.headerBuilder,
    this.footerBuilder,
    this.route,
    this.color = Colors.white,
    this.backdropColor,
    this.cornerRadius = 0.0,
    this.elevation = 0.0,
    this.shadowColor = Colors.black54,
    this.closeOnBackdropTap = false,
    this.listener,
    this.controller,
    this.scrollSpec = const ScrollSpec(overscroll: false),
    this.maxWidth = double.infinity,
  })  : assert(duration != null),
        assert(builder != null),
        assert(snapSpec != null),
        super(key: key);

  @override
  _SlidingSheetState createState() => _SlidingSheetState();
}

class _SlidingSheetState extends State<SlidingSheet> with TickerProviderStateMixin {
  // The key of the scrolling child to determine its size.
  GlobalKey _childKey;
  // The key of the header to determine the ScrollView's top inset.
  GlobalKey _headerKey;
  // The key of the footer to determine the ScrollView's bottom inset.
  GlobalKey _footerKey;
  // The child of the sheet that will be scrollable if the content is bigger
  // than the available space.
  Widget _child;
  // A Widget that will be displayed at the top and that wont be scrolled.
  Widget _header;
  // A Widget that will be displayed at the bottom and that wont be scrolled.
  Widget _footer;
  // Whether the sheet has drawn its first frame.
  bool _isLaidOut = false;
  // Whether a dismiss was already triggered by the sheet itself
  // and thus further route pops can be safely ignored.
  bool _dismissUnderway = false;
  // The current sheet extent.
  _SheetExtent _extent;
  // The ScrollController for the sheet.
  _DragableScrollableSheetController _controller;
  StreamController<double> _stream;

  // The height of the child of the sheet that scrolls if its bigger than
  // the availableHeight.
  double _childHeight = 0;
  // The height of the non scrolling header of the sheet.
  double _headerHeight = 0;
  // The height of the non scrolling footer of the sheet.
  double _footerHeight = 0;
  // The total available height that the sheet can expand to.
  double _availableHeight = 0;
  // The total height of all sheet components.
  double get _sheetHeight => _childHeight + _headerHeight + _footerHeight;

  double get _currentExtent => _extent?.currentExtent ?? 0.0;
  double get _minExtent => _snappings[_fromBottomSheet ? 1 : 0].clamp(0.0, 1.0);
  double get _maxExtent => _snappings.last.clamp(0.0, 1.0);

  bool get _fromBottomSheet => widget.route != null;
  ScrollSpec get _scrollSpec => widget.scrollSpec;
  SnapSpec get _snapSpec => widget.snapSpec;
  SnapPositioning get _snapPositioning => _snapSpec.positioning;
  List<double> get _snappings => _snapSpec.snappings.map(_normalizeSnap).toList()..sort();

  // The current state of this sheet.
  SheetState get _state => SheetState(
        _extent,
        extent: _reverseSnap(_currentExtent),
        minExtent: _reverseSnap(_minExtent),
        maxExtent: _reverseSnap(_maxExtent),
        isLaidOut: _isLaidOut,
      );

  @override
  void initState() {
    super.initState();
    // Assign the keys that will be used to determine the size of
    // the children.
    _childKey = GlobalKey();
    _headerKey = GlobalKey();
    _footerKey = GlobalKey();
    _stream = StreamController.broadcast();

    // Call the listener when the extent or scroll position changes.
    final listener = () {
      if (_isLaidOut) widget?.listener?.call(_state);
    };

    _controller = _DragableScrollableSheetController(
      this,
    )..addListener(listener);

    _extent = _SheetExtent(
      _controller,
      isFromBottomSheet: _fromBottomSheet,
      snappings: _snappings,
      listener: (extent) {
        _stream.add(extent);
        listener();
      },
    );

    _assignSheetController();

    _measure(true);

    // Snap to the initial snap with a one frame delay to correctley
    // calculate the extents.
    postFrame(() {
      if (_fromBottomSheet) {
        snapToExtent(_minExtent);

        // When the route gets popped we animate fully out - not just
        // to the minExtent.
        widget.route.popped.then(
          (_) {
            if (!_dismissUnderway) _controller.snapToExtent(0.0, this, clamp: false);
          },
        );
      } else {
        _extent.currentExtent = _minExtent;
      }
    });
  }

  // Measure the height of all sheet components.
  void _measure([bool remeasure = false]) {
    postFrame(() {
      final RenderBox child = _childKey?.currentContext?.findRenderObject();
      final RenderBox header = _headerKey?.currentContext?.findRenderObject();
      final RenderBox footer = _footerKey?.currentContext?.findRenderObject();
      _childHeight = child?.size?.height ?? 0;
      _headerHeight = header?.size?.height ?? 0;
      _footerHeight = footer?.size?.height ?? 0;

      _extent
        ..snappings = _snappings
        ..targetHeight = math.min(_sheetHeight, _availableHeight)
        ..childHeight = _childHeight
        ..headerHeight = _headerHeight
        ..footerHeight = _footerHeight
        ..availableHeight = _availableHeight
        ..maxExtent = _maxExtent
        ..minExtent = _minExtent;

      _isLaidOut = true;

      if (remeasure) rebuild();
    });
  }

  @override
  void didUpdateWidget(SlidingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _measure();
    _assignSheetController();

    _extent.snappings = _snappings;
  }

  // A snap must be relative to its availableHeight.
  // Here we handle all available snap positions and normalize them
  // to the availableHeight.
  double _normalizeSnap(double snap) {
    if (_availableHeight > 0) {
      final maxPossibleExtent = _isLaidOut ? _sheetHeight / _availableHeight : 1.0;
      switch (_snapPositioning) {
        case SnapPositioning.relativeToAvailableSpace:
          assert(snap >= 0.0 && snap <= 1.0, 'Relative snap $snap is not between 0 and 1.');
          return math.min(snap, maxPossibleExtent).clamp(0.0, 1.0);
        case SnapPositioning.relativeToSheetHeight:
          assert(snap >= 0.0 && snap <= 1.0, 'Relative snap $snap is not between 0 and 1.');
          final extent = (snap * math.min(_sheetHeight, _availableHeight)) / _availableHeight;
          return math.min(extent, maxPossibleExtent).clamp(0.0, 1.0);
        case SnapPositioning.pixelOffset:
          if (snap == double.infinity) snap = _availableHeight;
          final extent = snap / _availableHeight;
          return math.min(extent, maxPossibleExtent).clamp(0.0, 1.0);
        default:
          return snap.clamp(0.0, 1.0);
      }
    } else {
      return snap.clamp(0.0, 1.0);
    }
  }

  // Reverse a normalized snap.
  double _reverseSnap(double snap) {
    if (_isLaidOut && _childHeight > 0) {
      switch (_snapPositioning) {
        case SnapPositioning.relativeToAvailableSpace:
          return snap;
        case SnapPositioning.relativeToSheetHeight:
          return snap * (_availableHeight / _sheetHeight);
        case SnapPositioning.pixelOffset:
          return snap * _availableHeight;
        default:
          return snap.clamp(0.0, 1.0);
      }
    } else {
      return snap.clamp(0.0, 1.0);
    }
  }

  // Assign the controller functions to actual methods.
  void _assignSheetController() {
    final controller = widget.controller;
    if (controller != null) {
      // Assign the controller functions to the state functions.
      if (!_fromBottomSheet) controller._rebuild = rebuild;
      controller._scrollTo = scrollTo;
      controller._snapToExtent = (snap, {duration}) => snapToExtent(_normalizeSnap(snap), duration: duration);
      controller._expand = () => snapToExtent(_maxExtent);
      controller._collapse = () => snapToExtent(_minExtent);
      controller._show = () async {
        if (_state.isHidden) return snapToExtent(_minExtent, clamp: false);
      };
      controller._hide = () async {
        if (_state.isShown) return snapToExtent(0.0, clamp: false);
      };
    }
  }

  Future snapToExtent(double snap, {Duration duration, double velocity = 0, bool clamp}) async {
    if (!_isLaidOut) return null;

    duration ??= widget.duration;
    if (!_state.isAtTop) {
      duration *= 0.5;
      await _controller.animateTo(
        0,
        duration: duration,
        curve: Curves.easeInCubic,
      );
    }

    return _controller.snapToExtent(
      snap,
      this,
      duration: duration,
      velocity: velocity,
      clamp: clamp ?? (!_fromBottomSheet || (_fromBottomSheet && snap != 0.0)),
    );
  }

  Future scrollTo(double offset, {Duration duration, Curve curve}) async {
    if (!_isLaidOut) return null;

    duration ??= widget.duration;
    if (!_extent.isAtMax) {
      duration *= 0.5;
      await snapToExtent(
        _maxExtent,
        duration: duration,
      );
    }

    return _controller.animateTo(
      offset,
      duration: duration ?? widget.duration,
      curve: curve ?? (!_extent.isAtMax ? Curves.easeOutCirc : Curves.ease),
    );
  }

  void _pop(double velocity) {
    if (_fromBottomSheet && !_dismissUnderway && Navigator.canPop(context)) {
      _dismissUnderway = true;
      Navigator.pop(context);
    }

    snapToExtent(_fromBottomSheet ? 0.0 : _minExtent, velocity: velocity);
  }

  void rebuild() {
    _callBuilders();
    _measure();
    _stream.add(_currentExtent);
  }

  void _callBuilders() {
    if (context != null) {
      if (widget.headerBuilder != null) _header = _delegateInteractions(widget.headerBuilder(context, _state));
      if (widget.footerBuilder != null) _footer = _delegateInteractions(widget.footerBuilder(context, _state));
      if (widget.builder != null) _child = widget.builder(context, _state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _callBuilders();

    // StreamBuilder is used to update the sheet irrespective of its children.
    return StreamBuilder(
      stream: _stream.stream,
      builder: (context, snapshot) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth ?? double.infinity),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _availableHeight = constraints.biggest.height;

                // Wrap the scrollView in a ScrollConfiguration to
                // remove the default overscroll effect.
                Widget scrollView = ScrollConfiguration(
                  behavior: ScrollBehavior(),
                  child: SingleChildScrollView(
                    controller: _controller,
                    physics: _scrollSpec.physics ?? ScrollPhysics(),
                    child: Container(
                      key: _childKey,
                      child: _child,
                    ),
                  ),
                );

                // Add the overscroll if required again if required
                if (_scrollSpec.overscroll) {
                  scrollView = GlowingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    color: _scrollSpec.overscrollColor ?? theme.accentColor,
                    child: scrollView,
                  );
                }

                return Stack(
                  children: <Widget>[
                    if (widget.closeOnBackdropTap ||
                        (widget.backdropColor != null && widget.backdropColor.opacity != 0))
                      GestureDetector(
                        onTap: widget.closeOnBackdropTap ? () => _pop(0.0) : null,
                        child: Opacity(
                          opacity: _currentExtent != 0 ? (_currentExtent / _minExtent).clamp(0.0, 1.0) : 0.0,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: widget.backdropColor,
                          ),
                        ),
                      ),
                    SizedBox.expand(
                      child: FractionallySizedBox(
                        // Hide the box until it is laid out and measured.
                        heightFactor: _isLaidOut ? _currentExtent.clamp(0.0, 1.0) : _minExtent,
                        alignment: Alignment.bottomCenter,
                        child: _SheetContainer(
                          color: widget.color ?? Colors.white,
                          border: widget.border,
                          margin: widget.margin,
                          padding: widget.padding,
                          elevation: widget.elevation,
                          shadowColor: widget.shadowColor,
                          customBorders: BorderRadius.vertical(
                            top: Radius.circular(widget.cornerRadius),
                          ),
                          child: Stack(
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  SizedBox(height: _headerHeight),
                                  Expanded(
                                    child: scrollView,
                                  ),
                                  SizedBox(height: _footerHeight),
                                ],
                              ),
                              if (widget.headerBuilder != null)
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    key: _headerKey,
                                    child: _header,
                                  ),
                                ),
                              if (widget.footerBuilder != null)
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    key: _footerKey,
                                    child: _footer,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _delegateInteractions(Widget child) {
    if (child == null) return child;

    double start = 0;
    double end = 0;

    void onDragEnd([double velocity = 0.0]) {
      _controller.imitateFling(velocity);

      // If a header was dragged, but the scroll view is not at the top
      // animate to the top when the drag has ended.
      if (!_state.isAtTop && (start - end).abs() > 5) {
        _controller.animateTo(0.0, duration: widget.duration * .5, curve: Curves.ease);
      }
    }

    return GestureDetector(
      onVerticalDragStart: (details) {
        start = details.localPosition.dy;
        end = start;
      },
      onVerticalDragUpdate: (details) {
        end = details.localPosition.dy;
        final delta = swapSign(details.delta.dy);
        _controller.imitiateDrag(delta);
      },
      onVerticalDragEnd: (details) {
        final velocity = swapSign(details.velocity.pixelsPerSecond.dy);
        onDragEnd(velocity);
      },
      onVerticalDragCancel: onDragEnd,
      child: child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _stream.close();
    super.dispose();
  }
}

class _SheetExtent {
  final bool isFromBottomSheet;
  final _DragableScrollableSheetController controller;
  List<double> snappings;
  double targetHeight = 0;
  double childHeight = 0;
  double headerHeight = 0;
  double footerHeight = 0;
  double availableHeight = 0;
  _SheetExtent(
    this.controller, {
    @required this.isFromBottomSheet,
    @required this.snappings,
    @required void Function(double) listener,
  }) {
    maxExtent = snappings.last.clamp(0.0, 1.0);
    minExtent = snappings.first.clamp(0.0, 1.0);
    _currentExtent = ValueNotifier(minExtent)..addListener(() => listener(currentExtent));
  }

  ValueNotifier<double> _currentExtent;
  double get currentExtent => _currentExtent.value;
  set currentExtent(double value) {
    assert(value != null);
    _currentExtent.value = math.min(value, maxExtent);
  }

  double get sheetHeight => childHeight + headerHeight + footerHeight;

  double maxExtent;
  double minExtent;
  double get additionalMinExtent => isAtMin ? 0.0 : 1.0;
  double get additionalMaxExtent => isAtMax ? 0.0 : 1.0;

  bool get isAtMax => currentExtent >= maxExtent;
  bool get isAtMin => currentExtent <= minExtent;

  void addPixelDelta(double pixelDelta) {
    if (targetHeight == 0 || availableHeight == 0) return;
    currentExtent = (currentExtent + (pixelDelta / availableHeight));

    // The bottom sheet should be allowed to be dragged below its min extent.
    if (!isFromBottomSheet) currentExtent = currentExtent.clamp(minExtent, maxExtent);
  }

  double get scrollOffset {
    try {
      return math.max(controller.offset, 0);
    } catch (e) {
      return 0;
    }
  }

  bool get isAtTop => scrollOffset <= 0;

  bool get isAtBottom {
    try {
      return scrollOffset >= controller.position.maxScrollExtent;
    } catch (e) {
      return false;
    }
  }
}

class _DragableScrollableSheetController extends ScrollController {
  final _SlidingSheetState sheet;
  _DragableScrollableSheetController(this.sheet);

  _SheetExtent get extent => sheet._extent;
  void Function(double) get onPop => sheet._pop;
  Duration get duration => sheet.widget.duration;
  SnapSpec get snapSpec => sheet._snapSpec;

  double get currentExtent => extent.currentExtent;
  double get maxExtent => extent.maxExtent;
  double get minExtent => extent.minExtent;
  bool inDrag = false;

  _DraggableScrollableSheetScrollPosition _currentPosition;

  TickerFuture snapToExtent(
    double snap,
    TickerProvider vsync, {
    double velocity = 0,
    Duration duration,
    bool clamp = true,
  }) {
    if (clamp) snap = snap.clamp(extent.minExtent, extent.maxExtent);
    final speedFactor = (math.max((currentExtent - snap).abs(), .25) / maxExtent) *
        (1 - ((velocity.abs() / 2000) * 0.3).clamp(.0, 0.3));
    duration = this.duration * speedFactor;

    final controller = AnimationController(duration: duration, vsync: vsync);
    final tween = Tween(begin: extent.currentExtent, end: snap).animate(
      CurvedAnimation(parent: controller, curve: velocity.abs() > 300 ? Curves.easeOutCubic : Curves.ease),
    );

    controller.addListener(() => this.extent.currentExtent = tween.value);
    return controller.forward()
      ..whenCompleteOrCancel(() {
        controller.dispose();

        // Invoke the snap callback.
        snapSpec?.onSnap?.call(
          sheet._state,
          sheet._reverseSnap(snap),
        );
      });
  }

  void imitiateDrag(double delta) {
    inDrag = true;
    extent.addPixelDelta(delta);
  }

  void imitateFling([double velocity = 0.0]) {
    velocity != 0 ? _currentPosition?.goBallistic(velocity) : _currentPosition?.didEndScroll();
  }

  @override
  _DraggableScrollableSheetScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    _currentPosition = _DraggableScrollableSheetScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      extent: extent,
      onPop: onPop,
      scrollController: this,
    );

    return _currentPosition;
  }
}

class _DraggableScrollableSheetScrollPosition extends ScrollPositionWithSingleContext {
  final _SheetExtent extent;
  final void Function(double) onPop;
  final _DragableScrollableSheetController scrollController;
  _DraggableScrollableSheetScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    ScrollPosition oldPosition,
    String debugLabel,
    @required this.extent,
    @required this.onPop,
    @required this.scrollController,
  })  : assert(extent != null),
        assert(onPop != null),
        assert(scrollController != null),
        super(
          physics: physics,
          context: context,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  VoidCallback _dragCancelCallback;
  bool up = true;
  double lastVelocity = 0.0;

  bool get inDrag => scrollController.inDrag;
  set inDrag(bool value) => scrollController.inDrag = value;

  bool get fromBottomSheet => extent.isFromBottomSheet;
  SnapSpec get snapBehavior => scrollController.snapSpec;
  bool get snap => snapBehavior.snap;
  List<double> get snappings => extent.snappings;
  bool get shouldScroll => pixels > 0.0 && extent.isAtMax;
  double get availableHeight => extent.targetHeight;
  double get currentExtent => extent.currentExtent;
  double get maxExtent => extent.maxExtent;
  double get minExtent => extent.minExtent;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // We need to provide some extra extent if we haven't yet reached the max or
    // min extents. Otherwise, a list with fewer children than the extent of
    // the available space will get stuck.
    return super.applyContentDimensions(
      minScrollExtent - extent.additionalMinExtent,
      maxScrollExtent + extent.additionalMaxExtent,
    );
  }

  @override
  void applyUserOffset(double delta) {
    up = delta.isNegative;
    inDrag = true;

    if (!shouldScroll &&
        (!(extent.isAtMin || extent.isAtMax) ||
            (extent.isAtMin && (delta < 0 || fromBottomSheet)) ||
            (extent.isAtMax && delta > 0))) {
      extent.addPixelDelta(-delta);
    } else {
      super.applyUserOffset(delta);
    }
  }

  @override
  void didEndScroll() {
    super.didEndScroll();

    if ((snap && !extent.isAtMax && !extent.isAtMin && !shouldScroll) ||
        (fromBottomSheet && currentExtent < minExtent && inDrag)) {
      goSnapped(0.0);
    }
  }

  @override
  void goBallistic(double velocity) {
    up = !velocity.isNegative;
    lastVelocity = velocity;

    if (velocity != 0) inDrag = false;

    if (velocity == 0.0 || (velocity.isNegative && shouldScroll) || (!velocity.isNegative && extent.isAtMax)) {
      super.goBallistic(velocity);
      return;
    }

    // Scrollable expects that we will dispose of its current _dragCancelCallback
    _dragCancelCallback?.call();
    _dragCancelCallback = null;

    snap ? goSnapped(velocity) : goUnsnapped(velocity);
  }

  void goSnapped(double velocity) {
    velocity = velocity.abs();
    const flingThreshold = 1700;

    if (velocity > flingThreshold) {
      if (!up) {
        // Pop from the navigator on down fling.
        onPop(velocity);
      } else if (currentExtent > 0.0) {
        scrollController.snapToExtent(maxExtent, context.vsync, velocity: velocity);
      }
    } else {
      const snapToNextThreshold = 300;

      // Find the next snap based on the velocity.
      double distance = double.maxFinite;
      double snap;
      final slow = velocity < snapToNextThreshold;
      final target = !slow
          ? ((up ? 1 : -1) * (((velocity * .45) * (1 - currentExtent)) / flingThreshold)) + currentExtent
          : currentExtent;

      void findSnap([bool greaterThanCurrent = true]) {
        for (var i = 0; i < snappings.length; i++) {
          final stop = snappings[i];
          final valid = slow || !greaterThanCurrent || ((up && stop >= target) || (!up && stop <= target));

          if (valid) {
            final dis = (stop - target).abs();
            if (dis < distance) {
              distance = dis;
              snap = stop;
            }
          }
        }
      }

      // First try to find a snap higher than the current extent.
      // If there is non (snap == null), find the next snap.
      findSnap();
      if (snap == null) findSnap(false);

      if (snap == 0.0) {
        onPop(velocity);
      } else if (snap != extent.currentExtent && currentExtent > 0) {
        scrollController.snapToExtent(
          snap.clamp(minExtent, maxExtent),
          context.vsync,
          velocity: velocity,
        );
      }
    }
  }

  void goUnsnapped(double velocity) async {
    // The iOS bouncing simulation just isn't right here - once we delegate
    // the ballistic back to the ScrollView, it will use the right simulation.
    final simulation = ClampingScrollSimulation(
      position: extent.currentExtent,
      velocity: velocity,
      tolerance: physics.tolerance,
    );

    final ballisticController = AnimationController.unbounded(
      debugLabel: '$runtimeType',
      vsync: context.vsync,
    );

    double lastDelta = 0;
    void _tick() {
      final double delta = ballisticController.value - lastDelta;
      lastDelta = ballisticController.value;
      extent.addPixelDelta(delta);
      if ((velocity > 0 && extent.isAtMax) || (!fromBottomSheet && (velocity < 0 && extent.isAtMin))) {
        // Make sure we pass along enough velocity to keep scrolling - otherwise
        // we just "bounce" off the top making it look like the list doesn't
        // have more to scroll.
        velocity = ballisticController.velocity + (physics.tolerance.velocity * ballisticController.velocity.sign);
        super.goBallistic(velocity);
        ballisticController.stop();
      }
    }

    ballisticController.addListener(_tick);
    final animation = ballisticController.animateWith(simulation)
      ..whenCompleteOrCancel(
        ballisticController.dispose,
      );

    // Await the animation. In bottom sheets we need to decide whether to pop the route
    // when the animation ends and the sheet is below its min extent
    await animation;

    if (fromBottomSheet && currentExtent < minExtent) {
      goSnapped(0.0);
    }
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    // Save this so we can call it later if we have to [goBallistic] on our own.
    _dragCancelCallback = dragCancelCallback;
    return super.drag(details, dragCancelCallback);
  }
}

/// A data class containing state information about the [_SlidingSheetState].
class SheetState {
  final _SheetExtent _extent;

  /// The current extent the sheet covers.
  final double extent;

  /// The minimum extent that the sheet will cover.
  final double minExtent;

  /// The maximum extent that the sheet will cover
  /// until it begins scrolling.
  final double maxExtent;

  /// Whether the sheet has finished measuring its children and computed
  /// the correct extents. This takes until the first frame was drawn.
  final bool isLaidOut;
  SheetState(
    this._extent, {
    @required this.extent,
    @required this.minExtent,
    @required this.maxExtent,
    @required this.isLaidOut,
  });

  factory SheetState.inital() => SheetState(null, extent: 0.0, minExtent: 0.0, maxExtent: 1.0, isLaidOut: false);

  /// The progress between [minExtent] and [maxExtent] of the current [extent].
  /// A progress of 1 means the sheet is fully expanded, while
  /// a progress of 0 means the sheet is fully collapsed.
  double get progress => isLaidOut ? ((extent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0) : 0.0;

  /// The scroll offset when the content is bigger than the available space.
  double get scrollOffset => _extent?.scrollOffset ?? 0;

  /// Whether the [SlidingSheet] has reached its maximum extent.
  bool get isExpanded => extent >= maxExtent;

  /// Whether the [SlidingSheet] has reached its minimum extent.
  bool get isCollapsed => extent <= minExtent;

  /// Whether the [SlidingSheet] has a [scrollOffset] of zero.
  bool get isAtTop => _extent?.isAtTop ?? true;

  /// Whether the [SlidingSheet] has reached its maximum scroll extent.
  bool get isAtBottom => _extent?.isAtBottom ?? false;

  /// Whether the sheet is hidden to the user.
  bool get isHidden => extent <= 0.0;

  /// Whether the sheet is visible to the user.
  bool get isShown => !isHidden;
}

/// A controller for a [SlidingSheet].
class SheetController {
  /// Animates the sheet to the [extent].
  ///
  /// The [extent] will be clamped to the minimum and maximum extent.
  /// If the scrolling child is not at the top, it will scroll to the top
  /// first and then animate to the specified extent.
  Future snapToExtent(double extent, {Duration duration}) => _snapToExtent(extent, duration: duration);
  Future Function(double extent, {Duration duration}) _snapToExtent;

  /// Animates the scrolling child to a specified offset.
  ///
  /// If the sheet is not fully expanded it will expand first and then
  /// animate to the given [offset].
  Future scrollTo(double offset, {Duration duration, Curve curve}) =>
      _scrollTo(offset, duration: duration, curve: curve);
  Future Function(double offset, {Duration duration, Curve curve}) _scrollTo;

  /// Calls every builder function of the sheet to rebuild the widgets with
  /// the current [SheetState].
  ///
  /// This function can be used to reflect changes on the [SlidingSheet]
  /// without calling `setState(() {})` on the parent widget if that would be
  /// too expensive.
  void rebuild() => _rebuild();
  VoidCallback _rebuild;

  /// Fully collapses the sheet.
  ///
  /// Short-hand for calling `snapToExtent(minExtent)`.
  Future collapse() => _collapse();
  Future Function() _collapse;

  /// Fully expands the sheet.
  ///
  /// Short-hand for calling `snapToExtent(maxExtent)`.
  Future expand() => _expand();
  Future Function() _expand;

  /// Reveals the [SlidingSheet] if it is currently hidden.
  Future show() => _show();
  Future Function() _show;

  /// Slides the sheet off to the bottom and hides it.
  Future hide() => _hide();
  Future Function() _hide;
}

class SlidingSheetDialog {
  final SnapSpec snapSpec;
  final Duration duration;
  final Color color;
  final Color backdropColor;
  final Color shadowColor;
  final double elevation;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Border border;
  final double cornerRadius;
  final bool dismissableBackground;
  final SheetBuilder builder;
  final SheetBuilder headerBuilder;
  final SheetBuilder footerBuilder;
  final SheetListener listener;
  final SheetController controller;
  final ScrollSpec scrollSpec;
  final double maxWidth;
  SlidingSheetDialog({
    this.snapSpec = const SnapSpec(),
    this.duration = const Duration(milliseconds: 800),
    this.color,
    this.backdropColor = Colors.black54,
    this.shadowColor,
    this.elevation = 0.0,
    this.padding,
    this.margin,
    this.border,
    this.cornerRadius = 0.0,
    this.dismissableBackground = true,
    @required this.builder,
    this.headerBuilder,
    this.footerBuilder,
    this.listener,
    this.controller,
    this.scrollSpec = const ScrollSpec(overscroll: false),
    this.maxWidth = double.infinity,
  });
}

Future<T> showSlidingBottomSheet<T>(
  BuildContext context, {
  @required SlidingSheetDialog Function(BuildContext) builder,
}) {
  assert(builder != null);
  SlidingSheetDialog dialog = builder(context);

  ValueNotifier<bool> rebuilder = ValueNotifier(false);
  if (dialog.controller != null) {
    dialog.controller._rebuild = () {
      rebuilder.value = !rebuilder.value;
    };
  }

  final theme = Theme.of(context);
  return Navigator.push(
    context,
    _TransparentRoute(
      duration: dialog.duration,
      builder: (context, animation, route) {
        return ValueListenableBuilder(
          valueListenable: rebuilder,
          builder: (context, value, _) {
            dialog = builder(context);
            var snapSpec = dialog.snapSpec;

            if (snapSpec.snappings.first != 0.0) {
              snapSpec = snapSpec.copyWith(
                snappings: [0.0] + snapSpec.snappings,
              );
            }

            return SlidingSheet(
              route: route,
              snapSpec: snapSpec,
              duration: dialog.duration,
              color: dialog.color ??
                  theme.bottomSheetTheme.backgroundColor ??
                  theme.dialogTheme.backgroundColor ??
                  theme.dialogBackgroundColor ??
                  theme.backgroundColor,
              backdropColor: dialog.backdropColor,
              shadowColor: dialog.shadowColor,
              elevation: dialog.elevation,
              padding: dialog.padding,
              margin: dialog.margin,
              border: dialog.border,
              cornerRadius: dialog.cornerRadius,
              closeOnBackdropTap: dialog.dismissableBackground,
              builder: dialog.builder,
              headerBuilder: dialog.headerBuilder,
              footerBuilder: dialog.footerBuilder,
              listener: dialog.listener,
              controller: dialog.controller,
              scrollSpec: dialog.scrollSpec,
              maxWidth: dialog.maxWidth,
            );
          },
        );
      },
    ),
  );
}

/// A custom [Container] for a [SlidingSheet].
class _SheetContainer extends StatelessWidget {
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
  _SheetContainer({
    Key key,
    this.child,
    this.border,
    this.color = Colors.transparent,
    this.borderRadius = 0.0,
    this.elevation = 0.0,
    this.shadowColor = Colors.black12,
    this.margin,
    this.customBorders,
    this.alignment,
    this.boxShadows,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final br = customBorders ?? BorderRadius.circular(borderRadius);

    final List<BoxShadow> boxShadow = boxShadows ?? elevation != 0
        ? [
            BoxShadow(
              color: shadowColor ?? Colors.black12,
              blurRadius: elevation,
              spreadRadius: 0,
            ),
          ]
        : const [];

    return Container(
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: br,
        boxShadow: boxShadow,
        border: border,
        shape: BoxShape.rectangle,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: child,
      ),
    );
  }
}

/// A transparent route for a bottom sheet dialog.
class _TransparentRoute<T> extends PageRoute<T> {
  final Widget Function(BuildContext, Animation<double>, _TransparentRoute<T>) builder;
  final Duration duration;
  _TransparentRoute({
    @required this.builder,
    @required this.duration,
    RouteSettings settings,
  })  : assert(builder != null),
        super(
          settings: settings,
          fullscreenDialog: false,
        );

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      builder(context, animation, this);
}
