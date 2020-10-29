import 'package:flutter/material.dart';
import 'package:google_maps_in_flutter/home_map.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps',
      home: HomeMap(),
    );
  }
}
