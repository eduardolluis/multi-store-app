import 'package:flutter/material.dart';

class SubcategProducts extends StatelessWidget {
  final String maincategoryName;
  final String subcategoryName;
  const SubcategProducts({
    super.key,
    required this.subcategoryName,
    required this.maincategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: AppbarTitle(title: subcategoryName),
      ),
      body: Center(child: Text(maincategoryName)),
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
