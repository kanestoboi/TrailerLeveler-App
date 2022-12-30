import 'package:flutter/material.dart';

import 'package:trailer_leveler_app/angles_page.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  runApp(const MyApp());
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
