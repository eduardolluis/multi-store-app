import 'package:flutter/material.dart';
import 'package:multi_store_app/customer_screens/customer_orders.dart';
import 'package:multi_store_app/customer_screens/customer_wishlist.dart';
import 'package:multi_store_app/main_screens/cart.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.yellow, Colors.brown]),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                centerTitle: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                expandedHeight: 140,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    return FlexibleSpaceBar(
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: constraints.biggest.height <= 120 ? 1 : 0,
                        child: const Text(
                          "Account",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.yellow, Colors.brown],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8, left: 30),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage(
                                  'images/inapp/guest.jpg',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 25),
                                child: const Text(
                                  "Guest",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CartScreen(back: AppbarBackButton()),
                                  ),
                                );
                              },
                              child: SizedBox(
                                height: 40,
                                width: MediaQuery.of(context).size.width * 0.2,
                                child: const Center(
                                  child: Text(
                                    'Cart',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.yellow,

                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerOrders(),
                                  ),
                                );
                              },
                              child: SizedBox(
                                height: 40,
                                width: MediaQuery.of(context).size.width * 0.2,
                                child: const Center(
                                  child: Text(
                                    'Orders',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerWishlist(),
                                  ),
                                );
                              },
                              child: SizedBox(
                                height: 40,
                                width: MediaQuery.of(context).size.width * 0.2,
                                child: const Center(
                                  child: Text(
                                    'WishList',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.grey[300],
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 150,
                            child: Image(
                              image: AssetImage('images/inapp/logo.jpg'),
                            ),
                          ),
                          ProfileHeaderLabel(headerLabel: "  Account Info  "),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              height: 260,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  RepeatedListTile(
                                    title: 'Email Address',
                                    subtitle: 'example@email.com',
                                    icon: Icons.email,
                                  ),
                                  YellowDivider(),
                                  RepeatedListTile(
                                    title: 'Phone No.',
                                    subtitle: '+1 234 421 132',
                                    icon: Icons.phone,
                                  ),
                                  YellowDivider(),
                                  RepeatedListTile(
                                    title: 'Address',
                                    subtitle: '123 Main Street, City, Country',
                                    icon: Icons.location_pin,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ProfileHeaderLabel(
                            headerLabel: "  Account Settings  ",
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              height: 260,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  RepeatedListTile(
                                    title: "Edit Profile",
                                    subtitle: "",
                                    icon: Icons.edit,
                                    onPressed: () {},
                                  ),
                                  YellowDivider(),
                                  RepeatedListTile(
                                    title: "Change Password",
                                    icon: Icons.lock,
                                    onPressed: () {},
                                  ),
                                  YellowDivider(),
                                  RepeatedListTile(
                                    title: "Log Out",
                                    icon: Icons.logout,
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/welcome_screen',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class YellowDivider extends StatelessWidget {
  const YellowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Divider(color: Colors.yellow, thickness: 1.2),
    );
  }
}

class RepeatedListTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Function()? onPressed;
  const RepeatedListTile({
    super.key,
    required this.title,
    this.subtitle = "",
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(icon),
      ),
    );
  }
}

class ProfileHeaderLabel extends StatelessWidget {
  final String headerLabel;
  const ProfileHeaderLabel({super.key, required this.headerLabel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
            width: 50,
            child: Divider(color: Colors.grey, thickness: 1),
          ),
          Text(
            headerLabel,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 40,
            width: 50,
            child: Divider(color: Colors.grey, thickness: 1),
          ),
        ],
      ),
    );
  }
}
