import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VehicleAngle extends StatefulWidget {
  final Stream<double>? xAngleStream;
  final Stream<double>? yAngleStream;

  final double caravanWidth;
  final double caravanLength;
  final ImageProvider camperRear;
  final ImageProvider camperSide;

  const VehicleAngle({
    Key? super.key,
    this.xAngleStream,
    this.yAngleStream,
    required this.camperSide,
    required this.camperRear,
    required this.caravanWidth,
    required this.caravanLength,
  });

  @override
  _VehicleAngleState createState() => _VehicleAngleState();
}

class _VehicleAngleState extends State<VehicleAngle> {
  double _xAngle = 0;
  double _yAngle = 0;

  String horizontalReference = 'right';

  String downArrow = "\u2b07";
  String upArrow = "\u2b06";

  StreamSubscription<double>? xAngleStreamSubscription;
  StreamSubscription<double>? yAngleStreamSubscription;

  @override
  void dispose() {
    // TODO: implement dispose
    cancelStreamSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initialiseStreamSubscriptions();

    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(
              16.0, 32.0, 16.0, 10.0), // left, top, right, bottom
          child: Center(
            child: Transform.rotate(
              angle: pi / 180.0 * (_xAngle),
              child: Image(
                image: widget.camperRear,
                width: 125,
              ),
            ),
          )),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            child: getLeftHeightStringWidget(),
          ),
          Container(
            alignment: Alignment.center,
            child: getXAngleStringWidget(),
          ),
          Container(
            alignment: Alignment.center,
            child: getRightHeightStringWidget(),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
            16.0, 32.0, 16.0, 10.0), // left, top, right, bottom
        child: Center(
          child: Transform.rotate(
            angle: getJockeyImageAngle(),
            child: Image(image: widget.camperSide),
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            child: getJockyHeightWidget(),
          ),
          Container(
            alignment: Alignment.center,
            child: getYAngleStringWidget(),
          ),
          Container(
            child: SizedBox(),
          )
        ],
      ),
    ]);
  }

  Widget getXAngleStringWidget() {
    var format = NumberFormat("##0.00", "en_US");

    String angleString;
    Color textColor = Colors.black54;

    double adjustedAngle = (_xAngle);
    double roundedAngle = (adjustedAngle / 0.05).round() * 0.05;

    angleString = '${format.format(roundedAngle)}°';

    return Text(
      angleString,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget getYAngleStringWidget() {
    var format = NumberFormat("##0.00", "en_US");

    String angleString;
    Color textColor = Colors.black54;

    double roundedAngle = (_yAngle / 0.05).round() * 0.05;

    angleString = '${format.format(roundedAngle)}°';

    return Text(
      angleString,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget getLeftHeightStringWidget() {
    double height;

    if (horizontalReference == 'right') {
      height = double.parse(
          (tan((_xAngle) * pi / 180.0) * this.widget.caravanWidth)
              .toStringAsFixed(3));
    } else {
      height = 0.0;
    }

    var format = NumberFormat("##0.000", "en_US");

    String heightString;
    Color textColor = Colors.red;

    if (height > 0) {
      heightString = '$downArrow ${format.format(height.abs())}';
    } else if (height < 0) {
      heightString = '$upArrow ${format.format(height.abs())}';
    } else {
      heightString = '0.000';
      textColor = Color(0xFF4CB050);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          horizontalReference = 'right';
        });
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.white,
          border: Border.all(
            color: textColor,
            width: 1.0,
          ),
        ),
        child: Text(
          heightString,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 36,
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter'),
        ),
      ),
    );
  }

  Widget getRightHeightStringWidget() {
    double height;

    if (horizontalReference == 'left') {
      height = double.parse(
          (tan((_xAngle) * pi / 180.0) * this.widget.caravanWidth)
              .toStringAsFixed(3));
    } else {
      height = 0.0;
    }

    var format = NumberFormat("##0.000", "en_US");

    String heightString;
    Color textColor = Colors.red;

    if (height < 0) {
      heightString = '$downArrow ${format.format(height.abs())}';
    } else if (height > 0) {
      heightString = '$upArrow ${format.format(height.abs())}';
    } else {
      heightString = '0.000';
      textColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          horizontalReference = 'left';
        });
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.white,
          border: Border.all(
            color: textColor,
            width: 1.0,
          ),
        ),
        child: Text(
          heightString,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 36,
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter'),
        ),
      ),
    );
  }

  Future<void> cancelStreamSubscriptions() async {
    await xAngleStreamSubscription?.cancel();
    await yAngleStreamSubscription?.cancel();

    print("Streams Cancelled");
  }

  void initialiseStreamSubscriptions() {
    xAngleStreamSubscription = widget.xAngleStream?.listen((xangle) {
      _xAngle = xangle;
    });
    yAngleStreamSubscription = widget.yAngleStream?.listen((yangle) {
      _yAngle = yangle;
    });

    if (mounted) {
      setState(() {});
    }
  }

  double getJockeyImageAngle() {
    return pi / 180 * _yAngle * -1;
  }

  Widget getJockyHeightWidget() {
    double height;
    String heightString;
    Color textColor = Colors.red;
    var format = NumberFormat("##0.000", "en_US");

    height = double.parse((tan((_yAngle) * pi / 180.0) * widget.caravanLength)
        .toStringAsFixed(3));

    if (height > 0) {
      heightString = '$upArrow ${format.format(height.abs())}';
    } else if (height < 0) {
      heightString = '$downArrow ${format.format(height.abs())}';
    } else {
      heightString = '0.000';
      textColor = Colors.green;
    }

    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
        border: Border.all(
          color: textColor,
          width: 1.0,
        ),
      ),
      child: Text(
        heightString,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 36,
            color: textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter'),
      ),
    );
  }
}
