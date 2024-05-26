import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Log.dart';

class MyAppModel extends ChangeNotifier {}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MyAppModel(),
      child: MyApp(),
    ),
  );
}

final TextEditingController usernameController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitor',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
