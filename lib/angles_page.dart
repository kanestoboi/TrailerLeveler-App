import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:trailer_leveler_app/bluetooth_devices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:trailer_leveler_app/app_data.dart';

class AnglesPage extends StatefulWidget {
  const AnglesPage({Key? key}) : super(key: key);

  @override
  PageState createState() => PageState();
}

class PageState extends State<AnglesPage> {
  double _xAngleCalibration = 0.0;
  double _yAngleCalibration = 0.0;
  double _zAngleCalibration = 0.0;
  double _xAngle = 0.0;
  double _yAngle = 0.0;
  double _zAngle = 0.0;
  double? _batteryLevel;

  double _caravanWidth = 0.0001;
  double _caravanLength = 0.0001;

  String downArrow = "\u2b07";
  String upArrow = "\u2b06";
  String batterySymbol = "\u{1F50B}";

  String horizontalReference = 'right';

  bool deviceConnected = false;

  // save in the state for caching!
  late SharedPreferences _sharedPreferences;

  @override
  void initState() {
    super.initState();
  }

  Future<void> setupSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();

    double xAngleSharedPreferences =
        _sharedPreferences.getDouble('xAngleCalibration') ?? 0;

    double yAngleSharedPreferences =
        _sharedPreferences.getDouble('yAngleCalibration') ?? 0;

    double zAngleSharedPreferences =
        _sharedPreferences.getDouble('zAngleCalibration') ?? 0;

    double? _caravanWidthSharedPreferences =
        _sharedPreferences.getDouble('caravanWidth');

    double? _caravanLengthSharedPreferences =
        _sharedPreferences.getDouble('caravanLength');

    int orientationSharedPreferences =
        _sharedPreferences.getInt('deviceOrientation') ?? 1;

    _xAngleCalibration = xAngleSharedPreferences;
    _yAngleCalibration = yAngleSharedPreferences;
    _zAngleCalibration = zAngleSharedPreferences;

    if (_caravanWidthSharedPreferences != null) {
      _caravanWidth = _caravanWidthSharedPreferences;
    }

    if (_caravanLengthSharedPreferences != null) {
      _caravanLength = _caravanLengthSharedPreferences;
    }

