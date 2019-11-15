import 'package:flutter/material.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

class W extends StatefulWidget {
  W({Key key}) : super(key: key);

  @override
  _WState createState() => _WState();
}

class _WState extends State<W> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text('Simple Example'),
      ),
      /* floatingActionButton: FloatingActionButton(
        onPressed: showAsBottomSheet,
        child: Icon(
          Icons.place,
        ),
      ), */
      body: Stack(
        children: <Widget>[
          SlidingSheet(
            elevation: 8,
            cornerRadius: 16,
            snapBehavior: const SnapBehavior(
              snap: true,
              snappings: [100, double.infinity],
              positioning: SnapPositioning.pixelOffset,
            ),
            builder: (context, state) {
              return Container(
                height: 300,
                child: Center(
                  child: Text(
                    'This is the content of the sheet',
                    style: Theme.of(context).textTheme.body1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

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
}
