import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:collection/collection.dart';
import 'package:trailer_leveler_app/app_data.dart'; // You have to add this manually, for some reason it cannot be added automatically

const int MPU6050_MAX_VALUE = 32767;
const int MPU6050_MIN_VALUE = -32768;
const int ADXL355_MAX_VALUE = 262143;
const int ADXL355_MIN_VALUE = -262144;

const int ADXL355_DATA_LENGTH = 12;
const int MPU6050_DATA_LENGTH = 6;

// ignore: non_constant_identifier_names
const double _RAD_TO_DEG = 57.296;
// ignore: non_constant_identifier_names
const double _PI = 3.14;

// ignore: constant_identifier_names
const String ACCELEROMETER_SERVICE_UUID =
    "76491400-7DD9-11ED-A1EB-0242AC120002";
// ignore: constant_identifier_names
const String BATTERY_LEVEL_SERVICE_UUID =
    "0000180f-0000-1000-8000-00805f9b34fb";
// ignore: constant_identifier_names
const String ADXL355_ACCELEROMETER_CHARACTERISTIC_UUID =
    "76491401-7DD9-11ED-A1EB-0242AC120002";
// ignore: constant_identifier_names
const String MPU6050_ACCELEROMETER_CHARACTERISTIC_UUID =
    "76491402-7DD9-11ED-A1EB-0242AC120002";
// ignore: constant_identifier_names
const String ACCELEROMETER_ANGLES_CHARACTERISTIC_UUID =
    "76491403-7DD9-11ED-A1EB-0242AC120002";
const String ACCELEROMETER_ORIENTATION_CHARACTERISTIC_UUID =
    "76491404-7DD9-11ED-A1EB-0242AC120002";

// ignore: constant_identifier_names
const String BATTERY_LEVEL_CHARACTERISTIC_UUID =
    "00002A19-0000-1000-8000-00805F9B34FB";
// ignore: constant_identifier_names
const String UART_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
// ignore: constant_identifier_names
const String UART_CHARACTERISTIC_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

class BluetoothDevices extends StatefulWidget {
  const BluetoothDevices({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _BluetoothDevicesState createState() => _BluetoothDevicesState();

  Widget build(BuildContext context) {
    return const BluetoothDevices(
      title: "devices",
    );
  }
}

class _BluetoothDevicesState extends State<BluetoothDevices> {
  final _devices = <BluetoothDevice>[];

  StreamSubscription<List<ScanResult>>? scanResultsStreamSubscription;
  StreamSubscription<List<int>>? accelerationCharacteristicStreamSubscription;

  @override
  dispose() async {
    FlutterBluePlus.stopScan();

    super.dispose();
  }

  Widget _buildFindDevicesList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _devices.length,
        itemBuilder: (context, item) => _buildDeviceRow(_devices[item]));
  }

  Widget _buildDeviceRow(BluetoothDevice device) {
    return ListTile(
      title: Text(device.localName),
      trailing: const Text("Connect"),
      onTap: () => connectToDevice(device),
    );
  }

  @override
  void initState() {
    super.initState();
    refreshPressed();
  }

  @override
  Widget build(BuildContext context) {
    return _buildFindDevicesPage(context);
  }

