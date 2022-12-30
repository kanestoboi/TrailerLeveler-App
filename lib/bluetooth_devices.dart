import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:math';

FlutterBlue flutterBlue = FlutterBlue.instance;

// ignore: constant_identifier_names
const String ACCELEROMETER_SERVICE_UUID =
    "76491400-7DD9-11ED-A1EB-0242AC120002";
// ignore: constant_identifier_names
const String ACCELEROMETER_CHARACTERISTIC_UUID =
    "76491401-7DD9-11ED-A1EB-0242AC120002";

double x = 0;
double y = 0;
double z = 0.0;
int xoutput = 0;
int youtput = 0;
int zoutput = 0;
int minVal = -262144;
int maxVal = 262143;

// ignore: non_constant_identifier_names
double RAD_TO_DEG = 57.296;
// ignore: non_constant_identifier_names
double PI = 3.14;

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

  String one = "0";
  String two = "0";

  @override
  dispose() async {
    super.dispose();
  }

  Widget _buildList() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _devices.length,
        itemBuilder: (context, item) => _buildRow(_devices[item]));
  }

  Widget _buildRow(BluetoothDevice device) {
    return ListTile(
      title: Text(device.name + " " + device.id.toString()),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Devices'), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add_link),
          onPressed: () async {
            Navigator.pop(context, 'Yep!');
          },
        ),
      ]),
      body: _buildList(),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: stopScanPressed,
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: const Icon(Icons.refresh), onPressed: refreshPressed);
          }
        },
      ),
    );
  }

  void stopScanPressed() {
    FlutterBlue.instance.stopScan();
  }

  void refreshPressed() {
    // Clear the devices in the discovered list

    // clear the ListView
    setState(() => {});

    // Listen to scan results
    flutterBlue.scanResults.listen((results) {
      // Add unique scan results to _devices list
      for (ScanResult r in results) {
        if (r.device.name != '' && !_devices.contains(r.device)) {
          print('${r.device.name} found! rssi: ${r.rssi}, ID: ${r.device.id}');
          _devices.add(r.device);
          setState(() => {});
        }
      }
    });

    print("starting scan");
    FlutterBlue.instance.startScan(timeout: const Duration(seconds: 8));
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    final _streamController = StreamController<Map<String, double>>();

    Stream<Map<String, double>> stream = _streamController.stream;

    await device
        .connect(autoConnect: false)
        .timeout(const Duration(seconds: 5))
        .onError((error, stackTrace) => {
              Fluttertoast.showToast(
                  msg: "Couldn't Connect to Device",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0)
            });

    List<BluetoothService> services = await device.discoverServices();

    BluetoothCharacteristic? readCharacteristic;

    for (BluetoothService service in services) {
      if (service.uuid == Guid(ACCELEROMETER_SERVICE_UUID)) {
        List<BluetoothCharacteristic> characteristics = service.characteristics;

        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid == Guid(ACCELEROMETER_CHARACTERISTIC_UUID)) {
            readCharacteristic = characteristic;
          }
        }
      }
    }

    if (readCharacteristic == null) {
      print("Not a trailer leveller device");

      Fluttertoast.showToast(
          msg: "Not a Trailer Leveler",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

      device.disconnect();

      return;
    }

    await readCharacteristic.setNotifyValue(true);

    var sub1 = readCharacteristic.value.listen((value) async {
      if (value.length == 12) {
        int accX = (value[3] << 24 | value[2] << 16 | value[1] << 8 | value[0]);
        int accY = (value[7] << 24 | value[6] << 16 | value[5] << 8 | value[4]);
        int accZ =
            (value[11] << 24 | value[10] << 16 | value[9] << 8 | value[8]);

        int maskedN = (value[2] & (1 << 2));
        int thebit = maskedN >> 2;

        if (thebit == 1) {
          accX = accX | 0xFFFFFFFFFF000000;
        }

        maskedN = (value[6] & (1 << 2));
        thebit = maskedN >> 2;

        if (thebit == 1) {
          accY = accY | 0xFFFFFFFFFF000000;
        }

        maskedN = (value[10] & (1 << 2));
        thebit = maskedN >> 2;

        if (thebit == 1) {
          accZ = accZ | 0xFFFFFFFFFF000000;
        }

        xoutput = (0.9896 * xoutput + 0.01042 * accX).round();
        youtput = (0.9896 * youtput + 0.01042 * accY).round();
        zoutput = (0.9896 * zoutput + 0.01042 * accZ).round();

        double xAng = map(xoutput, minVal, maxVal, -90, 90);
        double yAng = map(youtput, minVal, maxVal, -90, 90);
        double zAng = map(zoutput, minVal, maxVal, -90, 90);

        //print(
        //"x: $accX, y: $accY, z: $accZ, xAng: $xAng, yAng: $yAng, zAng: $zAng");

        x = RAD_TO_DEG * (atan2(-yAng, -zAng) + PI);
        y = RAD_TO_DEG * (atan2(-xAng, -zAng) + PI);
        z = RAD_TO_DEG * (atan2(-yAng, -xAng) + PI);

        var obj = {"xAngle": x, "yAngle": y, "zAngle": z};

        //print("x: $x, y: $y, z: $z");

        _streamController.sink.add(obj);
      }
    }, cancelOnError: true);

    Navigator.pop(context, stream);
  }
}

double map(int value, int low1, int high1, int low2, int high2) {
  return low2 + ((high2 - low2) * (value - low1) / (high1 - low1));
}
