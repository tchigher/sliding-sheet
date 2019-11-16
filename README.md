# Sliding Sheet

A widget that can be dragged and scrolled in a single gesture and snapped to a list of extents.

<a href="https://github.com/BendixMa/sliding-sheet/blob/master/example/lib/main.dart">
  <img width="205px" alt="Example of a SlidingSheet" src="assets/example.gif"/>
</a>

Click <a href="https://github.com/BendixMa/sliding-sheet/blob/master/example/lib/main.dart">here</a> to view the full example.

## Installing

Add it to your `pubspec.yaml` file:
```yaml
dependencies:
  sliding_up_panel: ^0.0.1
```
Install packages from the command line
```
flutter packages get
```

## Usage

There are two ways in which you can use a `SlidingSheet`: either as a permanent (or persistent) `Widget` in your
widget tree or as a `BottomSheetDialog`. 

### As a Widget

This method can be used to show the `SlidingSheet` permanently (usually above your other widget) as shown in the example.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade200,
    appBar: AppBar(
      title: Text('Simple Example'),
    ),
    body: Stack(
      children: <Widget>[
        Center(
          child: Text('This widget is below the SlidingSheet'),
        ),

        SlidingSheet(
          elevation: 8,
          cornerRadius: 16,
          snapSpec: const SnapSpec(
            // Enable snapping. This is true by default.
            snap: true,
            // Set custom snapping points.
            snappings: [0.4, 0.7, 1.0],
            // Define to what the snappings relate to. In this case, 
            // the total available space that the sheet can expand to.
            positioning: SnapPositioning.relativeToAvailableSpace,
          ),
          builder: (context, state) {
            // This is the content of the sheet that will get
            // scrolled, if the content is bigger than the available
            // height of the sheet.
            return Container(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Text('This is the content of the sheet'),
              ),
            );
          },
        )
      ],
    ),
  );
}
```

#### Result:
<img width="205px" alt="Example" src="assets/usage_example.gif" href/>

### As a BottomSheetDialog

This method can be used to show a `SlidingSheet` as a `BottomSheetDialog` by calling the `showSlidingBottomSheet` function.

```dart
void showAsBottomSheet() async {
  final result = await showSlidingBottomSheet(
    context,
    elevation: 8,
    cornerRadius: 16,
    snapSpec: const SnapSpec(
      snap: true,
      snappings: [0.4, 0.7, 1.0],
      positioning: SnapPositioning.relativeToAvailableSpace,
    ),
    builder: (context, state) {
      return Container(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Material(
            child: InkWell(
              onTap: () => Navigator.pop(context, 'This is the result.'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'This is the content of the sheet',
                  style: Theme.of(context).textTheme.body1,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  print(result); // This is the result.
}
```
#### Result:
<img width="205px" alt="Example" src="assets/usage_example_bottom_sheet.gif"/>

### Snapping

A `SlidingSheet` can snap to multiple extents or to no at all. You can customize the snapping behavior by
passing an instance of `SnapSpec` to the `SlidingSheet`.

 Parameter | Description 
--- | ---
snap | If true, the `SlidingSheet` will snap to the provided `snappings`. If false, the `SlidingSheet` will slide from minExtent to maxExtent and then begin to scroll, if the content is bigger than the available height.
snappings | The extents that the `SlidingSheet` will snap to, when the user ends a drag interaction. The minimum and maximum values will represent the bounds in which the `SlidingSheet` will slide until it reaches the maximum from which on it will scroll.
positioning | Can be set to one of these three values: `SnapPositioning.relativeToAvailableSpace` - Positions the snaps relative to total available height that the `SlidingSheet` can expand to. All values must be between 0 and 1. E.g. a snap of `0.5` in a `Scaffold` without an `AppBar` would mean that the snap would be positioned at 40% of the screen height, irrespective of the height of the `SlidingSheet`. `SnapPositioning.relativeToSheetHeight` - Positions the snaps relative to the total height of the sheet. All values must be between 0 and 1. E.g. a snap of `0.5` and a total sheet size of 300 pixels would mean the snap would be positioned at a 150 pixel offset from the bottom. `SnapPositioning.pixelOffset` - Positions the snaps at a fixed pixel offset. `double.infinity` can be used to refer to the total available space without having to compute it yourself.
onSnap | A callback function that gets invoked when the `SlidingSheet` snaps to an extent.

<p float="left">
  <img width="205px" alt="SnapPositioning.relativeToAvailableSpace with a snap of 0.5" src="assets/example_snapping_relativeToAvailableSpace.png"/>
  <img width="205px" alt="SnapPositioning.relativeToSheetHeight with a snap of 0.5" src="assets/example_snapping_relativeToSheetHeight.png"/>
  <img width="205px" alt="SnapPositioning.pixelOffset with a snap of 100" src="assets/example_snapping_pixelOffset.png"/>
</p>

### SheetController

The `SheetController` can be used to change the state of a `SlidingSheet` manually, simply passing an instance of `SheetController` to a `SlidingSheet`. Note that the methods can only be used after the `SlidingSheet` has been rendered, however calling them before wont throw an exception.

 Method | Description 
--- | ---
`expand()` | Expands the `SlidingSheet` to the maximum extent.
`collapse()` | Collapses the `SlidingSheet` to the minimum extent.
`snapToExtent()` | Snaps the `SlidingSheet` to an arbitrary extent. The extent will be clamped to the minimum and maximum extent. If the scroll offset is > 0, the `SlidingSheet` will first scroll to the top and then slide to the extent.
`scrollTo()` | Scrolls the `SlidingSheet` to the given offset. If the `SlidingSheet` is not yet at its maximum extent, it will first snap to the maximum extent and then scroll to the given offset.
`rebuild()` | Calls all builders of the `SlidingSheet` to rebuild their children. This method can be used to reflect changes in the `SlidingSheet`s children without calling `setState(() {});` on the parent widget to improve performance.

### Headers and Footers

Headers and footers are UI elements of a `SlidingSheet` that will be displayed at the top or bottom of a `SlidingSheet` respectively and will not get scrolled. The scrollable content will then live in between the header and the footer if specified. Delegating the touch events to the `SlidingSheet` is done for you. Example:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade200,
    appBar: AppBar(
      title: Text('Simple Example'),
    ),
    body: Stack(
      children: <Widget>[
        SlidingSheet(
          elevation: 8,
          cornerRadius: 16,
          snapSpec: const SnapSpec(
            snap: true,
            snappings: [112, 400, double.infinity],
            positioning: SnapPositioning.pixelOffset,
          ),
          builder: (context, state) {
            return Container(
              height: 500,
              child: Center(
                child: Text(
                  'This is the content of the sheet',
                  style: Theme.of(context).textTheme.body1,
                ),
              ),
            );
          },
          headerBuilder: (context, state) {
            return Container(
              height: 56,
              width: double.infinity,
              color: Colors.green,
              alignment: Alignment.center,
              child: Text(
                'This is the header',
                style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
              ),
            );
          },
          footerBuilder: (context, state) {
            return Container(
              height: 56,
              width: double.infinity,
              color: Colors.yellow,
              alignment: Alignment.center,
              child: Text(
                'This is the footer',
                style: Theme.of(context).textTheme.body1.copyWith(color: Colors.black),
              ),
            );
          },
        ),
      ],
    ),
  );
}
```
#### Result:
<img width="205px" alt="Simple header/footer example" src="assets/example_header_footer.gif"/>

### ListViews and Columns

The children of a `SlidingSheet` are not allowed to have an inifinite (unbounded) height. Therefore when using a `ListView`, make sure to set `shrinkWrap` to `true` and `physics` to `NeverScrollableScrollPhysics`. Similarly when using a `Column` as a child of a `SlidingSheet`, make sure to set the `mainAxisSize` to `MainAxisSize.min`.

### Reflecting changes

To improve performace, the children of a `SlidingSheet` are not rebuild when it slides or gets scrolled. You can however pass a callback function to the `listener` parameter of a `SlidingSheet`, that gets called with the current `SheetState` whenever the `SlidingSheet` slides or gets scrolled. You can then rebuild your UI by calling `setState(() {})`, `(instance of SheetController).rebuild()` or by a different state management solution to rebuild the sheet. The example for instance decreases the corner radius of the `SlidingSheet` as it gets dragged to the top and increases the headers top padding by the status bar height.

<img width="205px" alt="Example on how to reflect changes in the SlidingSheet" src="assets/example_reflecting_changes.gif"/>