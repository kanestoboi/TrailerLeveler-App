import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:collection/collection.dart'; // You have to add this manually, for some reason it cannot be added automatically

// ignore: constant_identifier_names
const String DEVICE_INFORMATION_SERVICE_UUID =
    "0000180A-0000-1000-8000-00805F9B34FB";
// ignore: constant_identifier_names
const String ACCELEROMETER_SERVICE_UUID =
    "76491400-7DD9-11ED-A1EB-0242AC120002";
// ignore: constant_identifier_names
const String BATTERY_LEVEL_SERVICE_UUID =
    "0000180f-0000-1000-8000-00805f9b34fb";
// ignore: constant_identifier_names
const String DEVICE_FIRMWARE_CHARACTERISTIC_UUID =
    "00002A26-0000-1000-8000-00805F9B34FB";
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
const String ACCELEROMETER_CALIBRATION_CHARACTERISTIC_UUID =
    "76491405-7DD9-11ED-A1EB-0242AC120002";
const String ACCELEROMETER_SAVED_HITCH_ANGLE_CHARACTERISTIC_UUID =
    "76491406-7DD9-11ED-A1EB-0242AC120002";
// ignore: constant_identifier_names
const String BATTERY_LEVEL_CHARACTERISTIC_UUID =
    "00002A19-0000-1000-8000-00805F9B34FB";

const int MPU6050_MAX_VALUE = 32767;
const int MPU6050_MIN_VALUE = -32768;
const int ADXL355_MAX_VALUE = 262143;
const int ADXL355_MIN_VALUE = -262144;

// ignore: non_constant_identifier_names
const double _RAD_TO_DEG = 57.296;
// ignore: non_constant_identifier_names
const double _PI = 3.14;

int xoutput = 0;
int youtput = 0;
int zoutput = 0;

class AngleMeasurement {
  double xAngle;
  double yAngle;
  double zAngle;

  AngleMeasurement(this.xAngle, this.yAngle, this.zAngle);
}

enum ANGLE_CALCULATION_SOURCE {
  ANGLES_CALCULATED_ON_DEVICE,
  ANGLES_CALCULATED_ON_PHONE
}

class BluetoothBloc {
  // Private static instance of the class
  static final BluetoothBloc _singleton = BluetoothBloc._internal();

  StreamSubscription<List<ScanResult>>? scanResultsStreamSubscription;
  StreamSubscription<List<int>>?
      accelerometerDataCharacteristicStreamSubscription;
  StreamSubscription<List<int>>? anglesCharacteristicStreamSubscription;
  StreamSubscription<List<int>>? batteryLevelCharacteristicStreamSubscription;

  BluetoothService? deviceInformationService;
  BluetoothService? accelerometerService;
  BluetoothService? batteryLevelService;

  BluetoothCharacteristic? firmwareVersionCharacteristic;
  BluetoothCharacteristic? accelerometerDataCharacteristic;
  BluetoothCharacteristic? anglesCharacteristic;
  BluetoothCharacteristic? orientationCharacteristic;
  BluetoothCharacteristic? calibrationCharacteristic;
  BluetoothCharacteristic? savedHitchAngleCharacteristic;
  BluetoothCharacteristic? batteryLevelCharacteristic;

  int currentOrientation = 1;

  final _anglesStreamController = StreamController<Map<String, double>>();
  final _batteryLevelStreamController = StreamController<Map<String, int>>();
  final _connectionStateStreamController =
      StreamController<Map<String, bool>>();

  // Declare the subscription variable
  StreamSubscription<BluetoothConnectionState>?
      connectionStateStreamSubscription;

  Stream<Map<String, double>> get anglesStream =>
      _anglesStreamController.stream;
  Stream<Map<String, int>> get batteryLevelStream =>
      _batteryLevelStreamController.stream;
  Stream<Map<String, bool>> get connectionStateStream =>
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

  Future<void> setCalibration(int calibration) async {
    await calibrationCharacteristic?.write([calibration]);
  }

  Future<int> getCalibration() async {
    List<int>? calibration = await calibrationCharacteristic?.read();

    return calibration![0];
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    accelerometerDataCharacteristicStreamSubscription?.cancel();

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

    _connectionStateStreamController.sink.add({"connected": true});

    await findDeviceServices(device);

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

    await findDeviceCharacteristics();

    await setAnglesSource(ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_DEVICE);

    // Start listening to the connection state stream
    connectionStateStreamSubscription =
        getConnectionStateStreamSubscription(device);

    await batteryLevelCharacteristic?.setNotifyValue(true);
    await batteryLevelCharacteristic?.read();

    batteryLevelCharacteristicStreamSubscription =
        getBatteryLevelStreamSubscription();
  }

  void dispose() {
    _anglesStreamController.close();
    _batteryLevelStreamController.close();

    connectionStateStreamSubscription?.cancel();
    batteryLevelCharacteristicStreamSubscription?.cancel();
    accelerometerDataCharacteristicStreamSubscription?.cancel();
    anglesCharacteristicStreamSubscription?.cancel();
  }

