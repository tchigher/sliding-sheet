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
}
