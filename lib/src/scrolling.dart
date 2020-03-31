part of 'sheet.dart';

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
  bool get isAtMin => currentExtent <= minExtent && minExtent != maxExtent;

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

  _SheetExtent get extent => sheet.extent;
  void Function(double) get onPop => sheet._pop;
  Duration get duration => sheet.widget.duration;
  SnapSpec get snapSpec => sheet.snapSpec;

  double get currentExtent => extent.currentExtent;
  double get maxExtent => extent.maxExtent;
  double get minExtent => extent.minExtent;

  bool inDrag = false;
  bool animating = false;
  bool get inInteraction => inDrag || animating;

  _DraggableScrollableSheetScrollPosition _currentPosition;

  AnimationController controller;

  TickerFuture snapToExtent(
    double snap,
    TickerProvider vsync, {
    double velocity = 0,
    Duration duration,
    bool clamp = true,
  }) {
    _dispose();

    if (clamp) snap = snap.clamp(extent.minExtent, extent.maxExtent);
    final speedFactor = (math.max((currentExtent - snap).abs(), .25) / maxExtent) *
        (1 - ((velocity.abs() / 2000) * 0.3).clamp(.0, 0.3));
    duration = this.duration * speedFactor;

    controller = AnimationController(duration: duration, vsync: vsync);
    final tween = Tween(begin: extent.currentExtent, end: snap).animate(
      CurvedAnimation(parent: controller, curve: velocity.abs() > 300 ? Curves.easeOutCubic : Curves.ease),
    );

    animating = true;
    controller.addListener(() => this.extent.currentExtent = tween.value);
    return controller.forward()
      ..whenComplete(() {
        controller.dispose();
        animating = false;

        // Invoke the snap callback.
        snapSpec?.onSnap?.call(
          sheet.state,
          sheet._reverseSnap(snap),
        );
      });
  }

  void imitiateDrag(double delta) {
    inDrag = true;
    extent.addPixelDelta(delta);
  }

  void imitateFling([double velocity = 0.0]) {
    if (velocity != 0.0) {
      _currentPosition?.goBallistic(velocity);
    } else {
      inDrag = true;
      _currentPosition?.didEndScroll();
    }
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

  void _dispose() {
    if (animating) {
      controller?.stop();
      controller?.dispose();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
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

  SnapSpec get snapBehavior => scrollController.snapSpec;
  ScrollSpec get scrollSpec => scrollController.sheet.scrollSpec;
  List<double> get snappings => extent.snappings;
  bool get fromBottomSheet => extent.isFromBottomSheet;
  bool get snap => snapBehavior.snap;
  bool get shouldScroll => pixels > 0.0 && extent.isAtMax;
  bool get isCoveringFullExtent => scrollController.sheet.isCoveringFullExtent;
  double get availableHeight => extent.targetHeight;
  double get currentExtent => extent.currentExtent;
  double get maxExtent => extent.maxExtent;
  double get minExtent => extent.minExtent;
  double get offset => scrollController.offset;

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
    } else if (!extent.isAtMin) {
      super.applyUserOffset(delta);
    }
  }

  @override
  void didEndScroll() {
    super.didEndScroll();

    if (inDrag &&
        ((snap && !extent.isAtMax && !extent.isAtMin && !shouldScroll) ||
            (fromBottomSheet && currentExtent < minExtent))) {
      goSnapped(0.0);
    }

    inDrag = false;
  }

  @override
  void goBallistic(double velocity) {
    up = !velocity.isNegative;
    lastVelocity = velocity;

    // There is an issue with the bouncing scroll physics that when the sheet doesn't cover the full extent
    // the bounce back of the simulation would be so fast to close the sheet again, although it was swiped
    // upwards. Here we soften the bounce back to prevent that from happening.
    if (velocity < 0 && !inDrag && (scrollSpec.physics is BouncingScrollPhysics) && !isCoveringFullExtent) {
      velocity /= 8;
    }

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
      if ((velocity > 0 && extent.isAtMax) ||
          (velocity < 0 && (!fromBottomSheet ? extent.isAtMin : currentExtent <= 0.0))) {
        // Make sure we pass along enough velocity to keep scrolling - otherwise
        // we just "bounce" off the top making it look like the list doesn't
        // have more to scroll.
        velocity = ballisticController.velocity + (physics.tolerance.velocity * ballisticController.velocity.sign);
        super.goBallistic(velocity);
        ballisticController.stop();

        // Pop the route when reaching 0.0 extent.
        if (fromBottomSheet && currentExtent <= 0.0) {
          onPop(0.0);
        }
      }
    }

    ballisticController.addListener(_tick);
    await ballisticController.animateWith(simulation);
    ballisticController.dispose();

    if (fromBottomSheet && currentExtent < minExtent && currentExtent > 0.0) {
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