  Future<void> findDeviceServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    deviceInformationService = services.firstWhereOrNull(
        (service) => service.uuid == Guid(DEVICE_INFORMATION_SERVICE_UUID));

    accelerometerService = services.firstWhereOrNull(
        (service) => service.uuid == Guid(ACCELEROMETER_SERVICE_UUID));

    batteryLevelService = services.firstWhereOrNull(
        (service) => service.uuid == Guid(BATTERY_LEVEL_SERVICE_UUID));

    if (accelerometerService == null) {
      debugPrint("Accelerometer Service NOT found");
    } else {
      debugPrint("Accelerometer Service found");
    }

    if (batteryLevelService == null) {
      debugPrint(" Battery Service NOT found");
    } else {
      debugPrint("Battery Service found");
    }

    if (deviceInformationService == null) {
      debugPrint("Device Information Service NOT found");
    } else {
      debugPrint("Device Information Service found");
    }
  }

  BluetoothCharacteristic? getAccelerometerDataCharacteristic(
      BluetoothService service) {
    BluetoothCharacteristic? characteristic;
    characteristic = accelerometerService?.characteristics.firstWhereOrNull(
        (characteristic) =>
            characteristic.uuid ==
            Guid(ADXL355_ACCELEROMETER_CHARACTERISTIC_UUID));

    characteristic ??= accelerometerService?.characteristics.firstWhereOrNull(
        (characteristic) =>
            characteristic.uuid ==
            Guid(MPU6050_ACCELEROMETER_CHARACTERISTIC_UUID));

    return characteristic;
  }

  StreamSubscription<List<int>>? getAccelerometerDataStreamSubscription() {
    var obj = {"xAngle": 0.0, "yAngle": 0.0, "zAngle": 0.0};

    return accelerometerDataCharacteristic?.lastValueStream.listen(
        (value) async {
      // The bytes are received in 32 bit little endian format so convert them into a numbers
      ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));
      if (value.length == 12) {
        int accX = byteData.getInt32(0, Endian.little);
        int accY = byteData.getInt32(4, Endian.little);
        int accZ = byteData.getInt32(8, Endian.little);

        xoutput = (0.9396 * xoutput + 0.0604 * accX).round();
        youtput = (0.9396 * youtput + 0.0604 * accY).round();
        zoutput = (0.9396 * zoutput + 0.0604 * accZ).round();

        double xAng =
            map(xoutput, ADXL355_MIN_VALUE, ADXL355_MAX_VALUE, -90, 90);
        double yAng =
            map(youtput, ADXL355_MIN_VALUE, ADXL355_MAX_VALUE, -90, 90);
        double zAng =
            map(youtput, ADXL355_MIN_VALUE, ADXL355_MAX_VALUE, -90, 90);

        AngleMeasurement angles = calculateAnglesFromDeviceOrientation(
            xAng, yAng, zAng, BluetoothBloc.instance.currentOrientation);

        obj = {
          "xAngle": angles.xAngle,
          "yAngle": angles.yAngle,
          "zAngle": angles.zAngle
        };
      } else if (value.length == 6) {
        int accX = byteData.getInt16(0, Endian.little);
        int accY = byteData.getInt16(2, Endian.little);
        int accZ = byteData.getInt16(4, Endian.little);

        xoutput = (0.9396 * xoutput + 0.0604 * accX).round();
        youtput = (0.9396 * youtput + 0.0604 * accY).round();
        zoutput = (0.9396 * zoutput + 0.0604 * accZ).round();

        double xAng =
            map(xoutput, MPU6050_MIN_VALUE, MPU6050_MAX_VALUE, -90, 90);
        double yAng =
            map(youtput, MPU6050_MIN_VALUE, MPU6050_MAX_VALUE, -90, 90);
        double zAng =
            map(zoutput, MPU6050_MIN_VALUE, MPU6050_MAX_VALUE, -90, 90);

        AngleMeasurement angles = calculateAnglesFromDeviceOrientation(
            xAng, yAng, zAng, BluetoothBloc.instance.currentOrientation);

        obj = {
          "xAngle": angles.xAngle,
          "yAngle": angles.yAngle,
          "zAngle": angles.zAngle
        };
      }

      _anglesStreamController.sink.add(obj);
    }, cancelOnError: true);
  }

  StreamSubscription<List<int>>? getAnglesStreamSubscription() {
    return anglesCharacteristic?.lastValueStream.listen((value) async {
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
  }

  Future<void> setAnglesSource(ANGLE_CALCULATION_SOURCE source) async {
    if (source == ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_DEVICE) {
      debugPrint("Setting Source to device");
      await accelerometerDataCharacteristic?.setNotifyValue(false);
      accelerometerDataCharacteristicStreamSubscription?.cancel();

      await anglesCharacteristic?.setNotifyValue(true);
      anglesCharacteristicStreamSubscription = getAnglesStreamSubscription();
    } else if (source == ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_PHONE) {
      debugPrint("Setting Source to phone");

      await anglesCharacteristic?.setNotifyValue(false);
      anglesCharacteristicStreamSubscription?.cancel();

      await accelerometerDataCharacteristic?.setNotifyValue(true);
      anglesCharacteristicStreamSubscription =
          getAccelerometerDataStreamSubscription();
    }
  }

  double map(int value, int low1, int high1, int low2, int high2) {
    return low2 + ((high2 - low2) * (value - low1) / (high1 - low1));
  }

  AngleMeasurement calculateAnglesFromDeviceOrientation(
      double angleX, double angleY, double angleZ, int orientation) {
    AngleMeasurement angles = AngleMeasurement(0, 0, 0);

    switch (orientation) {
      case 1:
        {
          angles.xAngle = _RAD_TO_DEG * (atan2(angleZ, -angleY) + _PI);
          angles.yAngle = _RAD_TO_DEG * (atan2(-angleX, -angleZ) + _PI);
          angles.zAngle = _RAD_TO_DEG * (atan2(-angleZ, -angleX) + _PI);
          break;
        }
      case 2:
        {
          angles.xAngle = _RAD_TO_DEG * (atan2(-angleY, -angleZ) + _PI);
          angles.yAngle = _RAD_TO_DEG * (atan2(-angleX, angleY) + _PI);
          angles.zAngle = _RAD_TO_DEG * (atan2(-angleY, -angleX) + _PI);
          break;
        }
      case 3:
        {
          angles.xAngle = _RAD_TO_DEG * (atan2(-angleY, -angleX) + _PI);
          angles.yAngle = _RAD_TO_DEG * (atan2(angleZ, angleY) + _PI);
          angles.zAngle = _RAD_TO_DEG * (atan2(-angleY, angleZ) + _PI);
          break;
        }
      case 4:
        {
          angles.xAngle = _RAD_TO_DEG * (atan2(-angleY, angleX) + _PI);
          angles.yAngle = _RAD_TO_DEG * (atan2(-angleZ, angleY) + _PI);
          angles.zAngle = _RAD_TO_DEG * (atan2(-angleY, -angleZ) + _PI);
          break;
        }
      case 5:
        {
          angles.xAngle = _RAD_TO_DEG * (atan2(-angleY, angleZ) + _PI);
          angles.yAngle = _RAD_TO_DEG * (atan2(angleX, angleY) + _PI);
          angles.zAngle = _RAD_TO_DEG * (atan2(-angleY, angleX) + _PI);
          break;
        }
      case 6:
        {
          angles.xAngle = _RAD_TO_DEG * (atan2(-angleZ, angleY) + _PI);
          angles.yAngle = _RAD_TO_DEG * (atan2(-angleX, angleZ) + _PI);
          angles.zAngle = _RAD_TO_DEG * (atan2(-angleZ, -angleX) + _PI);
          break;
        }
    }

    return angles;
  }

  Future<void> findDeviceCharacteristics() async {
    firmwareVersionCharacteristic = deviceInformationService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid == Guid(DEVICE_FIRMWARE_CHARACTERISTIC_UUID));

    anglesCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_ANGLES_CHARACTERISTIC_UUID));

    orientationCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_ORIENTATION_CHARACTERISTIC_UUID));

    calibrationCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_CALIBRATION_CHARACTERISTIC_UUID));

    savedHitchAngleCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_SAVED_HITCH_ANGLE_CHARACTERISTIC_UUID));

    batteryLevelCharacteristic = batteryLevelService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid == Guid(BATTERY_LEVEL_CHARACTERISTIC_UUID));

    accelerometerDataCharacteristic =
        getAccelerometerDataCharacteristic(accelerometerService!);
  }

  StreamSubscription<BluetoothConnectionState>?
      getConnectionStateStreamSubscription(BluetoothDevice device) {
    return device.connectionState.listen((connectionState) async {
      switch (connectionState) {
        case BluetoothConnectionState.disconnected:
          _connectionStateStreamController.sink.add({"connected": false});

          // Cancel the subscription to stop listening
          connectionStateStreamSubscription?.cancel();

          accelerometerDataCharacteristic = null;
          anglesCharacteristic = null;
          break;
        default:
          break;
      }
    });
  }

  StreamSubscription<List<int>>? getBatteryLevelStreamSubscription() {
    return batteryLevelCharacteristic?.lastValueStream.listen((value) async {
      var obj = {
        "batteryLevel": value[0],
      };
      _batteryLevelStreamController.sink.add(obj);
    });
  }

  Future<String> getFirmwareVersion() async {
    List<int>? firmwareVersion = await firmwareVersionCharacteristic?.read();
    String firmwareString = String.fromCharCodes(firmwareVersion!);
    debugPrint('Firmware Version: $firmwareString');

    return firmwareString;
  }

  Future<double> getSavedHitchAngle() async {
    List<int>? hitchAngleBytes = await savedHitchAngleCharacteristic?.read();
    // The bytes are received in 32 bit little endian format so convert them into a numbers
    ByteData byteData =
        ByteData.sublistView(Uint8List.fromList(hitchAngleBytes!));

    return byteData.getFloat32(0, Endian.little);
  }
}
