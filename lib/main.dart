import 'dart:io';

import 'package:flutter/material.dart';

import 'package:wakelock/wakelock.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:trailer_leveler_app/angles_page.dart';

void main() {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const MyApp());
    });
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // To keep the screen on:
    Wakelock.enable();
    return const MaterialApp(home: AnglesPage());
  }
}