  Scaffold _buildFindDevicesPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Discover Devices'), actions: const <Widget>[]),
      body: _buildFindDevicesList(),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              onPressed: stopScanPressed,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
                onPressed: refreshPressed, child: const Icon(Icons.refresh));
          }
        },
      ),
    );
  }

  void stopScanPressed() {
    FlutterBluePlus.stopScan();
  }

  void refreshPressed() {
    scanResultsStreamSubscription?.cancel();
    // Clear the devices in the discovered list

    // clear the ListView
    setState(() => {});

    // Listen to scan results
    scanResultsStreamSubscription =
        FlutterBluePlus.scanResults.listen((results) {
      // Add unique scan results to _devices list
      for (ScanResult r in results) {
        if (r.device.localName != '' && !_devices.contains(r.device)) {
          debugPrint(
              '${r.device.localName} found! rssi: ${r.rssi}, ID: ${r.device.remoteId}');
          _devices.add(r.device);
          setState(() => {});
        }
      }
    });

    debugPrint("starting scan");
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
    );
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    accelerationCharacteristicStreamSubscription?.cancel();
    final _streamController = StreamController<Map<String, double>>();

    Stream<Map<String, double>> stream = _streamController.stream;

    bool connected = true;
    await device
        .connect(autoConnect: false)
        .timeout(const Duration(seconds: 5))
        .onError((error, stackTrace) {
      debugPrint("${stackTrace.toString()}");

      debugPrint("${error.toString()}");
      connected = false;
      Fluttertoast.showToast(
          msg: "Couldn't Connect to Device",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    });

    if (!connected) {
      debugPrint("Not Connected");
      return;
    }

    var obj = {
      "connected": 1.0,
    };

    _streamController.sink.add(obj);

    List<BluetoothService> services = await device.discoverServices();

    BluetoothCharacteristic? angleDataCharacteristic;
    BluetoothCharacteristic? orientationCharacteristic;

    BluetoothService? accelerometerService = services.firstWhereOrNull(
        (service) => service.uuid == Guid(ACCELEROMETER_SERVICE_UUID));

    if (accelerometerService == null) {
      debugPrint("Accelerometer Service not found");
    } else {
      debugPrint("Accelerometer Service found");
    }

    if (accelerometerService == null) {
      Fluttertoast.showToast(
          msg: "Not a Trailer Leveler",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black38,
          textColor: Colors.white,
          fontSize: 16.0);

      device.disconnect();

      return;
    }

    angleDataCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_ANGLES_CHARACTERISTIC_UUID));

    orientationCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_ORIENTATION_CHARACTERISTIC_UUID));

    if (orientationCharacteristic == null) {
      debugPrint("Orientation not found");
      Fluttertoast.showToast(
          msg: "orientation char not found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black38,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      debugPrint("Orientation found");
      await orientationCharacteristic.read().then((value) {
        debugPrint("orientation value received");
        if (value.isNotEmpty) {
          debugPrint("Orientation not empty");

          Uint8List uint8List = Uint8List.fromList(value);
          double orientation =
              uint8List[0].toDouble(); // Convert Uint8 to double

          var obj = {
            "orientation": orientation,
          };

          _streamController.sink.add(obj);
        }
      });
    }

    await angleDataCharacteristic?.setNotifyValue(true);

    accelerationCharacteristicStreamSubscription =
        angleDataCharacteristic?.lastValueStream.listen((value) async {
      if (value.length == ADXL355_DATA_LENGTH) {
        // The bytes are received in 32 bit little endian format so convert them into a numbers
        ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));

        double accX = byteData.getFloat32(0, Endian.little);
        double accY = byteData.getFloat32(4, Endian.little);
        double accZ = byteData.getFloat32(8, Endian.little);

        var obj = {"xAngle": accX, "yAngle": accY, "zAngle": accZ};

        _streamController.sink.add(obj);
      }
    }, cancelOnError: true);

    // Declare the subscription variable
    StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;

    // Start listening to the stream
    connectionStateSubscription =
        device.connectionState.listen((connectionState) async {
      switch (connectionState) {
        case BluetoothConnectionState.disconnected:
          var obj = {
            "connected": 0.0,
          };

          _streamController.sink.add(obj);

          debugPrint("DISCONNECTED!!!!!");
          // Cancel the subscription to stop listening
          connectionStateSubscription?.cancel();
          break;
        default:
          break;
      }
    });

    debugPrint("Looking for battery service");
    BluetoothService? batterLevelService = services.firstWhereOrNull(
        (service) => service.uuid == Guid(BATTERY_LEVEL_SERVICE_UUID));

    if (batterLevelService == null) {
      debugPrint("NO Service Found");
    } else {
      debugPrint("Battery Service found");
    }

    var characteristics = batterLevelService?.characteristics;
    for (BluetoothCharacteristic c in characteristics!) {
      debugPrint(c.uuid.toString());
    }

    BluetoothCharacteristic? batterLevelCharacteristic =
        batterLevelService?.characteristics.firstWhereOrNull((characteristic) =>
            characteristic.uuid == Guid(BATTERY_LEVEL_CHARACTERISTIC_UUID));

    if (batterLevelCharacteristic != null) {
      await batterLevelCharacteristic.setNotifyValue(true);

      await batterLevelCharacteristic.read();
      batterLevelCharacteristic.lastValueStream.listen((value) async {
        double bat = value[0] * 1.0;
        var obj = {
          "batteryLevel": bat,
        };
        _streamController.sink.add(obj);
      });
    } else {
      debugPrint("Characteristic not found!!!");
    }

    appData.orientaionCharacteristic = orientationCharacteristic;
    Navigator.pop(
      context,
      stream,
    );
  }
}
