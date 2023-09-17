import 'package:flutter/material.dart';
import 'package:trailer_leveler_app/bluetooth_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
                  "Settings",
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
              const Column(
                children: [],
              ),
            ],
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
                visible: true,
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
}
