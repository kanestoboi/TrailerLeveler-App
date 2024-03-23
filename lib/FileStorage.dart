import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class TemperatureDataPoint {
  final int time;
  final double temperature;

  TemperatureDataPoint(this.time, this.temperature);
}

class AngleDataPoint {
  final int time;
  final double angle;

  AngleDataPoint(this.time, this.angle);
}

// To save the file in the device
class FileStorage {
  static Future<String> getExternalDocumentPath() async {
    // To check whether permission is given for this app or not.
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // If not we will ask for permission first
      await Permission.storage.request();
    }
    Directory _directory = Directory("");
    if (Platform.isAndroid) {
      // Redirects it to download folder in android
      _directory = Directory("/storage/emulated/0/documents");
    } else {
      _directory = await getApplicationDocumentsDirectory();
    }

    final exPath = _directory.path;
    print("Saved Path: $exPath");
    await Directory(exPath).create(recursive: true);
    return exPath;
  }

  static Future<String> get _localPath async {
    // final directory = await getApplicationDocumentsDirectory();
    // return directory.path;
    // To get the external path from device of download folder
    final String directory = await getExternalDocumentPath();
    return directory;
  }

  static Future<File> writeCounter(String bytes, String name) async {
    final path = await _localPath;
    // Create a file for the path of
    // device and file name with extension
    File file = File('$path/$name');
    ;
    print("Save file");

    // Write the data in the file you have created
    return file.writeAsString(bytes);
  }

  static Future<File> writeValues<T>(List<T> values, String name) async {
    final path = await _localPath;
    File file = File('$path/$name.csv');

    // Open the file for writing.
    IOSink sink = file.openWrite();

    // Write each value to a new line in the file.
    for (T value in values) {
      sink.writeln(value.toString());
    }

    // Close the file.
    await sink.close();

    return file;
  }

  static Future<File> writeTemperatureDataPoints(
      List<TemperatureDataPoint> dataPoints, String name) async {
    final path = await _localPath;
    File file = File('$path/$name.csv');

    // Open the file for writing.
    IOSink sink = file.openWrite();

    // Write each data point to a new line in the file.
    for (TemperatureDataPoint dataPoint in dataPoints) {
      sink.writeln('${dataPoint.time},${dataPoint.temperature}');
    }

    // Close the file.
    await sink.close();

    return file;
  }

  static Future<File> writeAngleDataPoints(
      List<AngleDataPoint> dataPoints, String name) async {
    final path = await _localPath;
    File file = File('$path/$name.csv');

    // Open the file for writing.
    IOSink sink = file.openWrite();

    // Write each data point to a new line in the file.
    for (AngleDataPoint dataPoint in dataPoints) {
      sink.writeln('${dataPoint.time},${dataPoint.angle}');
    }

    // Close the file.
    await sink.close();

    return file;
  }
}
