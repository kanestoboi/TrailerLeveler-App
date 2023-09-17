import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nordic_dfu/nordic_dfu.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:trailer_leveler_app/bluetooth_bloc.dart';

enum DownloadState {
  DOWNLOAD_NOT_STARTED,
  DOWNLOADING,
  DOWNLOAD_COMPLETE,
  DOWNLOAD_FAILED
}

enum UploadState {
  UPLOAD_NOT_STARTED,
  UPLOADING,
  UPLOAD_COMPLETE,
  UPLOAD_FAILED,
  UPLOAD_FAILED_NO_DEVICE_CONNECTED,
}

enum DFUState {
  DFU_NOT_COMPLETE,
  DFU_COMPLETE,
}

Map<DownloadState, String> DownloadStateToString = {
  DownloadState.DOWNLOAD_NOT_STARTED: "",
  DownloadState.DOWNLOADING: "Downloading",
  DownloadState.DOWNLOAD_COMPLETE: "Download Complete",
  DownloadState.DOWNLOAD_FAILED: "Download Failed",
};

Map<UploadState, String> UploadStateToString = {
  UploadState.UPLOAD_NOT_STARTED: "",
  UploadState.UPLOADING: "Uploading",
  UploadState.UPLOAD_COMPLETE: "Upload Complete",
  UploadState.UPLOAD_FAILED: "Upload FAILED",
  UploadState.UPLOAD_FAILED_NO_DEVICE_CONNECTED:
      "Upload FAILED - No Device Connected",
};

class DFUUpdatePage extends StatefulWidget {
  const DFUUpdatePage({super.key});

  @override
  _DFUUpdatePageState createState() => _DFUUpdatePageState();
}

class _DFUUpdatePageState extends State<DFUUpdatePage> {
  bool downloadingLatestRelease = false; // Set this based on your logic

  DownloadState currentDownloadState = DownloadState.DOWNLOAD_NOT_STARTED;
  UploadState currentUploadState = UploadState.UPLOAD_NOT_STARTED;

  double dfuUploadProgress = 0.0;
  bool dfuInProgress = false;
  bool dfuUploading = false;

  bool deviceConnected = false;

  bool dfuRunning = false;

