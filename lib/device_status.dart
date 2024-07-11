import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class DeviceStatus extends StatefulWidget {
  final Stream<String>? connectionStateStream;
  final Stream<int>? batteryChargePercentageStream;
  final Stream<String>? productIDStream;
  final Stream<String>? deviceNameStream;
  final String productID;

  final ImageProvider camperSide;

  const DeviceStatus({
    Key? super.key,
    this.connectionStateStream,
    this.batteryChargePercentageStream,
    this.productIDStream,
    this.deviceNameStream,
    required this.productID,
    required this.camperSide,
  });

  @override
  _DeviceStatusState createState() => _DeviceStatusState();
}

class _DeviceStatusState extends State<DeviceStatus> {
  int _batteryChargePercentage = 0;
  bool _connectedStatus = false;
  String _productID = "";
  String _deviceName = "";

  StreamSubscription<String>? connectionStateStreamSubscription;
  StreamSubscription<int>? batteryChargePercentageStreamSubscription;
  StreamSubscription<String>? productIDStreamSubscription;
  StreamSubscription<String>? deviceNameStreamSubscription;

  @override
  void dispose() {
    // TODO: implement dispose
    cancelStreamSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initialiseStreamSubscriptions();

    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.95, // Width of the box
      height: 110, // Height of the box
      padding: EdgeInsets.all(9.0), // Adding 16.0 padding to all sides

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0), // Adding rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Shadow color
            spreadRadius: 2, // Spread radius
            blurRadius: 6, // Blur radius
            offset: const Offset(0, 3), // Shadow offset
          ),
        ],
        color: Colors.white,

        border: Border.all(
          color: Colors.white,
          width: 1.0,
        ),
      ),
      child: Row(children: [
        Expanded(
            flex: 3,
            child: Container(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .start, // Aligns children to the start (left)
              children: [
                Expanded(
                    flex: 1,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Making the text bold
                          fontFamily: 'Inter',
                          color: const Color(0xFF737373).withOpacity(0.4),
                          fontSize: 12.0,
                          height: 14.52 / 12,
                        ),
                        children: [
                          const TextSpan(
                            text: "Product ID: ",
                          ),
                          TextSpan(
                            text: _productID,
                            style: TextStyle(
                              color: const Color(0xFF2196F3).withOpacity(
                                  0.4), // Changing the color of the number part
                              // You can add more style properties here if needed
                            ),
                          ),
                        ],
                      ),
                    )),
                const Expanded(
                    flex: 2,
                    child: Text(
                      "Trailer Leveler",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Color(0xFF2F2F2F),
                          fontSize: 16.0,
                          height: 19.36 / 16.0),
                    )),
                Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(0),
                      width: 80,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.07),
                        border: Border.all(
                          color: const Color.fromARGB(255, 255, 255, 255)
                              .withOpacity(0.07),
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 25,
                              height: 25,
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  Colors
                                      .black54, // Replace with the color you want
                                  BlendMode.srcIn,
                                ),
                                child: getBatteryIcon(),
                              ),
                            ), // Icon you want to add
                            // Add some spacing between the icon and text
                            Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "  " +
                                      _batteryChargePercentage.toString() +
                                      "%",
                                  maxLines: 1,
                                )),
                          ],
                        ),
                      ),
                    ))
              ],
            ))),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(flex: 3, child: Image(image: widget.camperSide)),
              Expanded(
                  flex: 1,
                  child: Text(
                    _connectedStatus ? "Connected" : "Disconnected",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF2F2F2F),
                    ),
                  ))
            ],
          ),
        )
      ]),
    );
  }

  Widget getBatteryIcon() {
    if (_batteryChargePercentage <= 10) {
      return SvgPicture.asset(
        'assets/battery-empty.svg',
        width: 20,
        height: 20,
      );
    } else if (_batteryChargePercentage <= 55) {
      return SvgPicture.asset(
        'assets/battery-empty-1.svg',
        width: 20,
        height: 20,
      );
    } else if (_batteryChargePercentage <= 90) {
      return SvgPicture.asset(
        'assets/battery-3full.svg',
        width: 20,
        height: 20,
      );
    } else if (_batteryChargePercentage > 90) {
      return SvgPicture.asset(
        'assets/battery-full.svg',
        width: 20,
        height: 20,
      );
    } else {
      return SvgPicture.asset(
        'assets/battery-disable.svg', // Replace with your SVG image path
        width: 20, // Adjust the width as needed
        height: 20, // Adjust the height as needed
      );
    }
  }

  Future<void> cancelStreamSubscriptions() async {
    await batteryChargePercentageStreamSubscription?.cancel();
    await connectionStateStreamSubscription?.cancel();

    print("Streams Cancelled");
  }

  void initialiseStreamSubscriptions() {
    connectionStateStreamSubscription =
        widget.connectionStateStream?.listen((connectionStatus) {
      if (connectionStatus == "connected") {
        _connectedStatus = true;
      } else {
        _connectedStatus = false;
      }

      if (mounted) {
        setState(() {});
      }
    });

    batteryChargePercentageStreamSubscription =
        widget.batteryChargePercentageStream?.listen((batteryLevel) {
      _batteryChargePercentage = batteryLevel;
      if (mounted) {
        setState(() {});
      }
    });

    productIDStreamSubscription = widget.productIDStream?.listen((productID) {
      _productID = productID;
      if (mounted) {
        setState(() {});
      }
    });

    deviceNameStreamSubscription =
        widget.deviceNameStream?.listen((deviceName) {
      _deviceName = deviceName;
      if (mounted) {
        setState(() {});
      }
    });
  }
}
