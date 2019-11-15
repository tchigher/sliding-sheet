# Sliding Sheet (Preview)

A widget that can be dragged and scrolled in a single gesture and snapped to a list of extents.

<a href="https://github.com/BendixMa/sliding-sheet/blob/master/example/lib/main.dart">
  <img width="205px" alt="Example of a SlidingSheet" src="assets/example.gif"/>
</a>



## Installing (Soon)
---
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
---

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
          snapBehavior: const SnapBehavior(
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

This method can be used to show a `SlidingSheet` as a `BottomSheetDialog`.

```dart
void showAsBottomSheet() async {
  final result = await showSlidingBottomSheet(
    context,
    elevation: 8,
    cornerRadius: 16,
    snapBehavior: const SnapBehavior(
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

### ListViews and Columns

The children of a `SlidingSheet` are not allowed to have an inifinite height. Therefore when using a `Column` as a child of a `SlidingSheet`, make sure to set the `mainAxisSize` to `MainAxisSize.min`. Similarly when using a `ListView`, make sure to set `shrinkWrap` to `true` and `physics` to `NeverScrollableScrollPhysics`.

### Snapping

A `SlidingSheet` can snap to multiple extents. You can customize the snapping behavior by
passing an instance of `SnapBehavior` to the `SlidingSheet`.

 Parameter | Description 
--- | ---
snap | If true, the `SlidingSheet` will snap to the provided `snappings`. If false, the `SlidingSheet` will slide from minExtent to maxExtent and then begin to scroll.
snappings | The extents that the `SlidingSheet` will snap to, when the user ends a drag interaction. The minimum and maximum values will represent the bounds in which the `SlidingSheet` will slide until it reaches the maximum from which on it will scroll.
positioning | Can be set to one of these three values: `SnapPositioning.relativeToAvailableSpace` - Positions the snaps relative to total available height that the `SlidingSheet` can expand to. All values must be between 0 and 1. E.g. a snap of `0.5` in a `Scaffold` without an `AppBar` would mean that the snap would be positioned at 40% of the screen height, irrespective of the height of the `SlidingSheet`. `SnapPositioning.relativeToSheetHeight` - Positions the snaps relative to the total height of the sheet. All values must be between 0 and 1. E.g. a snap of `0.5` and a total sheet size of 300 pixels would mean the snap would be positioned at a 150 pixel offset from the bottom. `SnapPositioning.pixelOffset` - Positions the snaps at a fixed pixel offset. `double.infinity` can be used to refer to the total available space without having to compute it yourself.

<p float="left">
  <img width="205px" alt="SnapPositioning.relativeToAvailableSpace with a snap of 0.5" src="assets/example_snapping_relativeToAvailableSpace.png"/>
  <img width="205px" alt="SnapPositioning.relativeToSheetHeight with a snap of 0.5" src="assets/example_snapping_relativeToSheetHeight.png"/>
  <img width="205px" alt="SnapPositioning.pixelOffset with a snap of 100" src="assets/example_snapping_pixelOffset.png"/>
</p>








