import 'package:flutter/material.dart';

class DeviceOrientationPage extends StatefulWidget {
  final int initialOrientation; // Add this field

  const DeviceOrientationPage({Key? key, required this.initialOrientation})
      : super(key: key);

  @override
  _DeviceOrientationPageState createState() => _DeviceOrientationPageState();
}

class _DeviceOrientationPageState extends State<DeviceOrientationPage> {
  int selectedOrientation = 0;

  @override
  void initState() {
    super.initState();
    selectedOrientation = widget.initialOrientation;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.lightBlue,
            width: 400,
            child: const Text(
              "Front Direction \u2B09",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                height: 1,
                fontSize: 30,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Material(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: selectedOrientation == 1
                            ? Colors.blue
                            : Colors.white,
                        child: Image.asset('images/device-orientation-1.png',
                            width: 100),
                      ),
                      onTap: () {
                        handleDeviceOrientationSelection(1);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: selectedOrientation == 2
                            ? Colors.blue
                            : Colors.white,
                        child: Image.asset('images/device-orientation-2.png',
                            width: 100),
                      ),
                      onTap: () {
                        handleDeviceOrientationSelection(2);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Material(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: selectedOrientation == 3
                            ? Colors.blue
                            : Colors.white,
                        child: Image.asset('images/device-orientation-3.png',
                            width: 100),
                      ),
                      onTap: () {
                        handleDeviceOrientationSelection(3);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: selectedOrientation == 4
                            ? Colors.blue
                            : Colors.white,
                        child: Image.asset('images/device-orientation-4.png',
                            width: 100),
                      ),
                      onTap: () {
                        handleDeviceOrientationSelection(4);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Material(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: selectedOrientation == 5
                            ? Colors.blue
                            : Colors.white,
                        child: Image.asset('images/device-orientation-5.png',
                            width: 100),
                      ),
                      onTap: () {
                        handleDeviceOrientationSelection(5);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    child: InkWell(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: selectedOrientation == 6
                            ? Colors.blue
                            : Colors.white,
                        child: Image.asset('images/device-orientation-6.png',
                            width: 100),
                      ),
                      onTap: () {
                        handleDeviceOrientationSelection(6);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            width: 400,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(selectedOrientation);
              },
              child: const Text('Set Orientation'),
            ),
          ),
        ],
      ),
    );
  }

  void handleDeviceOrientationSelection(int selection) {
    switch (selection) {
      case 1:
        {
          debugPrint("Selection 1");

          setState(() {
            selectedOrientation = 1;
          });
          break;
        }
      case 2:
        {
          debugPrint("Selection 2");
          setState(() {
            selectedOrientation = 2;
          });
          break;
        }
      case 3:
        {
          debugPrint("Selection 3");
          setState(() {
            selectedOrientation = 3;
          });
          break;
        }
      case 4:
        {
          debugPrint("Selection 4");
          setState(() {
            selectedOrientation = 4;
          });
          break;
        }
      case 5:
        {
          debugPrint("Selection 5");
          setState(() {
            selectedOrientation = 5;
          });
          break;
        }
      case 6:
        {
          debugPrint("Selection 6");
          setState(() {
            selectedOrientation = 6;
          });
          break;
        }
    }
  }
}
