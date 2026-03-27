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
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        ),
        title: Text(
          subcategoryName,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Center(child: Text(maincategoryName)),
    );
  }
}
