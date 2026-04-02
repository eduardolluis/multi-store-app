import 'package:flutter/material.dart';
import 'package:multi_store_app/utilities/categ_list.dart';
import 'package:multi_store_app/widgets/categ_widgets.dart';

class AccessoriesCategory extends StatelessWidget {
  const AccessoriesCategory({super.key});

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
                  const CategoryHeaderLabel(headerLabel: "Accessories"),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.68,
                    child: GridView.count(
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 5,
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      children: List.generate(accessories.length - 1, (index) {
                        return SubCategoryModel(
                          mainCategoryName: 'accessories',
                          subCategoryName: accessories[index + 1],
                          assetName: 'images/accessories/accessories$index',
                          subCategorLabel: accessories[index + 1],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            right: 0,
            child: Slidebar(mainCategoryName: 'Accessories'),
          ),
        ],
      ),
    );
  }
}
