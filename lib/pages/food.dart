import 'package:flutter/material.dart';
class Food extends StatelessWidget {
  const Food({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: 
          Text(
            "This is the Food Page",
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    );
  }
}