  BluetoothDevice? deviceForDFU;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.lightBlue,
                width: 400,
                child: const Text(
                  "Firmware Update",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 1,
                    fontSize: 30,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Column(
                children: [
                  Visibility(
                    visible: currentDownloadState !=
                        DownloadState.DOWNLOAD_NOT_STARTED,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.transparent,
                      width: 400,
                      child: Text(
                        DownloadStateToString[currentDownloadState]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible:
                        currentUploadState != UploadState.UPLOAD_NOT_STARTED,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.transparent,
                      width: 400,
                      child: Text(
                        UploadStateToString[currentUploadState]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible:
                        currentUploadState != UploadState.UPLOAD_NOT_STARTED,
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      color: Colors.transparent,
                      width: 400,
                      child: LinearProgressIndicator(
                        value: dfuUploadProgress,
                        semanticsLabel: 'Linear progress indicator',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.transparent,
              width: 400,
              child: Visibility(
                visible: !dfuInProgress,
                child: FilledButton(
                  onPressed: () async {
                    if (!BluetoothBloc.instance.isConnected()) {
                      Fluttertoast.showToast(
                        msg: 'Not connected to a device',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );

                      return;
                    }

                    setState(() {
                      dfuInProgress = true;
                      currentDownloadState = DownloadState.DOWNLOAD_NOT_STARTED;
                      currentUploadState = UploadState.UPLOAD_NOT_STARTED;
                    });

                    setState(() {
                      currentDownloadState = DownloadState.DOWNLOADING;
                    });

                    String? latestDeviceFirmwareVersion =
                        await getLatestReleaseAssetVersion();

                    String? currentDeviceVersionNumber =
                        await BluetoothBloc.instance.getFirmwareVersion();

                    if (latestDeviceFirmwareVersion ==
                        "v$currentDeviceVersionNumber") {
                      debugPrint("Latest firmware virsion installed already");
                      Fluttertoast.showToast(
                        msg: 'Latest firmware virsion installed already',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.grey,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );

                      setState(() {
                        dfuInProgress = false;
                        currentDownloadState =
                            DownloadState.DOWNLOAD_NOT_STARTED;
                        currentUploadState = UploadState.UPLOAD_NOT_STARTED;
                      });
                      return;
                    }

                    String? link = await getLatestReleaseAssetLink();

                    if (link != null) {
                      File? downloadedFile =
                          await downloadLatestReleaseAsset(link);
                      setState(() {
                        currentDownloadState = DownloadState.DOWNLOAD_COMPLETE;
                      });

                      if (downloadedFile == null) {
                        setState(() {
                          currentDownloadState = DownloadState.DOWNLOAD_FAILED;
                        });

                        return;
                      }

                      if (await downloadedFile.exists()) {
                        setState(() {
                          currentUploadState = UploadState.UPLOADING;
                        });

                        await startDfu(downloadedFile.path);
                        await downloadedFile.delete();

                        debugPrint("Deleted File");
                      }
                    } else {
                      setState(() {
                        currentDownloadState = DownloadState.DOWNLOAD_FAILED;
                      });
                      debugPrint("Link not found");
                    }

                    await BluetoothBloc.instance.connectToDevice(deviceForDFU!);

                    setState(() {
                      dfuInProgress = false;
                    });
                    //Navigator.of(context).pop();
                  },
                  child: const Text('Start Firmware Update'),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.transparent,
              width: 60,
              child: Visibility(
                visible: !dfuInProgress,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> startDfu(String filePath) async {
    String? deviceID;

    List<BluetoothDevice> devices =
        await FlutterBluePlus.connectedSystemDevices;

    devices.forEach((device) async {
      if (device.localName == "Trailer Leveler") {
        deviceID = device.remoteId.toString();
        deviceForDFU = device;

        await deviceForDFU?.disconnect();
      }
    });

    if (deviceID == null) {
      setState(() {
        debugPrint("no device id");
        currentUploadState = UploadState.UPLOAD_FAILED_NO_DEVICE_CONNECTED;
      });
      return;
    }

    try {
      debugPrint("Updating");
      final s = await NordicDfu().startDfu(
        deviceID!,
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
          setState(() {
            dfuUploadProgress = percent / 100;
          });

          dfuUploadProgress = percent / 100;
          debugPrint('deviceAddress: $deviceAddress, percent: $percent');
        },
        onDfuAborted: (address) => () {
          debugPrint('ABORTED!!!!!!!');
        },
        onFirmwareValidating: (address) {
          debugPrint('Validating');
        },
        onDfuCompleted: (address) {
          debugPrint('Completed');
          currentUploadState = UploadState.UPLOAD_COMPLETE;
        },
        onError: (address, error, errorType, message) async {
          debugPrint('Error: ${message}');
        },
        onEnablingDfuMode: (address) {
          debugPrint('Enabling DFU mode');
        },
      );

      debugPrint(s);
      dfuRunning = false;
    } catch (e) {
      dfuRunning = false;
      debugPrint(e.toString());
    }
  }

  Future<String?> getLatestReleaseAssetLink() async {
    const username = 'kanestoboi';
    const repo = 'TrailerLeveler-Firmware';

    debugPrint('api.github.com/repos/$username/$repo/releases/latest');

    final response = await http.get(
      Uri.https('api.github.com', 'repos/$username/$repo/releases/latest'),
    );

    debugPrint(response.statusCode.toString());

    if (response.statusCode == 200) {
      final releaseData = json.decode(response.body);
      final assets = releaseData['assets'] as List<dynamic>;

      for (var asset in assets) {
        final assetName = asset['name'] as String;
        if (assetName.contains('trailer_leveler_application_v') &&
            assetName.endsWith('_s140.zip')) {
          return asset['browser_download_url'] as String;
        }
      }
    }

    return null;
  }

  Future<String?> getLatestReleaseAssetVersion() async {
    const username = 'kanestoboi';
    const repo = 'TrailerLeveler-Firmware';

    final response = await http.get(
      Uri.https('api.github.com', 'repos/$username/$repo/releases/latest'),
    );

    debugPrint(response.statusCode.toString());

    if (response.statusCode == 200) {
      final releaseData = json.decode(response.body);
      final releaseVersion = releaseData['tag_name'] as String;

      debugPrint('VERSION!!!: $releaseVersion');

      return releaseVersion;
    }

    return null;
  }

  Future<File?> downloadLatestReleaseAsset(String assetLink) async {
    File? downloadedFile;
    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/trailer_leveler_application.zip';

    final response = await http.get(Uri.parse(assetLink));

    if (response.statusCode == 200) {
      final file = File(tempFilePath);
      await file.writeAsBytes(response.bodyBytes);
      debugPrint("Download Completed");
      // Delete the downloaded file after it's complete
      downloadedFile = File(tempFilePath);
    }

    return downloadedFile;
  }
}
