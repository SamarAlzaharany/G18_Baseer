import 'dart:convert';

import 'package:baseerapp/Pages/SignupPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:baseerapp/pages/my_button.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import "package:http/http.dart" as http;
import 'HomePage.dart';
import 'HomePageAdmin.dart';
import 'components/my_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // sign user in method
  final client = http.Client();
  Future<void> signUserIn(context) async {
    final String email = emailController.text;
    final String password = passwordController.text;
    final uri;

    if (kIsWeb) {
      uri = Uri.parse(
          "http://127.0.0.1:13000/signin?email=$email&password=$password");
    } else {
      uri = Uri.parse(
          "http://10.0.2.2:13000/signin?email=$email&password=$password");
    }

    try {
      http.Response response = await client.post(uri);
      var decodedrespone = jsonDecode(response.body);
      if (decodedrespone['success']) {
        await SessionManager().set("email", email);
        await SessionManager().set("admin", decodedrespone['admin']);
        if (decodedrespone['admin'] == false) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()));
        } else {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePageAdmin()));
        }
      } else {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(title: Text(decodedrespone['message']));
            });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white70,
        body: SafeArea(
            child: Center(
          child: Column(children: [
            //empty space in the top
            const SizedBox(height: 150),
            
            const Text(
              'Sign In',
              style: TextStyle(
                  color: Color.fromARGB(235, 11, 11, 11),
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
            //empty space after "log in" text
            const SizedBox(height: 50),
            // email textfield
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
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: MyTextField(
                controller: emailController, //emailController
                hintText: '',
                obscureText: false,
              ),
            ),

            const SizedBox(height: 20),
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
                hintText: '',
                obscureText: true,
              ),
            ),

            const SizedBox(height: 15),
            // sign in button
            GestureDetector(
              onTap: () async {
                await signUserIn(context);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(50, 15, 50, 15),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Log In",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // sign up?
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Don't have an account?
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Color.fromARGB(235, 11, 11, 11),
                      fontSize: 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const SignupPage()));
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(50, 15, 50, 15),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        // color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("Sign UP",
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
