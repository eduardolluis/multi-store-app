import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class FullScreenView extends StatefulWidget {
  final List<dynamic> imagesList;
  const FullScreenView({super.key, required this.imagesList});

  @override
  State<FullScreenView> createState() => _FullScreenViewState();
}

class _FullScreenViewState extends State<FullScreenView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: AppbarBackButton(),
      ),
      body: Column(
        children: [
          Center(
            child: Text(
              "1/5",
              style: TextStyle(fontSize: 24, letterSpacing: 8),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: PageView(
              children: List.generate(widget.imagesList.length, (index) {
                return InteractiveViewer(
                  transformationController: TransformationController(),
                  child: Image(
                    image: NetworkImage(widget.imagesList[index].toString()),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.imagesList.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 130,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(width: 4, color: Colors.yellow),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),

                    child: Image.network(
                      widget.imagesList[index].toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
