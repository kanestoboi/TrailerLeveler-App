import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
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
const String ENVIRONMENTAL_SENSING_SERVICE_UUID =
    "0000181A-0000-1000-8000-00805f9b34fb";
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
const String ACCELEROMETER_VEHICLE_LENGTH_CHARACTERISTIC_UUID =
    "76491408-7DD9-11ED-A1EB-0242AC120002";
const String ACCELEROMETER_VEHICLE_WIDTH_CHARACTERISTIC_UUID =
    "76491409-7DD9-11ED-A1EB-0242AC120002";
const String ACCELEROMETER_LEVELING_MODE_CHARACTERISTIC_UUID =
    "76491410-7DD9-11ED-A1EB-0242AC120002";
const String ACCELEROMETER_LENGTH_AXIS_ADJUSTMENT_CHARACTERISTIC_UUID =
    "76491411-7DD9-11ED-A1EB-0242AC120002";
const String ACCELEROMETER_WIDTH_AXIS_ADJUSTMENT_CHARACTERISTIC_UUID =
    "76491412-7DD9-11ED-A1EB-0242AC120002";

// ignore: constant_identifier_names
const String BATTERY_LEVEL_CHARACTERISTIC_UUID =
    "00002A19-0000-1000-8000-00805F9B34FB";
// ignore: constant_identifier_names
const String TEMPERATURE_CHARACTERISTIC_UUID =
    "00002A6E-0000-1000-8000-00805F9B34FB";

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

enum DFU_UPLOAD_STATE {
  UPLOAD_NOT_STARTED,
  DISCONNECTING,
  UPLOADING,
  UPLOAD_COMPLETE,
  UPLOAD_FAILED,
  UPLOAD_FAILED_NO_DEVICE_CONNECTED,
  CONNECTING,
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
  StreamSubscription<List<int>>?
      lengthAxisAdjustmentCharacteristicStreamSubscription;
  StreamSubscription<List<int>>?
      widthAxisAdjustmentCharacteristicStreamSubscription;
  StreamSubscription<List<int>>? batteryLevelCharacteristicStreamSubscription;
  StreamSubscription<List<int>>? temperatureCharacteristicStreamSubscription;
  StreamSubscription<List<int>>? levelingModeCharacteristicStreamSubscription;

  BluetoothService? deviceInformationService;
  BluetoothService? accelerometerService;
  BluetoothService? batteryLevelService;
  BluetoothService? environmentalSensingService;

  BluetoothCharacteristic? firmwareVersionCharacteristic;
  BluetoothCharacteristic? accelerometerDataCharacteristic;
  BluetoothCharacteristic? anglesCharacteristic;
  BluetoothCharacteristic? orientationCharacteristic;
  BluetoothCharacteristic? calibrationCharacteristic;
  BluetoothCharacteristic? savedHitchAngleCharacteristic;
  BluetoothCharacteristic? vehicleLengthCharacteristic;
  BluetoothCharacteristic? vehicleWidthCharacteristic;
  BluetoothCharacteristic? levelingModeCharacteristic;
  BluetoothCharacteristic? lengthAxisAdjustmentCharacteristic;
  BluetoothCharacteristic? widthAxisAdjustmentCharacteristic;
  BluetoothCharacteristic? batteryLevelCharacteristic;
  BluetoothCharacteristic? temperatureCharacteristic;

  DFU_UPLOAD_STATE currentDFUUploadState = DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED;

  BluetoothDevice? trailerLevelerDevice;

  int currentOrientation = 1;

  final _anglesStreamController = StreamController<Map<String, double>>();
  final _xAngleStreamController = StreamController<double>.broadcast();
  final _yAngleStreamController = StreamController<double>.broadcast();
  final _levelingModeStreamController = StreamController<int>.broadcast();
  final _lengthAxisAdjustmentStreamController =
      StreamController<double>.broadcast();
  final _widthAxisAdjustmentStreamController =
      StreamController<double>.broadcast();
  final _batteryLevelStreamController = StreamController<int>.broadcast();
  final _temperatureStreamController = StreamController<double>.broadcast();
  final _connectionStateStreamController = StreamController<String>.broadcast();
  final _deviceNameStreamController = StreamController<String>.broadcast();
  final _dfuProgressStreamController = StreamController<int>.broadcast();
  final _dfuStateStreamController =
      StreamController<DFU_UPLOAD_STATE>.broadcast();

