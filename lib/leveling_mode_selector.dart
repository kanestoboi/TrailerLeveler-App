import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

enum LevelingMode {
  LEVEL_TO_LEVEL,
  LEVEL_TO_SAVED_HITCH_HEIGHT,
}

enum CONNECT_BUTTON_STATE {
  CONNECTING_TO_DEVICE,
  CONNECTED_TO_DEVICE,
  DISCONNECTED_FROM_DEVICE
}

typedef SaveHitchAngleCallback = void Function();
typedef SetLevelingModeCallback = void Function(int levelingMode);
typedef ConnectButtonPressedCallback = void Function();

class LevelingModeSelector extends StatefulWidget {
  final Stream<int>? levelingModeStream;
  final Stream<String>? deviceConnectionStream;
  final SetLevelingModeCallback setLevelingModeCallback;
  final SaveHitchAngleCallback saveHitchHeightAngleCallback;
  final ConnectButtonPressedCallback connectButtonPressedCallback;

  const LevelingModeSelector(
      {Key? super.key,
      this.levelingModeStream,
      this.deviceConnectionStream,
      required this.setLevelingModeCallback,
      required this.saveHitchHeightAngleCallback,
      required this.connectButtonPressedCallback});

  @override
  _LevelingModeSelectorState createState() => _LevelingModeSelectorState();
}

class _LevelingModeSelectorState extends State<LevelingModeSelector> {
  StreamSubscription<int>? levelingModeStreamSubscription;

  LevelingMode currentLevelingMode = LevelingMode.LEVEL_TO_LEVEL;

  CONNECT_BUTTON_STATE connectButtonState =
      CONNECT_BUTTON_STATE.DISCONNECTED_FROM_DEVICE;

  @override
  void dispose() {
    // TODO: implement dispose
    cancelStreamSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    initialiseStreamSubscriptions();

    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(16.0), // Adjust the padding as needed
            child: getConnectToDeviceWidget()),
        Padding(
            padding: const EdgeInsets.fromLTRB(
                0, 8.0, 0, 0), // Adjust the padding as needed
            child: toggleLevelingModeButtonWidget()),
        Padding(
            padding: const EdgeInsets.all(8.0), // Adjust the padding as needed
            child: getSaveHitchHeightWidget()),
      ],
    );
  }

  Widget getSaveHitchHeightWidget() {
    return (connectButtonState == CONNECT_BUTTON_STATE.CONNECTED_TO_DEVICE)
        ? FilledButton(
            onPressed: () async {
              await _showSaveHitchHeightConfirmationDialog();
            },
            child: const Text('Save Hitch Height'),
          )
        : const SizedBox();
  }

  Future<void> _showSaveHitchHeightConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orangeAccent,
                size: 50,
              ), // Warning icon
              SizedBox(width: 8), // Add some spacing between the icon and text
              Expanded(
                child: Text(
                  'This action will overwrite any previous height saved',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(),
          actions: <Widget>[
            TextButton(
              child: const Text('Overwrite previous height'),
              onPressed: () async {
                widget.saveHitchHeightAngleCallback();
                Fluttertoast.showToast(
                  msg: 'Hitch height saved',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.grey,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<bool> isSelected = [true, false];
  Widget toggleLevelingModeButtonWidget() {
    return (connectButtonState == CONNECT_BUTTON_STATE.CONNECTED_TO_DEVICE)
        ? Center(
            child: ToggleButtons(
              color: Colors.transparent,
              selectedColor: Colors.transparent,
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              selectedBorderColor: Colors.transparent,
              isSelected: isSelected,
              onPressed: (int index) {
                setState(() {
                  isSelected =
                      List.generate(isSelected.length, (i) => i == index);
                  toggleLevelingMode(0);
                });
              },
              children: _buildToggleButtons(),
            ),
          )
        : const SizedBox();
  }

  List<Widget> _buildToggleButtons() {
    return [
      ElevatedButton(
        onPressed: () {
          setState(() {
            isSelected = [true, false];
            toggleLevelingMode(0);
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            isSelected[0] ? Colors.green : Colors.grey,
          ),
        ),
        child: const Text('Adjest to Level'),
      ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            isSelected = [false, true];
          });
          toggleLevelingMode(1);
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            isSelected[1] ? Colors.green : Colors.grey,
          ),
        ),
        child: const Text('Adjust to Saved Height'),
      ),
    ];
  }

  Widget getConnectToDeviceWidget() {
    switch (connectButtonState) {
      case CONNECT_BUTTON_STATE.CONNECTED_TO_DEVICE:
        {
          return const SizedBox();
        }
      case CONNECT_BUTTON_STATE.DISCONNECTED_FROM_DEVICE:
        {
          return FilledButton(
            onPressed: () {
              widget.connectButtonPressedCallback();
              setState(() {});
            },
            child: const Text('Connect to Device'),
          );
        }

      case CONNECT_BUTTON_STATE.CONNECTING_TO_DEVICE:
        {
          return FilledButton(
            onPressed: () {},
            child: const Text('Connecting'),
          );
        }
    }
  }

  void toggleLevelingMode(int mode) {
    widget.setLevelingModeCallback(mode);
  }

  Future<void> cancelStreamSubscriptions() async {
    await levelingModeStreamSubscription?.cancel();

    print("Streams Cancelled");
  }

  void initialiseStreamSubscriptions() {
    levelingModeStreamSubscription =
        widget.levelingModeStream?.listen((levelingMode) {
      if (levelingMode == 0) {
        isSelected = [true, false];
      } else {
        isSelected = [false, true];
      }

      if (mounted) {
        setState(() {});
      }
    });
    widget.deviceConnectionStream?.listen((connectionState) {
      if (connectionState == "disconnected") {
        connectButtonState = CONNECT_BUTTON_STATE.DISCONNECTED_FROM_DEVICE;
      }
      if (connectionState == "connected") {
        connectButtonState = CONNECT_BUTTON_STATE.CONNECTED_TO_DEVICE;
      } else if (connectionState == "connecting") {
        connectButtonState = CONNECT_BUTTON_STATE.CONNECTING_TO_DEVICE;
      }
      if (mounted) {
        setState(() {});
      }
    });
  }
}
