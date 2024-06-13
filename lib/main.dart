// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:whois_app/pages/home_screen.dart';

/// Entry point of the application
void main() {
  runApp(MyApp());
}

/// Main widget of the application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WHOIS Lookup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        hintColor: Colors.lightBlueAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}
