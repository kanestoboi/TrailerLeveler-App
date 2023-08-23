import 'package:flutter/material.dart';
import 'package:trailer_leveler_app/app_data.dart';

class DeviceOrientationPage extends StatefulWidget {
  const DeviceOrientationPage({super.key});

  @override
  _DeviceOrientationPageState createState() => _DeviceOrientationPageState();
}

class _DeviceOrientationPageState extends State<DeviceOrientationPage> {
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
                        color: appData.deviceOrientation == 1
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
                        color: appData.deviceOrientation == 2
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
                        color: appData.deviceOrientation == 3
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
                        color: appData.deviceOrientation == 4
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
                        color: appData.deviceOrientation == 5
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
                        color: appData.deviceOrientation == 6
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              width: 400,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Set Orientation'),
              ),
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
            appData.deviceOrientation = 1;
          });
          break;
        }
      case 2:
        {
          debugPrint("Selection 2");
          setState(() {
            appData.deviceOrientation = 2;
          });
          break;
        }
      case 3:
        {
          debugPrint("Selection 3");
          setState(() {
            appData.deviceOrientation = 3;
          });
          break;
        }
      case 4:
        {
          debugPrint("Selection 4");
          setState(() {
            appData.deviceOrientation = 4;
          });
          break;
        }
      case 5:
        {
          debugPrint("Selection 5");
          setState(() {
            appData.deviceOrientation = 5;
          });
          break;
        }
      case 6:
        {
          debugPrint("Selection 6");
          setState(() {
            appData.deviceOrientation = 6;
          });
          break;
        }
    }
  }
}
