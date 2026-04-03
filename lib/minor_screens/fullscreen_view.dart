import 'package:flutter/material.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';

class FullScreenView extends StatefulWidget {
  final List<dynamic> imagesList;
  const FullScreenView({super.key, required this.imagesList});

  @override
  State<FullScreenView> createState() => _FullScreenViewState();
}

class _FullScreenViewState extends State<FullScreenView> {
  int index = 0;
  final PageController _pageController = PageController();
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: AppbarBackButton(),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Center(
              child: Text(
                ('${index + 1}') +
                    ('/') +
                    (widget.imagesList.length.toString()),
                style: TextStyle(fontSize: 24, letterSpacing: 8),
              ),
            ),
            SizedBox(
              height: size.height * 0.5,

              child: PageView(
                onPageChanged: (value) {
                  setState(() {
                    index = value;
                  });
                },
                controller: _pageController,
                children: images(),
              ),
            ),
            SizedBox(height: size.height * 0.2, child: imageView()),
          ],
        ),
      ),
    );
  }

  Widget imageView() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.imagesList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _pageController.jumpToPage(index);
          },
          child: Container(
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
          ),
        );
      },
    );
  }

  List<Widget> images() {
    return List.generate(widget.imagesList.length, (index) {
      return InteractiveViewer(
        transformationController: TransformationController(),
        child: Image(image: NetworkImage(widget.imagesList[index].toString())),
      );
    });
  }
}
