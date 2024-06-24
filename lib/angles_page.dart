import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:trailer_leveler_app/CircularBorder.dart';
import 'package:trailer_leveler_app/bluetooth_bloc.dart';
import 'package:trailer_leveler_app/bluetooth_devices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:trailer_leveler_app/device_status.dart';
import 'package:trailer_leveler_app/vehicle_angles.dart';

import 'package:trailer_leveler_app/dfu_update_page.dart';
import 'package:trailer_leveler_app/device_orientation_page.dart';
import 'package:trailer_leveler_app/settings_page.dart';

import 'package:trailer_leveler_app/CircularBorder.dart';
import 'package:trailer_leveler_app/FileStorage.dart';

double savedheight = 0;

enum LevelingMode {
  LEVEL_TO_LEVEL,
  LEVEL_TO_SAVED_HITCH_HEIGHT,
}

enum CONNECT_BUTTON_STATE {
  CONNECTING_TO_DEVICE,
  CONNECTED_TO_DEVICE,
  DISCONNECTED_FROM_DEVICE
}

class AnglesPage extends StatefulWidget {
  const AnglesPage({Key? key}) : super(key: key);

  @override
  PageState createState() => PageState();
}

class PageState extends State<AnglesPage> with TickerProviderStateMixin {
  AudioPlayer? audioPlayer;
  Timer? loopTimer;
  bool isPlaying = false;

  double _xAngle = 0.0;
  double _yAngle = 0.0;
  double _zAngle = 0.0;

  List<AngleDataPoint> xAngleReadings = [];
  List<AngleDataPoint> yAngleReadings = [];
  List<AngleDataPoint> zAngleReadings = [];
  List<TemperatureDataPoint> temperatureReadings = [];

  double _caravanWidth = 0.0001;
  double _caravanLength = 0.0001;

  int minInterval = 2000; // Minimum interval in milliseconds
  int maxInterval = 5000; // Maximum interval in milliseconds

  String downArrow = "\u2b07";
  String upArrow = "\u2b06";
  String batterySymbol = "\u{1F50B}";

  String horizontalReference = 'right';

  bool deviceConnected = false;
  int? batteryLevel;
  double? temperature;

  bool isSoundMuted = true;

  bool recordData = false;

  late Image camperRear;
  late Image camperSide;

  CONNECT_BUTTON_STATE connectButtonState =
      CONNECT_BUTTON_STATE.DISCONNECTED_FROM_DEVICE;

  // save in the state for caching!
  late SharedPreferences _sharedPreferences;

  LevelingMode currentLevelingMode = LevelingMode.LEVEL_TO_LEVEL;

