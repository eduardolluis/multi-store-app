import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';

class EditStore extends StatefulWidget {
  final dynamic data;
  const EditStore({super.key, required this.data});

  @override
  State<EditStore> createState() => _EditStoreState();
}

class _EditStoreState extends State<EditStore> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFileLogo;
  dynamic _pickedImageError;

  void pickStoreLogo() async {
    try {
      final pickedStoreLogo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 300,
        maxWidth: 300,
        imageQuality: 95,
      );
      setState(() {
        _imageFileLogo = pickedStoreLogo;
      });
    } catch (e) {
      setState(() {
        _pickedImageError = e;
      });
      print(_pickedImageError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: const AppbarBackButton(),
        backgroundColor: Colors.white,
        centerTitle: true,
        title: AppbarTitle(title: 'Edit Store'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            "Store Logo",
            style: TextStyle(fontSize: 24, color: Colors.blueGrey, fontWeight: FontWeight.w600),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CircleAvatar(radius: 60, backgroundImage: NetworkImage(widget.data['storeLogo'])),
              YellowButton(
                label: 'Change',
                onPressed: () {
                  pickStoreLogo();
                },
                width: 0.25,
              ),
              const SizedBox(height: 10),
              _imageFileLogo == null
                  ? const SizedBox()
                  : YellowButton(
                      label: 'Reset',
                      onPressed: () {
                        setState(() {
                          _imageFileLogo = null;
                        });
                      },
                      width: 0.25,
                    ),
              _imageFileLogo == null
                  ? const SizedBox()
                  : CircleAvatar(
                      radius: 60,
                      backgroundImage: FileImage(File(_imageFileLogo!.path)),
                    ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Divider(color: Colors.yellow, thickness: 2.5),
          ),
        ],
      ),
    );
  }
}
