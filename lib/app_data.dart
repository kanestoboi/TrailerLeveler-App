import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AppData {
  static final AppData _appData = new AppData._internal();

  int deviceOrientation = 1;
  BluetoothCharacteristic? orientaionCharacteristic;

  factory AppData() {
    return _appData;
  }

  AppData._internal();
}

final appData = AppData();
