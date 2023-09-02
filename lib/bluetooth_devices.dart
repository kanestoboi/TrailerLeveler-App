import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:trailer_leveler_app/bluetooth_bloc.dart';

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
      onTap: () async {
        await BluetoothBloc.instance.connectToDevice(device);
        Navigator.pop(context);
      },
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
    BluetoothBloc.instance.scanResultsStreamSubscription?.cancel();
    // Clear the devices in the discovered list

    // clear the ListView
    setState(() => {});

    // Listen to scan results
    BluetoothBloc.instance.scanResultsStreamSubscription =
        FlutterBluePlus.scanResults.listen((results) {
      // Add unique scan results to _devices list
      for (ScanResult scanResult in results) {
        if (scanResult.device.localName != '' &&
            !_devices.contains(scanResult.device)) {
          debugPrint(
              '${scanResult.device.localName} found! rssi: ${scanResult.rssi}, ID: ${scanResult.device.remoteId}');
          _devices.add(scanResult.device);
          setState(() => {});
        }
      }
    });

    debugPrint("starting scan");
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
    );
  }
}