  // Declare the subscription variable
  StreamSubscription<BluetoothConnectionState>?
      connectionStateStreamSubscription;

  Stream<Map<String, double>> get anglesStream =>
      _anglesStreamController.stream;
  Stream<double> get xAngleStream => _xAngleStreamController.stream;
  Stream<double> get yAngleStream => _yAngleStreamController.stream;
  Stream<int> get levelingModeStream => _levelingModeStreamController.stream;
  Stream<double> get lengthAxisAdjustmentStream =>
      _lengthAxisAdjustmentStreamController.stream;
  Stream<double> get widthAxisAdjustmentStream =>
      _widthAxisAdjustmentStreamController.stream;
  Stream<int> get batteryLevelStream => _batteryLevelStreamController.stream;
  Stream<double> get temperatureStream => _temperatureStreamController.stream;
  Stream<String> get connectionStateStream =>
      _connectionStateStreamController.stream;
  Stream<String> get deviceNameStream => _deviceNameStreamController.stream;
  Stream<int> get dfuProgressStream => _dfuProgressStreamController.stream;
  Stream<DFU_UPLOAD_STATE> get dfuStateStream =>
      _dfuStateStreamController.stream;

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

  Future<void> setVehicleLength(double length) async {
    // Step 1: Allocate a ByteData object of 4 bytes (for a 32-bit float)
    ByteData float32Data = ByteData(4);

    // Step 2: Set the float value at the beginning of the byte buffer
    float32Data.setFloat32(0, length, Endian.little);

    // Step 3: Get the byte array directly from the ByteData object
    List<int> lengthByteArray = float32Data.buffer.asUint8List();
    await vehicleLengthCharacteristic?.write(lengthByteArray);
  }

  Future<double> getVehicleLength() async {
    double length = 1.0;
    List<int>? lengthByteData = await vehicleLengthCharacteristic?.read();

    if (lengthByteData == null) {
      return length;
    }

    ByteData byteData =
        ByteData.sublistView(Uint8List.fromList(lengthByteData!));
    if (lengthByteData.length == 4) {
      length = byteData.getFloat32(0, Endian.little);
    }

    return length;
  }

  Future<void> setVehicleWidth(double width) async {
    // Step 1: Allocate a ByteData object of 4 bytes (for a 32-bit float)
    ByteData float32Data = ByteData(4);

    // Step 2: Set the float value at the beginning of the byte buffer
    float32Data.setFloat32(0, width, Endian.little);

    // Step 3: Get the byte array directly from the ByteData object
    List<int> widthByteArray = float32Data.buffer.asUint8List();
    await vehicleWidthCharacteristic?.write(widthByteArray);
  }

  Future<double> getVehicleWidth() async {
    double width = 1.0;
    List<int>? widthByteData = await vehicleWidthCharacteristic?.read();

    if (widthByteData == null) {
      return width;
    }

    ByteData byteData =
        ByteData.sublistView(Uint8List.fromList(widthByteData!));
    if (widthByteData.length == 4) {
      width = byteData.getFloat32(0, Endian.little);
    }

    return width;
  }

  Future<void> setLevelingMode(int mode) async {
    // Step 1: Allocate a ByteData object of 4 bytes (for a 32-bit float)
    ByteData uint8Data = ByteData(1);

    // Step 2: Set the float value at the beginning of the byte buffer
    uint8Data.setUint8(0, mode);

    // Step 3: Get the byte array directly from the ByteData object
    List<int> modeByteArray = uint8Data.buffer.asUint8List();
    await levelingModeCharacteristic?.write(modeByteArray);
  }

  Future<int> getLevelingMode() async {
    int mode = 0;
    List<int>? modeByteData = await levelingModeCharacteristic?.read();

    if (modeByteData == null) {
      return mode;
    }

    ByteData byteData = ByteData.sublistView(Uint8List.fromList(modeByteData!));
    if (modeByteData.length == 1) {
      mode = byteData.getUint8(0);
    }

    return mode;
  }

  String getDeviceName() {
    if (trailerLevelerDevice?.platformName != null) {
      return trailerLevelerDevice!.platformName.toUpperCase();
    } else {
      return "UNKNOWN DEVICE";
    }
  }

