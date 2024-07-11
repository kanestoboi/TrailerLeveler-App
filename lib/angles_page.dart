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
import 'package:trailer_leveler_app/leveling_mode_selector.dart';
import 'package:trailer_leveler_app/vehicle_angles.dart';

import 'package:trailer_leveler_app/dfu_update_page.dart';
import 'package:trailer_leveler_app/device_orientation_page.dart';
import 'package:trailer_leveler_app/settings_page.dart';

import 'package:trailer_leveler_app/CircularBorder.dart';
import 'package:trailer_leveler_app/FileStorage.dart';

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

  // save in the state for caching!
  late SharedPreferences _sharedPreferences;

  LevelingMode currentLevelingMode = LevelingMode.LEVEL_TO_LEVEL;

  @override
  void initState() {
    audioPlayer = AudioPlayer();

    listenToBluetoothBlocStreams();
    super.initState();

    // setup the shared prefrences and then get the length and width stored
    setupSharedPreferences().then((value) {
      if (BluetoothBloc.instance.trailerLevelerDevice != null) {
        setState(() {});

        BluetoothBloc.instance
            .connectToDevice(BluetoothBloc.instance.trailerLevelerDevice);
      }
    });
  }

  /// Did Change Dependencies
  @override
  void didChangeDependencies() {
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

    String? bluetoothDeviceMACSharedPreferences =
        _sharedPreferences.getString('bluetoothDeviceMAC');

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
              Expanded(
                child: SingleChildScrollView(
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
                        deviceNameStream:
                            BluetoothBloc.instance.deviceNameStream,
                        productID: BluetoothBloc.instance
                                .getBluetoothDeviceMACAddress() ??
                            "",
                      ),
                      VehicleAngle(
                        camperSide: const AssetImage(
                          "images/caravan_side.png",
                        ),
                        camperRear: AssetImage("images/caravan_rear.png"),
                        xAngleStream: BluetoothBloc.instance.xAngleStream,
                        yAngleStream: BluetoothBloc.instance.yAngleStream,
                        lengthAxisAdjustmentAngleStream:
                            BluetoothBloc.instance.lengthAxisAdjustmentStream,
                        widthAxisAdjustmentAngleStream:
                            BluetoothBloc.instance.widthAxisAdjustmentStream,
                      ),
                    ],
                  ),
                ),
              ),
              LevelingModeSelector(
                levelingModeStream: BluetoothBloc.instance.levelingModeStream,
                deviceConnectionStream:
                    BluetoothBloc.instance.connectionStateStream,
                setLevelingModeCallback: (int mode) async {
                  BluetoothBloc.instance.setLevelingMode(mode);
                },
                saveHitchHeightAngleCallback: () async {
                  await BluetoothBloc.instance.setCalibration(2);
                  print("Saving hitch height command sent");
                },
                connectButtonPressedCallback: _navigateToBluetoothDevicesPage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> saveHitchAngle() async {
    // sending 2 will set the device to save its hitch angle
    await BluetoothBloc.instance.setCalibration(2);
    //_savedHitchAngle = await BluetoothBloc.instance.getSavedHitchAngle();
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

  Future<void> _showDimensionsDialog() async {
    TextEditingController _caravanWidthController = TextEditingController();
    TextEditingController _caravanLengthController = TextEditingController();

    if (deviceConnected == false) {
      Fluttertoast.showToast(
        msg: 'Vehicle Dimensions can\'t be set without a device connected',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      return;
    }

    _caravanWidthController.text =
        (await BluetoothBloc.instance.getVehicleWidth()).toString();
    _caravanLengthController.text =
        (await BluetoothBloc.instance.getVehicleLength()).toString();

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
              onPressed: () async {
                await BluetoothBloc.instance.setVehicleLength(
                    double.parse(_caravanLengthController.text));
                await BluetoothBloc.instance.setVehicleWidth(
                    double.parse(_caravanWidthController.text));

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
      if (connectionState == "connected") {
        deviceConnected = true;
        double vehicleWidth = await BluetoothBloc.instance.getVehicleWidth();
        double vehicleLength = await BluetoothBloc.instance.getVehicleLength();

        if (vehicleLength == 1.0 && vehicleWidth == 1.0) {
          _showDimensionsDialog();
        }

        loopAudio();
      } else if (connectionState == 'disconnected') {
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
