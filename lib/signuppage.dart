import 'email_field.dart';
import 'Log.dart';
import 'get_started_button.dart';
import 'password_field.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SigupPage extends StatefulWidget {
  const SigupPage({super.key});

  @override
  State<SigupPage> createState() => _SigupPageState();
}

class _SigupPageState extends State<SigupPage> {
  late TextEditingController emailController;
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late TextEditingController repeatpasswordController;

  double _elementsOpacity = 1;
  bool loadingBallAppear = false;
  double loadingBallSize = 1;
  @override
  void initState() {
    emailController = TextEditingController();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    repeatpasswordController = TextEditingController();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: loadingBallAppear
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: LoginScreen(),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 70),
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300),
                        tween: Tween(begin: 1, end: _elementsOpacity),
                        builder: (_, value, __) => Opacity(
                          opacity: value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 55),
                              Text(
                                "Sign in ",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(1),
                                    fontSize: 35),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 50),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            EmailField(
                              fadeEmail: _elementsOpacity == 0,
                              emailController: usernameController,
                              hinText: "Username",
                            ),
                            SizedBox(height: 40),
                            EmailField(
                              fadeEmail: _elementsOpacity == 0,
                              emailController: emailController,
                              hinText: "Email",
                            ),
                            SizedBox(height: 40),
                            PasswordField(
                                fadePassword: _elementsOpacity == 0,
                                passwordController: passwordController),
                            SizedBox(height: 40),
                            PasswordField(
                                fadePassword: _elementsOpacity == 0,
                                passwordController: repeatpasswordController),
                            SizedBox(height: 40),
                            GetStartedButton(
                              elementsOpacity: _elementsOpacity,
                              TEXT: "GetStarted",
                              onTap: () async {
                                String url =
                                    'https://server---app-d244e2f2d7c9.herokuapp.com/CoachSignup';
                                String username = usernameController.text;
                                String password = passwordController.text;
                                String confirm = repeatpasswordController.text;
                                String email = emailController.text;
                                if (password == confirm) {
                                  try {
                                    http.Response response = await http.get(
                                        Uri.parse(
                                            '$url?userName=$username&password=$password'));

                                    if (response.statusCode == 200) {
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  LoginScreen()));
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                                'Error: ${response.statusCode}'),
                                            content: Text(''),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      print('Error: ${response.statusCode}');
                                    }
                                  } catch (error) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Error: $error'),
                                          content: Text(''),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    print('Error: $error');
                                  }
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Password Mismatch'),
                                        content:
                                            Text('The passwords do not match.'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              onAnimatinoEnd: () async {
                                await Future.delayed(
                                    Duration(milliseconds: 500));
                                setState(() {
                                  loadingBallAppear = true;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