  @override
  void initState() {
    audioPlayer = AudioPlayer();

    listenToBluetoothBlocStreams();

    camperRear = Image.asset("images/caravan_rear.png", width: 125);
    camperSide = Image.asset(
      "images/caravan_side.png",
      width: 350,
    );
    super.initState();

    // setup the shared prefrences and then get the length and width stored
    setupSharedPreferences().then((value) {
      if (_caravanWidth == 0.0001 && _caravanLength == 0.0001) {
        _caravanWidth = 1.0;
        _caravanLength = 1.0;
        _showDimensionsDialog();
      }

      if (BluetoothBloc.instance.trailerLevelerDevice != null) {
        setState(() {
          connectButtonState = CONNECT_BUTTON_STATE.CONNECTING_TO_DEVICE;
        });

        BluetoothBloc.instance
            .connectToDevice(BluetoothBloc.instance.trailerLevelerDevice);
      }
    });
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

      int interval = 100 + ((_xAngle) * 100.0).toInt().abs();
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

    double? caravanWidthSharedPreferences =
        _sharedPreferences.getDouble('caravanWidth');

    double? caravanLengthSharedPreferences =
        _sharedPreferences.getDouble('caravanLength');

    String? bluetoothDeviceMACSharedPreferences =
        _sharedPreferences.getString('bluetoothDeviceMAC');

    if (caravanWidthSharedPreferences != null) {
      _caravanWidth = caravanWidthSharedPreferences;
    }

    if (caravanLengthSharedPreferences != null) {
      _caravanLength = caravanLengthSharedPreferences;
    }

    if (bluetoothDeviceMACSharedPreferences != null) {
      BluetoothBloc.instance
          .setBluetoothDeviceMACAddress(bluetoothDeviceMACSharedPreferences);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Perform an action after the build is completed
    SchedulerBinding.instance.addPostFrameCallback((durarion) {});

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
              child: Text(''),
            ),
            ListTile(
              title: const Row(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: Icon(Icons.my_location, color: Colors.black54),
                  ),
                  // Icon you want to add
                  SizedBox(
                      width: 8), // Add some spacing between the icon and text
                  Text(
                    'Calibrate',
                    maxLines: 1,
                  ),
                ],
              ),
              selected: false,
              onTap: () async {
                Navigator.pop(context);

                await _showCalibrationDialog();

                // Then close the drawer
              },
            ),
            ListTile(
              title: Row(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black54, // Replace with the color you want
                        BlendMode.srcIn,
                      ),
                      child: SvgPicture.asset(
                        'assets/ruler-solid.svg', // Replace with your SVG image path
                        width: 18, // Adjust the width as needed
                        height: 18, // Adjust the height as needed
                      ),
                    ),
                  ), // Icon you want to add // Icon you want to add
                  const SizedBox(
                      width: 8), // Add some spacing between the icon and text
                  const Text(
                    'Set Caravan Dimensions',
                    maxLines: 1,
                  ),
                ],
              ),
              selected: false,
              onTap: () async {
                // Then close the drawer
                Navigator.pop(context);
                await _showDimensionsDialog();
              },
            ),
            ListTile(
              title: Row(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black54, // Replace with the color you want
                        BlendMode.srcIn,
                      ),
                      child: SvgPicture.asset(
                        'assets/arrows-spin-solid.svg', // Replace with your SVG image path
                        width: 20, // Adjust the width as needed
                        height: 20, // Adjust the height as needed
                      ),
                    ),
                  ), // Icon you want to add
                  const SizedBox(
                      width: 8), // Add some spacing between the icon and text
                  const Text(
                    'Set Device Orientation',
                    maxLines: 1,
                  ),
                ],
              ),
              selected: false,
              onTap: () async {
                // Then close the drawer
                Navigator.pop(context);
                _showDeviceOrientationDialog();
              },
            ),
            ListTile(
              title: const Row(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: Icon(Icons.settings, color: Colors.black54),
                  ), // Icon you want to add
                  SizedBox(
                      width: 8), // Add some spacing between the icon and text
                  Text(
                    'Settings',
                    maxLines: 1,
                  ),
                ],
              ),
              selected: false,
              onTap: () async {
                Navigator.pop(context);

                _showSettingsDialog();
              },
            ),
            ListTile(
              title: const Row(
                children: [
                  SizedBox(
                    width: 25,
                    height: 25,
                    child: Icon(Icons.keyboard_double_arrow_up_outlined,
                        color: Colors.black54),
                  ), // Icon you want to add
                  SizedBox(
                      width: 8), // Add some spacing between the icon and text
                  Text(
                    'Update Device Firmware',
                    maxLines: 1,
                  ),
                ],
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
    await Navigator.of(context).push(bluetoothDevicesPageRoute);

    if (BluetoothBloc.instance.trailerLevelerDevice != null) {
      _sharedPreferences.setString("bluetoothDeviceMAC",
          BluetoothBloc.instance.trailerLevelerDevice!.remoteId.toString());
    }
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
              DeviceStatus(
                camperSide: const AssetImage(
                  "images/caravan_side.png",
                ),
                connectionStateStream:
                    BluetoothBloc.instance.connectionStateStream,
                batteryChargePercentageStream:
                    BluetoothBloc.instance.batteryLevelStream,
                productID:
                    BluetoothBloc.instance.getBluetoothDeviceMACAddress() ?? "",
              ),
              VehicleAngle(
                camperSide: const AssetImage(
                  "images/caravan_side.png",
                ),
                camperRear: AssetImage("images/caravan_rear.png"),
                caravanWidth: _caravanWidth,
                caravanLength: _caravanLength,
                xAngleStream: BluetoothBloc.instance.xAngleStream,
                yAngleStream: BluetoothBloc.instance.yAngleStream,
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
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
              padding:
                  const EdgeInsets.all(16.0), // Adjust the padding as needed
              child: toggleLevelingModeButtonWidget()),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Padding(
              padding:
                  const EdgeInsets.all(16.0), // Adjust the padding as needed
              child: getSaveHitchHeightWidget()),
        )
      ],
    );
  }

  List<bool> isSelected = [
    true,
    false
  ]; // Initialize based on currentLevelingMode value

  List<Widget> _buildToggleButtons() {
    return [
      ElevatedButton(
        onPressed: () {
          setState(() {
            isSelected = [true, false];
            toggleLevelingMode();
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            isSelected[0] ? Colors.green : Colors.grey,
          ),
        ),
        child: const Text('Adjest to Level'),
      ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            isSelected = [false, true];
          });
          toggleLevelingMode();
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            isSelected[1] ? Colors.green : Colors.grey,
          ),
        ),
        child: const Text('Adjust to Saved Height'),
      ),
    ];
  }

  Widget toggleLevelingModeButtonWidget() {
    return deviceConnected
        ? Center(
            child: ToggleButtons(
              color: Colors.transparent,
              selectedColor: Colors.transparent,
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              selectedBorderColor: Colors.transparent,
              isSelected: isSelected,
              onPressed: (int index) {
                setState(() {
                  isSelected =
                      List.generate(isSelected.length, (i) => i == index);
                  toggleLevelingMode();
                });
              },
              children: _buildToggleButtons(),
            ),
          )
        : const SizedBox();
  }

  Widget getSaveHitchHeightWidget() {
    return deviceConnected
        ? FilledButton(
            onPressed: () async {
              await _showSaveHitchHeightConfirmationDialog();
            },
            child: const Text('Save Hitch Height'),
          )
        : const SizedBox();
  }

  Future<void> toggleLevelingMode() async {
    setState(() {
      switch (currentLevelingMode) {
        case LevelingMode.LEVEL_TO_SAVED_HITCH_HEIGHT:
          currentLevelingMode = LevelingMode.LEVEL_TO_LEVEL;
          break;
        default:
          currentLevelingMode = LevelingMode.LEVEL_TO_SAVED_HITCH_HEIGHT;
      }
    });

    switch (currentLevelingMode) {
      case LevelingMode.LEVEL_TO_SAVED_HITCH_HEIGHT:
        //_savedHitchAngle = await BluetoothBloc.instance.getSavedHitchAngle();
        break;
      default:
        {}
    }
  }

  Future<void> saveHitchAngle() async {
    // sending 2 will set the device to save its hitch angle
    await BluetoothBloc.instance.setCalibration(2);
    //_savedHitchAngle = await BluetoothBloc.instance.getSavedHitchAngle();
  }

  Widget getConnectToDeviceWidget() {
    switch (connectButtonState) {
      case CONNECT_BUTTON_STATE.CONNECTED_TO_DEVICE:
        {
          return const SizedBox();
        }
      case CONNECT_BUTTON_STATE.DISCONNECTED_FROM_DEVICE:
        {
          return FilledButton(
            onPressed: _navigateToBluetoothDevicesPage,
            child: const Text('Connect to Device'),
          );
        }

      case CONNECT_BUTTON_STATE.CONNECTING_TO_DEVICE:
        {
          return FilledButton(
            onPressed: () {},
            child: const Text('Connecting'),
          );
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
                if (deviceConnected) {
                  BluetoothBloc.instance.setCalibration(1);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSaveHitchHeightConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orangeAccent,
                size: 50,
              ), // Warning icon
              SizedBox(width: 8), // Add some spacing between the icon and text
              Expanded(
                child: Text(
                  'This action will overwrite any previous height saved',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(),
          actions: <Widget>[
            TextButton(
              child: const Text('Overwrite previous height'),
              onPressed: () async {
                await saveHitchAngle();
                Fluttertoast.showToast(
                  msg: 'Hitch height saved',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.grey,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
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
                const Text('Caravan Track Width (m)'),
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
    if (deviceConnected == false) {
      Fluttertoast.showToast(
        msg: 'Orientation can\'t be set without a device connected',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      return;
    }

    int currentOrientation = BluetoothBloc.instance.currentOrientation;

    int? selectedOrientation = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FractionallySizedBox(
              widthFactor: 0.8,
              heightFactor: 0.9,
              child:
                  DeviceOrientationPage(initialOrientation: currentOrientation),
            );
          },
        );
      },
    );

    setState(() {
      BluetoothBloc.instance.currentOrientation = selectedOrientation!;
    });

    await BluetoothBloc.instance.setOrientation(selectedOrientation!);
  }

  void recordDataCallback(bool ischecked) async {
    if (ischecked) {
      xAngleReadings = [];
      yAngleReadings = [];
      zAngleReadings = [];
      temperatureReadings = [];
      recordData = true;
    }
    if (!ischecked) {
      await FileStorage.writeAngleDataPoints(xAngleReadings, "xAngleReadings");
      await FileStorage.writeAngleDataPoints(yAngleReadings, "yAngleReadings");
      await FileStorage.writeAngleDataPoints(zAngleReadings, "zAngleReadings");
      await FileStorage.writeTemperatureDataPoints(
          temperatureReadings, "temperatureReadings");
    }
    print(ischecked);
    print("Record Data toggled");
  }

  Future<void> _showSettingsDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.6,
            child: SettingsPage(
                recordDataCallback: recordDataCallback,
                isRecordingSwitchValue: recordData),
          );
        });
      },
    );
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

  void listenToBluetoothBlocStreams() {
    BluetoothBloc.instance.connectionStateStream
        .listen((connectionState) async {
      if (connectionState == true) {
        connectButtonState = CONNECT_BUTTON_STATE.CONNECTED_TO_DEVICE;
        deviceConnected = true;
        loopAudio();
      } else {
        connectButtonState = CONNECT_BUTTON_STATE.DISCONNECTED_FROM_DEVICE;

        deviceConnected = false;

        if (BluetoothBloc.instance.currentDFUUploadState !=
            DFU_UPLOAD_STATE.DISCONNECTING) {
          _showDisconnectedDialog();
        }
      }

      setState(() {});
    });

    BluetoothBloc.instance.temperatureStream.listen((value) {
      temperature = value;
      if (recordData) {
        temperatureReadings.add(TemperatureDataPoint(
            DateTime.now().millisecondsSinceEpoch, temperature!));
      }

      print("Temperature $temperature");

      setState(() {});
    });
  }
}
