import 'package:flutter/widgets.dart';
import 'signuppage.dart';
import 'email_field.dart';
import 'mainpage.dart';
import 'get_started_button.dart';
import 'password_field.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  double _elementsOpacity = 1;
  bool loadingBallAppear = false;
  double loadingBallSize = 1;
  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();

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
                              emailController: emailController,
                              hinText: "Username",
                            ),
                            SizedBox(height: 40),
                            PasswordField(
                                fadePassword: _elementsOpacity == 0,
                                passwordController: passwordController),
                            SizedBox(height: 60),
                            Column(children: [
                              GetStartedButton(
                                TEXT: "GetStarted",
                                elementsOpacity: _elementsOpacity,
                                onTap: () async {
                                  String user = emailController.text;
                                  String pass = passwordController.text;
                                  String url =
                                      'https://server---app-d244e2f2d7c9.herokuapp.com/CoachLogin/';

                                  try {
                                    http.Response response = await http.get(
                                        Uri.parse(
                                            '$url?userName=$user&password=$pass'));

                                    if (response.statusCode == 200) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MainPage(
                                              username: user,
                                              responseBody: response.body),
                                        ),
                                      );
                                    } else if (response.statusCode == 404) {
                                      print("No user found.");
                                    } else {
                                      print('Error: ${response.statusCode}');
                                    }
                                  } catch (error) {
                                    print('Error: $error');
                                  }
                                  setState(() {
                                    _elementsOpacity = 0;
                                  });
                                },
                                onAnimatinoEnd: () async {
                                  await Future.delayed(
                                      Duration(milliseconds: 500));
                                  setState(() {
                                    loadingBallAppear = true;
                                  });
                                },
                              ),
                              SizedBox(height: 10),
                              GetStartedButton(
                                TEXT: "SignUp",
                                elementsOpacity: _elementsOpacity,
                                onTap: () async {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SigupPage(),
                                    ),
                                  );
                                },
                                onAnimatinoEnd: () async {
                                  await Future.delayed(
                                      Duration(milliseconds: 500));
                                  setState(() {
                                    loadingBallAppear = true;
                                  });
                                },
                              )
                            ]),
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