  Future<void> connectToDevice(BluetoothDevice? device) async {
    _connectionStateStreamController.sink.add("connecting");
    anglesCharacteristicStreamSubscription?.cancel();

    if (device == null && trailerLevelerDevice == null) {
      return;
    } else if (device == null && trailerLevelerDevice != null) {
      device = trailerLevelerDevice;
    }

    if (device == null) {
      return;
    }

    bool connected = true;
    await device.connect(autoConnect: false).onError((error, stackTrace) {
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

      _connectionStateStreamController.sink.add("disconnected");
    });

    if (!connected) {
      debugPrint("Not Connected");
      return;
    }

    trailerLevelerDevice = device;

    await findDeviceServices(device);

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

    await findDeviceCharacteristics();

    await setAnglesSource(ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_DEVICE);

    // Start listening to the connection state stream
    connectionStateStreamSubscription =
        getConnectionStateStreamSubscription(device);

    temperatureCharacteristicStreamSubscription =
        getTemperatureStreamSubscription();
    levelingModeCharacteristicStreamSubscription =
        getLevelingModeStreamSubscription();

    lengthAxisAdjustmentCharacteristicStreamSubscription =
        getLengthAxisAdjustmentStreamSubscription();

    widthAxisAdjustmentCharacteristicStreamSubscription =
        getWidthAxisAdjustmentStreamSubscription();

    await lengthAxisAdjustmentCharacteristic?.setNotifyValue(true);
    await widthAxisAdjustmentCharacteristic?.setNotifyValue(true);

    await temperatureCharacteristic?.setNotifyValue(true);
    await levelingModeCharacteristic?.setNotifyValue(true);

    await batteryLevelCharacteristic?.setNotifyValue(true);
    await batteryLevelCharacteristic?.read();

    batteryLevelCharacteristicStreamSubscription =
        getBatteryLevelStreamSubscription();

    _connectionStateStreamController.sink.add("connected");
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

    environmentalSensingService = services.firstWhereOrNull(
        (service) => service.uuid == Guid(ENVIRONMENTAL_SENSING_SERVICE_UUID));

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

    if (environmentalSensingService == null) {
      debugPrint("Environmental Sensing Service NOT found");
    } else {
      debugPrint("Environmental Sensing Service found");
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
      _xAngleStreamController.sink.add(obj['xAngle']!);
      _yAngleStreamController.sink.add(obj['yAngle']!);
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
        _xAngleStreamController.sink.add(obj['xAngle']!);
        _yAngleStreamController.sink.add(obj['yAngle']!);

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

    vehicleLengthCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_VEHICLE_LENGTH_CHARACTERISTIC_UUID));

    vehicleWidthCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_VEHICLE_WIDTH_CHARACTERISTIC_UUID));

    levelingModeCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_LEVELING_MODE_CHARACTERISTIC_UUID));

    lengthAxisAdjustmentCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_LENGTH_AXIS_ADJUSTMENT_CHARACTERISTIC_UUID));

    widthAxisAdjustmentCharacteristic = accelerometerService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid ==
            Guid(ACCELEROMETER_WIDTH_AXIS_ADJUSTMENT_CHARACTERISTIC_UUID));

    batteryLevelCharacteristic = batteryLevelService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid == Guid(BATTERY_LEVEL_CHARACTERISTIC_UUID));

    temperatureCharacteristic = environmentalSensingService?.characteristics
        .firstWhereOrNull((characteristic) =>
            characteristic.uuid == Guid(TEMPERATURE_CHARACTERISTIC_UUID));

    accelerometerDataCharacteristic =
        getAccelerometerDataCharacteristic(accelerometerService!);

    allCharacteristicsLoaded();
  }

  StreamSubscription<BluetoothConnectionState>?
      getConnectionStateStreamSubscription(BluetoothDevice device) {
    return device.connectionState.listen((connectionState) async {
      switch (connectionState) {
        case BluetoothConnectionState.disconnected:
          _connectionStateStreamController.sink.add("disconnected");

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
      _batteryLevelStreamController.sink.add(value[0]);
    });
  }

  StreamSubscription<List<int>>? getTemperatureStreamSubscription() {
    return temperatureCharacteristic?.lastValueStream.listen((value) async {
      if (value.length == 2) {
        ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));
        double temperature = byteData.getInt16(0, Endian.little) / 100.0;

        _temperatureStreamController.sink.add(temperature);
      }
    });
  }

  StreamSubscription<List<int>>? getLevelingModeStreamSubscription() {
    return levelingModeCharacteristic?.lastValueStream.listen((value) async {
      if (value.length == 1) {
        ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));
        int levelingMode = byteData.getUint8(0);

        _levelingModeStreamController.sink.add(levelingMode);
      }
    });
  }

  StreamSubscription<List<int>>? getLengthAxisAdjustmentStreamSubscription() {
    return lengthAxisAdjustmentCharacteristic?.lastValueStream.listen((value) {
      if (value.length == 4) {
        ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));

        double lengthAxisAdjustment = byteData.getFloat32(0, Endian.little);

        _lengthAxisAdjustmentStreamController.sink.add(lengthAxisAdjustment);
      }
    });
  }

  StreamSubscription<List<int>>? getWidthAxisAdjustmentStreamSubscription() {
    return widthAxisAdjustmentCharacteristic?.lastValueStream
        .listen((value) async {
      if (value.length == 4) {
        ByteData byteData = ByteData.sublistView(Uint8List.fromList(value));

        double widthAxisAdjustment = byteData.getFloat32(0, Endian.little);

        _widthAxisAdjustmentStreamController.sink.add(widthAxisAdjustment);
      }
    });
  }

  Future<String> getFirmwareVersion() async {
    List<int>? firmwareVersion = await firmwareVersionCharacteristic?.read();
    String firmwareString = String.fromCharCodes(firmwareVersion!);

    return firmwareString;
  }

  Future<double> getSavedHitchAngle() async {
    List<int>? hitchAngleBytes = await savedHitchAngleCharacteristic?.read();
    // The bytes are received in 32 bit little endian format so convert them into a numbers
    ByteData byteData =
        ByteData.sublistView(Uint8List.fromList(hitchAngleBytes!));

    return byteData.getFloat32(0, Endian.little);
  }

  bool isConnected() {
    return connectionStateStreamSubscription != null;
  }

  void setBluetoothDeviceMACAddress(String MACAddress) {
    trailerLevelerDevice = BluetoothDevice(
      remoteId: DeviceIdentifier(MACAddress),
    );
  }

  String? getBluetoothDeviceMACAddress() {
    return trailerLevelerDevice?.remoteId.toString();
  }

  void setBluetoothDeviceName(String name) {
    _deviceNameStreamController.sink.add(name);
  }

  String? getBluetoothDeviceName() {
    return trailerLevelerDevice?.platformName;
  }

  Future<bool> isBluetoothOn() async {
    return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  Future<void> doDeviceFirmwareUpdate(String filePath) async {
    if (trailerLevelerDevice == null) {
      currentDFUUploadState =
          DFU_UPLOAD_STATE.UPLOAD_FAILED_NO_DEVICE_CONNECTED;
      _dfuStateStreamController.sink.add(currentDFUUploadState);
      return;
    }

    currentDFUUploadState = DFU_UPLOAD_STATE.DISCONNECTING;
    _dfuStateStreamController.sink.add(currentDFUUploadState);

    await trailerLevelerDevice?.disconnect();

    await NordicDfu().startDfu(
      trailerLevelerDevice!.remoteId.toString(),
      filePath,
      fileInAsset: false,
      onDeviceDisconnecting: (string) {
        debugPrint('deviceAddress: $string');
      },
      onProgressChanged: (
        deviceAddress,
        percent,
        speed,
        avgSpeed,
        currentPart,
        partsTotal,
      ) {
        currentDFUUploadState = DFU_UPLOAD_STATE.UPLOADING;
        _dfuStateStreamController.sink.add(currentDFUUploadState);
        _dfuProgressStreamController.sink.add(percent);
      },
      onDfuAborted: (address) => () {
        debugPrint('ABORTED!!!!!!!');
      },
      onFirmwareValidating: (address) {
        debugPrint('Validating');
      },
      onDfuCompleted: (address) {
        debugPrint('Completed');
        _dfuStateStreamController.sink.add(DFU_UPLOAD_STATE.UPLOAD_COMPLETE);
      },
      onError: (address, error, errorType, message) async {
        debugPrint('Error: $message');
        _dfuStateStreamController.sink.add(DFU_UPLOAD_STATE.UPLOAD_FAILED);
      },
      onEnablingDfuMode: (address) {
        debugPrint('Enabling DFU mode');
      },
    );

    await connectToDevice(null);
  }

  void allCharacteristicsLoaded() async {
    int levelingMode = await getLevelingMode();
    _levelingModeStreamController.sink.add(levelingMode);
    print("leveling mode $levelingMode");
  }
}
