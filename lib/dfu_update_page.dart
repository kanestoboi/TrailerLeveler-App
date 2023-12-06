import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:trailer_leveler_app/bluetooth_bloc.dart';

enum DownloadState {
  DOWNLOAD_NOT_STARTED,
  DOWNLOADING,
  DOWNLOAD_COMPLETE,
  DOWNLOAD_FAILED
}

Map<DownloadState, String> DownloadStateToString = {
  DownloadState.DOWNLOAD_NOT_STARTED: "",
  DownloadState.DOWNLOADING: "Downloading",
  DownloadState.DOWNLOAD_COMPLETE: "Download Complete",
  DownloadState.DOWNLOAD_FAILED: "Download Failed",
};

Map<DFU_UPLOAD_STATE, String> UploadStateToString = {
  DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED: "",
  DFU_UPLOAD_STATE.DISCONNECTING: "Disconnecting",
  DFU_UPLOAD_STATE.UPLOADING: "Uploading",
  DFU_UPLOAD_STATE.UPLOAD_COMPLETE: "Upload Complete",
  DFU_UPLOAD_STATE.UPLOAD_FAILED: "Upload FAILED",
  DFU_UPLOAD_STATE.UPLOAD_FAILED_NO_DEVICE_CONNECTED:
      "Upload FAILED - No Device Connected",
  DFU_UPLOAD_STATE.CONNECTING: "Reconnecting",
};

class DFUUpdatePage extends StatefulWidget {
  const DFUUpdatePage({super.key});

  @override
  _DFUUpdatePageState createState() => _DFUUpdatePageState();
}

class _DFUUpdatePageState extends State<DFUUpdatePage> {
  bool downloadingLatestRelease = false; // Set this based on your logic

  DownloadState currentDownloadState = DownloadState.DOWNLOAD_NOT_STARTED;
  DFU_UPLOAD_STATE currentUploadState = DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED;

  double dfuUploadProgress = 0.0;
  bool dfuInProgress = false;
  bool dfuUploading = false;

  bool deviceConnected = false;

  StreamSubscription<int>? dfuProgressSubscription;
  StreamSubscription<DFU_UPLOAD_STATE>? dfuStateSubscription;

  @override
  void initState() {
    dfuProgressSubscription =
        BluetoothBloc.instance.dfuProgressStream.listen((progress) {
      setState(() {
        dfuUploadProgress = progress / 100;
      });
    });

    dfuStateSubscription =
        BluetoothBloc.instance.dfuStateStream.listen((uploadState) {
      setState(() {
        currentUploadState = uploadState;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    debugPrint("DFU UPDATE PAGE DISPOSE CALLED");
    super.dispose();
    dfuProgressSubscription?.cancel();
    dfuStateSubscription?.cancel();
  }

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
                    visible: currentUploadState !=
                        DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED,
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
                    visible: currentUploadState !=
                        DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED,
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
                visible:
                    currentUploadState == DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED ||
                        currentUploadState == DFU_UPLOAD_STATE.UPLOAD_FAILED,
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
                      currentUploadState = DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED;
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
                        currentUploadState =
                            DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED;
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
                          currentUploadState = DFU_UPLOAD_STATE.UPLOADING;
                        });

                        await startDfu(downloadedFile.path);

                        // Once firmware update has completed, delete the downloaded file
                        await downloadedFile.delete();

                        debugPrint("Deleted File");
                      }
                    } else {
                      setState(() {
                        currentDownloadState = DownloadState.DOWNLOAD_FAILED;
                      });
                      debugPrint("Link not found");
                    }

                    setState(() {
                      dfuInProgress = false;
                    });
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
                visible: currentUploadState ==
                        DFU_UPLOAD_STATE.UPLOAD_NOT_STARTED ||
                    currentUploadState == DFU_UPLOAD_STATE.UPLOAD_FAILED ||
                    currentUploadState == DFU_UPLOAD_STATE.UPLOAD_COMPLETE ||
                    currentUploadState ==
                        DFU_UPLOAD_STATE.UPLOAD_FAILED_NO_DEVICE_CONNECTED,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop(context);
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
    try {
      debugPrint("Updating");

      await BluetoothBloc.instance.doDeviceFirmwareUpdate(filePath);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String?> getLatestReleaseAssetLink() async {
    const username = 'kanestoboi';
    const repo = 'TrailerLeveler-Firmware';

    final response = await http.get(
      Uri.https('api.github.com', 'repos/$username/$repo/releases/latest'),
    );

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
