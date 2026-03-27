import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/subcateg_products.dart';

class Slidebar extends StatelessWidget {
  final String mainCategoryName;
  const Slidebar({super.key, required this.mainCategoryName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  mainCategoryName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.brown,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 10,
                  ),
                ),
                Text(
                  ' >> ',
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
    );
  }
}

class SubCategoryModel extends StatelessWidget {
  final String mainCategoryName;
  final String subCategoryName;
  final String assetName;
  final String subCategorLabel;

  const SubCategoryModel({
    super.key,
    required this.mainCategoryName,
    required this.subCategoryName,
    required this.assetName,
    required this.subCategorLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubcategProducts(
              maincategoryName: mainCategoryName,
              subcategoryName: subCategoryName,
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
              image: AssetImage('images/men/$assetName.jpg'),
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, size: 40);
              },
            ),
          ),
          Text(subCategorLabel),
        ],
      ),
    );
  }
}

class CategoryHeaderLabel extends StatelessWidget {
  final String headerLabel;
  const CategoryHeaderLabel({super.key, required this.headerLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Text(
        headerLabel,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
