import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:collection/collection.dart'; // You have to add this manually, for some reason it cannot be added automatically

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
// ignore: constant_identifier_names
const String ACCELEROMETER_ORIENTATION_CHARACTERISTIC_UUID =
    "76491404-7DD9-11ED-A1EB-0242AC120002";
// ignore: constant_identifier_names
const String BATTERY_LEVEL_CHARACTERISTIC_UUID =
    "00002A19-0000-1000-8000-00805F9B34FB";

class BluetoothBloc {
  StreamSubscription<List<ScanResult>>? scanResultsStreamSubscription;
  StreamSubscription<List<int>>? accelerationCharacteristicStreamSubscription;

  BluetoothService? accelerometerService;
  BluetoothService? batteryLevelService;
  BluetoothService? deviceInformationService;

  BluetoothCharacteristic? anglesCharacteristic;
  BluetoothCharacteristic? orientationCharacteristic;
  BluetoothCharacteristic? batteryLevelCharacteristic;

  // Private static instance of the class
  static final BluetoothBloc _singleton = BluetoothBloc._internal();

  final _anglesStreamController = StreamController<Map<String, double>>();
  final _batteryLevelStreamController = StreamController<Map<String, int>>();
  final _orientationStreamController = StreamController<Map<String, int>>();
  final _connectionStateStreamController = StreamController<Map<String, int>>();

  // Declare the subscription variable
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;

  Stream<Map<String, double>> get anglesStream =>
      _anglesStreamController.stream;
  Stream<Map<String, int>> get batteryLevelStream =>
      _batteryLevelStreamController.stream;
  Stream<Map<String, int>> get orientationStream =>
      _orientationStreamController.stream;
  Stream<Map<String, int>> get connectionStateStream =>
      _connectionStateStreamController.stream;

  factory BluetoothBloc() {
    return _singleton;
  }

  // Private constructor
  BluetoothBloc._internal() {
    // Initialization code
  }

  // Override the call method to return the instance
  static BluetoothBloc get instance => _singleton;

  Future<void> setOrientation(int orientation) async {
    await orientationCharacteristic?.write([orientation]);
  }

  Future<int> getOrientation() async {
    List<int>? orientation = await orientationCharacteristic?.read();

    return orientation![0];
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    accelerationCharacteristicStreamSubscription?.cancel();

    bool connected = true;
    await device
        .connect(autoConnect: false)
        .timeout(const Duration(seconds: 5))
        .onError((error, stackTrace) {
      debugPrint(stackTrace.toString());

      debugPrint(error.toString());
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

    _anglesStreamController.sink.add(obj);

    List<BluetoothService> services = await device.discoverServices();

    instance.accelerometerService = services.firstWhereOrNull(
        (service) => service.uuid == Guid(ACCELEROMETER_SERVICE_UUID));

    if (instance.accelerometerService == null) {
      debugPrint("Accelerometer Service not found");
    } else {
      debugPrint("Accelerometer Service found");
    }

    if (instance.accelerometerService == null) {
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

    anglesCharacteristic = instance.accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_ANGLES_CHARACTERISTIC_UUID));

    orientationCharacteristic = instance.accelerometerService?.characteristics
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
      await orientationCharacteristic?.read().then((value) {
        debugPrint("orientation value received");
        if (value.isNotEmpty) {
          var obj = {
            "orientation": value[0],
          };

          _orientationStreamController.sink.add(obj);
        }
      });
    }

    await anglesCharacteristic?.setNotifyValue(true);

    accelerationCharacteristicStreamSubscription =
        anglesCharacteristic?.lastValueStream.listen((value) async {
      if (value.length == 12) {
        // The bytes are received in 32 bit little endian format so convert them into a numbers
        ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));

        double accX = byteData.getFloat32(0, Endian.little);
        double accY = byteData.getFloat32(4, Endian.little);
        double accZ = byteData.getFloat32(8, Endian.little);

        var obj = {"xAngle": accX, "yAngle": accY, "zAngle": accZ};

        _anglesStreamController.sink.add(obj);
      }
    }, cancelOnError: true);

    // Start listening to the stream
    connectionStateSubscription =
        device.connectionState.listen((connectionState) async {
      switch (connectionState) {
        case BluetoothConnectionState.disconnected:
          var obj = {
            "connected": 1,
          };

          _connectionStateStreamController.sink.add(obj);

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

    BluetoothCharacteristic? batteryLevelCharacteristic =
        batterLevelService?.characteristics.firstWhereOrNull((characteristic) =>
            characteristic.uuid == Guid(BATTERY_LEVEL_CHARACTERISTIC_UUID));

    if (batteryLevelCharacteristic != null) {
      await batteryLevelCharacteristic.setNotifyValue(true);

      await batteryLevelCharacteristic.read();
      batteryLevelCharacteristic.lastValueStream.listen((value) async {
        var obj = {
          "batteryLevel": value[0],
        };
        _batteryLevelStreamController.sink.add(obj);
      });
    } else {
      debugPrint("Characteristic not found!!!");
    }

    orientationCharacteristic = orientationCharacteristic;
  }

  void dispose() {
    _anglesStreamController.close();
    _batteryLevelStreamController.close();
    _orientationStreamController.close();
    connectionStateSubscription?.cancel();
  }
}