    appData.deviceOrientation = orientationSharedPreferences;
  }

  @override
  Widget build(BuildContext context) {
    // Perform an action after the build is completed
    SchedulerBinding.instance.addPostFrameCallback((durarion) {
      // setup the shared prefrences and then get the length and width stored
      setupSharedPreferences().then((value) {
        if (_caravanWidth == 0.0001 && _caravanLength == 0.0001) {
          _caravanWidth = 1.0;
          _caravanLength = 1.0;
          _showDimensionsDialog();
        }
      });
    });

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size(double.infinity, kToolbarHeight),
          child: Builder(
              builder: (context) => AppBar(
                      title: const Text('Trailer Leveler'),
                      actions: <Widget>[
                        getBatteryLevelWidget(),
                        menuWidget(),
                      ]))

          // StreamBuilder
          ),
      body: getLevelIndicatorWidget(),
    );
  }

  Widget bluetoothDeviceWidget() {
    return IconButton(
        icon: const Icon(Icons.add_link),
        onPressed: _navigateToBluetoothDevicesPage);
  }

  Widget menuWidget() {
    return PopupMenuButton<String>(
      onSelected: handleClick,
      itemBuilder: (BuildContext context) {
        return {'Calibrate', 'Set Caravan Dimensions', 'Set Device Orientation'}
            .map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  void _navigateToBluetoothDevicesPage() async {
    MaterialPageRoute bluetoothDevicesPageRoute = MaterialPageRoute(
        builder: (BuildContext context) => const BluetoothDevices(
              title: "devices",
            ));
    final result = await Navigator.of(context).push(bluetoothDevicesPageRoute);

    result.listen((value) {
      setState(() {
        if (value['xAngle'] != null) {
          _xAngle = value['xAngle'];
        }
        if (value['yAngle'] != null) {
          _yAngle = value['yAngle'];
        }
        if (value['zAngle'] != null) {
          _zAngle = value['zAngle'];
        }
        if (value['batteryLevel'] != null) {
          _batteryLevel = value['batteryLevel'];
        }
        if (value['connected'] != null) {
          if (value['connected'] == 1.0) {
            deviceConnected = true;
          } else {
            deviceConnected = false;
            _showDisconnectedDialog();
          }
        }
      });
    });
  }

  Future<void> _showDisconnectedDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disconnected'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('The trailer leveler unexpectedly disconnected'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget getLevelIndicatorWidget() {
    return Stack(
      children: [
        Center(
          child: Column(
            children: [
              Padding(
                  padding: EdgeInsets.fromLTRB(
                      16.0, 32.0, 16.0, 10.0), // left, top, right, bottom
                  child: Center(
                    child: Transform.rotate(
                      angle: pi / 180.0 * (_xAngle - _xAngleCalibration),
                      child: Image.asset('images/camper_rear.png', width: 100),
                    ),
                  )),
              Row(
                children: <Widget>[
                  Expanded(
                    child: getLeftHeightStringWidget(),
                    flex: 2,
                  ),
                  Expanded(
                    child: getXAngleStringWidget(),
                    flex: 1,
                  ),
                  Expanded(
                    child: getRightHeightStringWidget(),
                    flex: 2,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16.0, 32.0, 16.0, 10.0), // left, top, right, bottom
                child: Center(
                  child: Transform.rotate(
                    angle: pi / 180 * (_yAngle - _yAngleCalibration) * -1,
                    child: Image.asset('images/camper_side.png', width: 250),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: getJockyHeightWidget(),
                    flex: 2,
                  ),
                  Expanded(
                    child: getYAngleStringWidget(),
                    flex: 1,
                  ),
                  const Expanded(
                    child: SizedBox(),
                    flex: 2,
                  )
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
              padding:
                  const EdgeInsets.all(16.0), // Adjust the padding as needed
              child: getConnectToDeviceWidget()),
        ),
      ],
    );
  }

  Widget getConnectToDeviceWidget() {
    return !deviceConnected
        ? FilledButton(
            onPressed: _navigateToBluetoothDevicesPage,
            child: const Text('Connect to Device'),
          )
        : SizedBox();
  }

  Widget getXAngleStringWidget() {
    var format = NumberFormat("##0.00", "en_US");

    String angleString;
    Color textColor = Colors.black54;

    double adjustedAngle = (_xAngle - _xAngleCalibration);
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

    double adjustedAngle = (_yAngle - _yAngleCalibration);
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

  Widget getLeftHeightStringWidget() {
    double height;

    if (horizontalReference != 'left') {
      height = double.parse(
          (tan((_xAngle - _xAngleCalibration) * pi / 180.0) * _caravanWidth)
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
      textColor = Colors.green;
    }

    return Text(heightString,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 36, color: textColor, fontWeight: FontWeight.bold));
  }

  Widget getRightHeightStringWidget() {
    double height;

    if (horizontalReference != 'right') {
      height = double.parse(
          (tan((_xAngle - _xAngleCalibration) * pi / 180.0) * _caravanWidth)
              .toStringAsFixed(3));
    } else {
      height = 0.0;
    }

    var format = NumberFormat("##0.00", "en_US");

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

    return Text(
      heightString,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 36, color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Widget getJockyHeightWidget() {
    double height = double.parse(
        (tan((_yAngle - _yAngleCalibration) * pi / 180.0) * _caravanLength)
            .toStringAsFixed(3));

    var format = NumberFormat("##0.000", "en_US");

    String heightString;
    Color textColor = Colors.red;

    if (height > 0) {
      heightString = '$downArrow ${format.format(height.abs())}';
    } else if (height < 0) {
      heightString = '$upArrow ${format.format(height.abs())}';
    } else {
      heightString = '0.000';
      textColor = Colors.green;
    }

    return Text(
      heightString,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: 36, color: textColor, fontWeight: FontWeight.bold),
    );
  }

  Widget getBatteryLevelWidget() {
    var format = NumberFormat("###", "en_US");

    String batteryLevelString;
    if (_batteryLevel != null) {
      batteryLevelString = "$batterySymbol ${format.format(_batteryLevel)}%";
    } else {
      batteryLevelString = "      ";
    }

    Color textColor = Colors.white;

    return Center(
        child: Text(
      batteryLevelString,
      textAlign: TextAlign.left,
      style: TextStyle(
          fontSize: 18, color: textColor, fontWeight: FontWeight.normal),
    ));
  }

  Future<void> handleClick(String value) async {
    switch (value) {
      case 'Calibrate':
        {
          await _showCalibrationDialog();
          _xAngleCalibration = _xAngle;
          _yAngleCalibration = _yAngle;
          _zAngleCalibration = _zAngle;
          _sharedPreferences.setDouble('xAngleCalibration', _xAngleCalibration);
          _sharedPreferences.setDouble('yAngleCalibration', _yAngleCalibration);
          _sharedPreferences.setDouble('zAngleCalibration', _zAngleCalibration);

          break;
        }
      case 'Set Caravan Dimensions':
        {
          await _showDimensionsDialog();
          break;
        }
      case 'Set Device Orientation':
        {
          await _showDeviceOrientationDialog();
          break;
        }
    }
  }

  Future<void> _showCalibrationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Calibrate Trailer Leveler'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('This will calibrate the sensor.'),
                Text('Make sure that the device is level and press OK.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDimensionsDialog() async {
    TextEditingController _caravanWidthController = TextEditingController();
    TextEditingController _caravanLengthController = TextEditingController();

    _caravanWidthController.text = _caravanWidth.toString();
    _caravanLengthController.text = _caravanLength.toString();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dimensions Trailer Leveler'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Caravan Width (m)'),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: _caravanWidthController,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter width in meters'),
                ),
                const Text('Caravan Length (m)'),
                TextField(
                  keyboardType: TextInputType.number,
                  controller: _caravanLengthController,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter Length in meters'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                try {
                  _caravanWidth = double.parse(_caravanWidthController.text);
                  _caravanLength = double.parse(_caravanLengthController.text);
                  _sharedPreferences.setDouble('caravanWidth', _caravanWidth);
                  _sharedPreferences.setDouble('caravanLength', _caravanLength);
                  print("Set Length $_caravanLength \t width: $_caravanWidth");
                } catch (e) {
                  return;
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeviceOrientationDialog() async {
    Color _colorContainer1 =
        appData.deviceOrientation == 1 ? Colors.blue : Colors.white;
    Color _colorContainer2 =
        appData.deviceOrientation == 2 ? Colors.blue : Colors.white;
    Color _colorContainer3 =
        appData.deviceOrientation == 3 ? Colors.blue : Colors.white;
    Color _colorContainer4 =
        appData.deviceOrientation == 4 ? Colors.blue : Colors.white;
    Color _colorContainer5 =
        appData.deviceOrientation == 5 ? Colors.blue : Colors.white;
    Color _colorContainer6 =
        appData.deviceOrientation == 6 ? Colors.blue : Colors.white;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.9,
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.lightBlue,
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
                  width: 400,
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
                              color: _colorContainer1,
                              child: Image.asset(
                                  'images/device-orientation-1.png',
                                  width: 100),
                            ),
                            onTap: () {
                              handleDeviceOrientationSelection(1);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Material(
                          child: InkWell(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: _colorContainer2,
                              child: Image.asset(
                                  'images/device-orientation-2.png',
                                  width: 100),
                            ),
                            onTap: () {
                              handleDeviceOrientationSelection(2);
                              _colorContainer1 = Colors.white;
                              _colorContainer2 = Colors.blue;
                              setState(() {});
                              Navigator.of(context).pop();
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
                              color: _colorContainer3,
                              child: Image.asset(
                                  'images/device-orientation-3.png',
                                  width: 100),
                            ),
                            onTap: () {
                              handleDeviceOrientationSelection(3);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Material(
                          child: InkWell(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: _colorContainer4,
                              child: Image.asset(
                                  'images/device-orientation-4.png',
                                  width: 100),
                            ),
                            onTap: () {
                              handleDeviceOrientationSelection(4);
                              Navigator.of(context).pop();
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
                              color: _colorContainer5,
                              child: Image.asset(
                                  'images/device-orientation-5.png',
                                  width: 100),
                            ),
                            onTap: () {
                              handleDeviceOrientationSelection(5);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Material(
                          child: InkWell(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color: _colorContainer6,
                              child: Image.asset(
                                  'images/device-orientation-6.png',
                                  width: 100),
                            ),
                            onTap: () {
                              handleDeviceOrientationSelection(6);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.lightBlue,
                  child: TextButton(
                    style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      textStyle:
                          MaterialStateProperty.all<TextStyle>(const TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1,
                        fontSize: 30,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      )),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Set Orientation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1,
                        fontSize: 26,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  width: 400,
                ),
              ],
            ));
      },
    );
  }

  void handleDeviceOrientationSelection(int selection) {
    switch (selection) {
      case 1:
        {
          print("Selection 1");
          appData.deviceOrientation = 1;
          break;
        }
      case 2:
        {
          print("Selection 2");
          appData.deviceOrientation = 2;
          break;
        }
      case 3:
        {
          print("Selection 3");
          appData.deviceOrientation = 3;
          break;
        }
      case 4:
        {
          print("Selection 4");
          appData.deviceOrientation = 4;
          break;
        }
      case 5:
        {
          print("Selection 5");
          appData.deviceOrientation = 5;
          break;
        }
      case 6:
        {
          print("Selection 6");
          appData.deviceOrientation = 6;
          break;
        }
    }
    _sharedPreferences.setInt('deviceOrientation', selection);
    Fluttertoast.showToast(
        msg: "Orientation Changed",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
