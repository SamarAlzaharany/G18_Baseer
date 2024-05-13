import 'dart:convert';

import 'package:baseerapp/Pages/LoginPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_application_499/Pages/LoginPage.dart';
import 'package:baseerapp/pages/my_button.dart';
import 'package:baseerapp/pages/components/my_textfield.dart';
import 'package:flutter/widgets.dart';
import "package:http/http.dart" as http;

final nameController = TextEditingController();
final emailController = TextEditingController();
final passwordController = TextEditingController();
final confirmpasswordController = TextEditingController();

final client = http.Client();

Future<void> signup(context) async {
  final String name = nameController.text;
  final String email = emailController.text;
  final String password = passwordController.text;
  final String confirmpassword = confirmpasswordController.text;
  final uri;
  if (kIsWeb) {
    uri = Uri.parse(
        "http://127.0.0.1:13000/signup?name=$name&email=$email&password=$password&confirmpassword=$confirmpassword");
  } else {
    uri = Uri.parse(
        "http://10.0.2.2:13000/signup?name=$name&email=$email&password=$password&confirmpassword=$confirmpassword");
  }
 
  try {
    http.Response response = await client.post(uri);
    var decodedrespone = jsonDecode(response.body);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(title: Text(decodedrespone['message']));
        });
  } on Exception catch (_) {
    showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
              title: Text(
                  '404 , unable to establish connection with server, check internet , make sure the server (python file) is running , type http://127.0.0.1:13000'));
        });
    return;
  }
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  // text editing controllers

  // sign user in method
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white70,
        body: SafeArea(
            child: Center(
          child: Column(children: [
            // sign in button

            //empty space in the top
            const SizedBox(height: 80),

            //Log In Text title
            const Text(
              'Sign Up',
              style: TextStyle(
                  color: Color.fromARGB(235, 11, 11, 11),
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
            //empty space after "sign in" text
            const SizedBox(height: 25),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 450,
                    child: Text(
                      'Name',
                      style: TextStyle(
                          color: Color.fromARGB(235, 11, 11, 11),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            const SizedBox(height: 10),
            // name textfield
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: MyTextField(
                controller: nameController, //nameController
                hintText: 'Name',
                obscureText: false,
              ),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 450,
                    child: Text(
                      'Email',
                      style: TextStyle(
                          color: Color.fromARGB(235, 11, 11, 11),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            const SizedBox(height: 10),
            // email textfield
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: MyTextField(
                controller: emailController, //emailController
                hintText: 'Email',
                obscureText: false,
              ),
            ),

            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 450,
                    child: Text(
                      'Password',
                      style: TextStyle(
                          color: Color.fromARGB(235, 11, 11, 11),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            const SizedBox(height: 10),
            // password textfield
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: MyTextField(
                controller: passwordController, //passwordController
                hintText: 'Password',
                obscureText: true,
              ),
            ),

            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 450,
                    child: Text(
                      'Password',
                      style: TextStyle(
                          color: Color.fromARGB(235, 11, 11, 11),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            const SizedBox(height: 10),
            // confirm password textfield
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: MyTextField(
                controller:
                    confirmpasswordController, //confirmpasswordController
                hintText: 'Confirm Password',
                obscureText: true,
              ),
            ),

            const SizedBox(height: 25),
            //signup button

            GestureDetector(
              onTap: () async {
                await signup(context);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(50, 15, 50, 15),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Sign UP",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // MyButton(),

            // login?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Don't have an account?
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Color.fromARGB(235, 11, 11, 11),
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const LoginPage()));
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(50, 15, 50, 15),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        // color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("Sign In",
                          style: TextStyle(
                              color: Colors.red[400],
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        )));
  }
}
