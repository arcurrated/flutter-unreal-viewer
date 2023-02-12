import 'package:flutter/material.dart';
import 'view/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp( //use MaterialApp() widget like this
        home: HomePage() //create new widget class for this 'home' to
      // escape 'No MediaQuery widget found' error
    );
  }
}