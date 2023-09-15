import 'package:flutter/material.dart';
import 'package:trailer_leveler_app/bluetooth_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<bool> angleDataSource = [
    BluetoothBloc.instance.anglesCalculationSource ==
        ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_DEVICE,
    BluetoothBloc.instance.anglesCalculationSource ==
        ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_PHONE,
  ]; //[0] = save to device, [1] = save to phone
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
              Column(
                children: [
                  const Text(
                    "Select where to store data",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 1,
                      fontSize: 20,
                      color: Colors.black54,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  toggleDataSourceWidget()
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildToggleButtons() {
    return [
      ElevatedButton(
        onPressed: () {
          setState(() {
            angleDataSource = [true, false];
            BluetoothBloc.instance.setAnglesSource(
                ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_DEVICE);
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            angleDataSource[0] ? Colors.blue : Colors.grey,
          ),
        ),
        child: const Text('Save to Device'),
      ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            angleDataSource = [false, true];
            BluetoothBloc.instance.setAnglesSource(
                ANGLE_CALCULATION_SOURCE.ANGLES_CALCULATED_ON_PHONE);
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            angleDataSource[1] ? Colors.blue : Colors.grey,
          ),
        ),
        child: const Text('Save to Phone'),
      ),
    ];
  }

  Widget toggleDataSourceWidget() {
    return Center(
      child: ToggleButtons(
        color: Colors.transparent,
        selectedColor: Colors.transparent,
        fillColor: Colors.transparent,
        borderColor: Colors.transparent,
        selectedBorderColor: Colors.transparent,
        isSelected: angleDataSource,
        onPressed: (int index) {
          debugPrint("Data Source ${index}");

          setState(() {
            angleDataSource =
                List.generate(angleDataSource.length, (i) => i == index);
          });
        },
        children: _buildToggleButtons(),
      ),
    );
  }
}
