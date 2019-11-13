import 'package:example/util/my_container.dart';
import 'package:example/util/util.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final controller = SheetController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example App',
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            buildMap(),
            buildSheet(),
          ],
        ),
      ),
    );
  }

  Widget buildSheet() {
    return SlidingSheet(
      controller: controller,
      color: Colors.white,
      elevation: 16,
      cornerRadius: 16,
      border: Border.all(
        color: Colors.grey.shade300,
        width: 3,
      ),
      snapBehavior: const SnapBehavior(
        snap: true,
        positioning: SnapPositioning.relativeToAvailableSize,
        snappings: [0.3, 0.7, 1.0],
      ),
      listener: (state) {
        if (!state.isExpanded) controller.rebuild();
      },
      headerBuilder: buildHeader,
      builder: (context, state) {
        return Container(
          height: 600,
          color: Colors.red,
        );
      },
    );
  }

  Widget buildHeader(BuildContext context, SheetState state) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final progress = state.progress;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 2 + (MediaQuery.of(context).padding.top * fInRange(.7, 1.0, progress))),
          Align(
            alignment: Alignment.topCenter,
            child: MyContainer(
              width: 16,
              height: 4,
              borderRadius: 2,
              color: Colors.grey.withOpacity(.5 * (1 - fInRange(0.7, 1.0, progress))),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                '44 min',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 22,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '(36 km)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Fastest route now due to traffic conditions.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget buildMap() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(53.551086, 9.993682),
        zoom: 9,
        maxZoom: 15,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png",
          tileSize: 256,
        ),
        MarkerLayerOptions(
          markers: [
            Marker(
              point: LatLng(40.441753, -80.011476),
              builder: (ctx) => Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 48.0,
              ),
              height: 60,
            ),
          ],
        ),
      ],
    );
  }
}
