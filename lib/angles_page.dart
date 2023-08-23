import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:trailer_leveler_app/bluetooth_devices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:trailer_leveler_app/app_data.dart';
import 'package:trailer_leveler_app/dfu_update_page.dart';
import 'package:trailer_leveler_app/device_orientation_page.dart';

class AnglesPage extends StatefulWidget {
  const AnglesPage({Key? key}) : super(key: key);

  @override
  PageState createState() => PageState();
}

class PageState extends State<AnglesPage> with TickerProviderStateMixin {
  AudioPlayer? audioPlayer;
  Timer? loopTimer;
  bool isPlaying = false;

  double _xAngleCalibration = 0.0;
  double _yAngleCalibration = 0.0;
  double _zAngleCalibration = 0.0;
  double _xAngle = 0.0;
  double _yAngle = 0.0;
  double _zAngle = 0.0;
  double? _batteryLevel;

  double _caravanWidth = 0.0001;
  double _caravanLength = 0.0001;

  int minInterval = 2000; // Minimum interval in milliseconds
  int maxInterval = 5000; // Maximum interval in milliseconds

  String downArrow = "\u2b07";
  String upArrow = "\u2b06";
  String batterySymbol = "\u{1F50B}";

  String horizontalReference = 'right';

  bool deviceConnected = false;

  bool isSoundMuted = true;

  late Image camperRear;
  late Image camperSide;

  // save in the state for caching!
  late SharedPreferences _sharedPreferences;

  @override
  void initState() {
    audioPlayer = AudioPlayer();

    //audioPlayer?.setPlayerMode(PlayerMode.lowLatency);
    camperRear = Image.asset("images/camper_rear.png", width: 200);
    camperSide = Image.asset(
      "images/camper_side.png",
      width: 250,
    );
    super.initState();
  }

  /// Did Change Dependencies
  @override
  void didChangeDependencies() {
    precacheImage(camperRear.image, context);
    precacheImage(camperSide.image, context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    audioPlayer?.dispose();
    loopTimer?.cancel();
    super.dispose();
  }

  void loopAudio() async {
    loopTimer?.cancel();
    if (!deviceConnected || isSoundMuted) {
      await audioPlayer?.stop();
      setState(() => isPlaying = false);
      loopTimer?.cancel();
      return;
    }

    if (!isPlaying) {
      debugPrint("Playing");
      await audioPlayer?.stop();

      try {
        await audioPlayer?.play(
            AssetSource('sounds/beep1.wav')); // will immediately start playing
      } on TimeoutException catch (e) {
        debugPrint('TimeoutException: ${e.message}');
      }

      isPlaying = true;

      int interval =
          100 + ((_xAngle - _xAngleCalibration) * 100.0).toInt().abs();
      debugPrint("interval: $interval");

      loopTimer = Timer(Duration(milliseconds: interval), () async {
        debugPrint("Stopped");
        await audioPlayer?.stop();
        isPlaying = false;
        loopAudio(); // Start the loop again
      });
    }
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
                      systemOverlayStyle: const SystemUiOverlayStyle(
                        // Status bar color
                        statusBarColor: Colors.transparent,

                        // Status bar brightness (optional)
                        statusBarIconBrightness:
                            Brightness.dark, // For Android (dark icons)
                        statusBarBrightness:
                            Brightness.light, // For iOS (dark icons)
                      ),
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      elevation: 0,
                      leading: menuWidget(context),
                      actions: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 25),
                          child: GestureDetector(
                            onTap: () {
                              // Code to execute when the icon is pressed
                              // For example, you can play the audio here

                              setState(() {
                                isSoundMuted = !isSoundMuted;
                                loopAudio();
                              });
                            },
                            child: Icon(
                              isSoundMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        getBatteryLevelWidget(),
                      ]))

          // StreamBuilder
          ),
      body: getLevelIndicatorWidget(),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text(
                'Calibrate',
                maxLines: 1,
              ),
              selected: false,
              onTap: () async {
                Navigator.pop(context);

                await _showCalibrationDialog();

                _xAngleCalibration = _xAngle;
                _yAngleCalibration = _yAngle;
                _zAngleCalibration = _zAngle;
                _sharedPreferences.setDouble(
                    'xAngleCalibration', _xAngleCalibration);
                _sharedPreferences.setDouble(
                    'yAngleCalibration', _yAngleCalibration);
                _sharedPreferences.setDouble(
                    'zAngleCalibration', _zAngleCalibration);
                // Then close the drawer
              },
            ),
            ListTile(
              title: const Text(
                'Set Caravan Dimensions',
                maxLines: 1,
              ),
              selected: false,
              onTap: () async {
                // Then close the drawer
                Navigator.pop(context);
                await _showDimensionsDialog();
              },
            ),
            ListTile(
              title: const Text(
                'Set Device Orientation',
                maxLines: 1,
              ),
              selected: false,
              onTap: () async {
                // Then close the drawer
                Navigator.pop(context);
                _showDeviceOrientationDialog();
              },
            ),
            ListTile(
              title: const Text(
                'Settings',
                maxLines: 1,
              ),
              selected: false,
              onTap: () async {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text(
                'Update Device Firmware',
                maxLines: 1,
              ),
              selected: false,
              onTap: () async {
                Navigator.pop(context);
                _showDFUDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget bluetoothDeviceWidget() {
    return IconButton(
        icon: const Icon(Icons.add_link),
        onPressed: _navigateToBluetoothDevicesPage);
  }

  Widget menuWidget(BuildContext thecontext) {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.black54), // Menu icon
      onPressed: () async {
        Scaffold.of(thecontext).openDrawer(); // Open the drawer
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
            loopAudio();
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
                  padding: const EdgeInsets.fromLTRB(
                      16.0, 32.0, 16.0, 10.0), // left, top, right, bottom
                  child: Center(
                    child: Transform.rotate(
                      angle: pi / 180.0 * (_xAngle - _xAngleCalibration),
                      child: camperRear,
                    ),
                  )),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: getLeftHeightStringWidget(),
                  ),
                  Expanded(
                    flex: 1,
                    child: getXAngleStringWidget(),
                  ),
                  Expanded(
                    flex: 2,
                    child: getRightHeightStringWidget(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16.0, 32.0, 16.0, 10.0), // left, top, right, bottom
                child: Center(
                  child: Transform.rotate(
                    angle: pi / 180 * (_yAngle - _yAngleCalibration) * -1,
                    child: camperSide,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: getJockyHeightWidget(),
                  ),
                  Expanded(
                    flex: 1,
                    child: getYAngleStringWidget(),
                  ),
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
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
        : const SizedBox();
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

    return GestureDetector(
      onTap: () {
        setState(() {
          horizontalReference = 'right';
        });
      },
      child: Text(
        heightString,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 36, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
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
      child: Text(
        heightString,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 36, color: textColor, fontWeight: FontWeight.bold),
      ),
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

    Color textColor = Colors.black54;

    return Padding(
        padding: const EdgeInsets.only(right: 25.0, top: 16),
        child: Text(
          batteryLevelString,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 18, color: textColor, fontWeight: FontWeight.normal),
        ));
  }

  Future<void> _showCalibrationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Calibrate Trailer Leveler'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
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
                  debugPrint(
                      "Set Length $_caravanLength \t width: $_caravanWidth");
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
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return const FractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.9,
                child: DeviceOrientationPage(),
              );
            },
          );
        });
  }

  Future<void> _showDFUDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return const FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.4,
            child: DFUUpdatePage(),
          );
        });
      },
    );
  }
}
