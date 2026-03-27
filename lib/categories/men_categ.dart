import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/subcateg_products.dart';
import 'package:multi_store_app/utilities/categ_list.dart';

class MenCategory extends StatelessWidget {
  const MenCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Text(
                      "Men",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.68,
                    child: GridView.count(
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 5,
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      children: List.generate(men.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubcategProducts(
                                  maincategoryName: 'men',
                                  subcategoryName: men[index],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              SizedBox(
                                height: 70,
                                width: 70,
                                child: Image(
                                  image: AssetImage('images/men/men$index.jpg'),
                                ),
                              ),
                              Text(men[index]),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.05,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          ' << ',
                          style: TextStyle(
                            color: Colors.brown,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 10,
                          ),
                        ),
                        Text(
                          'men'.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.brown,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 10,
                          ),
                        ),
                        Text(
                          ' >> '.toUpperCase(),
                          style: TextStyle(
                            color: Colors.brown,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
