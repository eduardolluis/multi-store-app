import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/inapp/bgimage.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        constraints: BoxConstraints.expand(),
        child: SafeArea(
          child: Column(
            children: [
              Text(
                'WELCOME',
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
              SizedBox(
                height: 120,
                width: 200,
                child: const Image(image: AssetImage('images/inapp/logo.jpg')),
              ),
              Text('SHOP', style: TextStyle(color: Colors.white, fontSize: 30)),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    "Suppliers only",
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 60,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image(image: AssetImage('images/inapp/logo.jpg')),
                    YellowButton(
                      label: 'Log In',
                      onPressed: () {},
                      width: 0.25,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: YellowButton(
                        label: 'Sign Up',
                        onPressed: () {},
                        width: 0.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 60,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: YellowButton(
                        label: 'Log In',
                        onPressed: () {},
                        width: 0.25,
                      ),
                    ),
                    YellowButton(
                      label: 'Sign Up',
                      onPressed: () {},
                      width: 0.25,
                    ),
                    Image(image: AssetImage('images/inapp/logo.jpg')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
