import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;

  const MyButton({super.key, this.onTap}); //Required onTap

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 150),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 174, 169, 169),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "Sign up",
            style: TextStyle(
              color: Color.fromARGB(255, 5, 5, 5),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
