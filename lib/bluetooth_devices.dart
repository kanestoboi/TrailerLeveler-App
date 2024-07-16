import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trailer_leveler_app/bluetooth_bloc.dart';
import 'dart:io' show Platform;

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

  void refreshPressed() async {
    BluetoothBloc.instance.scanResultsStreamSubscription?.cancel();
    // Clear the devices in the discovered list
    bool isBluetoothEnabled = await BluetoothBloc.instance.isBluetoothOn();
    if (!isBluetoothEnabled) {
      showBluetoothNotEnabledDialog();
    }

    // clear the ListView
    setState(() => {});

    // Listen to scan results
    BluetoothBloc.instance.scanResultsStreamSubscription =
        FlutterBluePlus.scanResults.listen((results) {
      // Add unique scan results to _devices list
      for (ScanResult scanResult in results) {
        if (scanResult.device.platformName != '' &&
            !_devices.contains(scanResult.device)) {
          debugPrint(
              '${scanResult.device.platformName} found! rssi: ${scanResult.rssi}, ID: ${scanResult.device.remoteId}');
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

  Future<void> showBluetoothNotEnabledDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth Not Enabled'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Bluetooth is not enabled on your device. You will need to enable it from Bluetooth settings to scan for bluetooth devices'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Bluetooth Settings'),
              onPressed: () {
                openBluetoothSettings();
              },
            ),
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

  void openBluetoothSettings() async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.settings.BLUETOOTH_SETTINGS',
      );
      await intent.launch();
    } else if (Platform.isIOS) {
      const url = 'App-Prefs:root=Bluetooth';
      if (await canLaunchUrl(Uri.dataFromString(url))) {
        await launchUrl(Uri.dataFromString(url));
      } else {
        // Open the main settings page as a fallback
        const fallbackUrl = 'App-Prefs:';
        if (await canLaunchUrl(Uri.dataFromString(fallbackUrl))) {
          await launchUrl(Uri.dataFromString(fallbackUrl));
        } else {
          debugPrint('Could not open settings.');
        }
      }
    }
  }
}
