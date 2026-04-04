import 'package:flutter/material.dart';

class AppbarBackButton extends StatelessWidget {
  const AppbarBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
    );
  }
}

class AppbarTitle extends StatelessWidget {
  const AppbarTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Acme',
        fontSize: 28,
        letterSpacing: 1.5,
      ),
    );
  }
}

class YellowBackButton extends StatelessWidget {
  const YellowBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.yellow),
    );
  }
}
