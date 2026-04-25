import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_store_app/widgets/appbar_widgets.dart';
import 'package:multi_store_app/widgets/snackbar_widget.dart';
import 'package:multi_store_app/widgets/yellow_button_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditStore extends StatefulWidget {
  final dynamic data;
  const EditStore({super.key, required this.data});

  @override
  State<EditStore> createState() => _EditStoreState();
}

class _EditStoreState extends State<EditStore> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFileLogo;
  XFile? _imageFileCover;
  dynamic _pickedImageError;

  late String storeName;
  late String phoneNumber;

  bool _isLoading = false; // Para mostrar un indicador mientras se guarda

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

  void pickCoverImage() async {
    try {
      final pickedCoverImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 300,
        maxWidth: 300,
        imageQuality: 95,
      );
      setState(() {
        _imageFileCover = pickedCoverImage;
      });
    } catch (e) {
      setState(() {
        _pickedImageError = e;
      });
      print(_pickedImageError);
    }
  }

  // Sube una imagen a Supabase Storage y retorna la URL pública
  Future<String?> _uploadImage(XFile imageFile, String folder) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final supabase = Supabase.instance.client;

      final fileName = '${folder}_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('images').upload(fileName, File(imageFile.path));

      // Obtener la URL pública del archivo subido
      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading $folder: $e');
      return null;
    }
  }

  void saveChanges() async {
    if (!formkey.currentState!.validate()) {
      MyMessageHandler.showSnackBar(scaffoldKey, "Please fill all fields");
      return;
    }

    formkey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final supabase = Supabase.instance.client;

      // URLs finales: si el usuario cambió la imagen, subir la nueva; si no, mantener la actual
      String logoUrl = widget.data['storeLogo'];
      String coverUrl = widget.data['coverImage'];

      if (_imageFileLogo != null) {
        final newLogoUrl = await _uploadImage(_imageFileLogo!, 'logo');
        if (newLogoUrl != null) logoUrl = newLogoUrl;
      }

      if (_imageFileCover != null) {
        final newCoverUrl = await _uploadImage(_imageFileCover!, 'cover');
        if (newCoverUrl != null) coverUrl = newCoverUrl;
      }

      // Actualizar los datos en la tabla de Supabase
      // Cambia 'stores' por el nombre real de tu tabla
      await supabase
          .from('stores')
          .update({
            'storeName': storeName,
            'phone': phoneNumber,
            'storeLogo': logoUrl,
            'coverImage': coverUrl,
          })
          .eq('supplierId', uid);

      MyMessageHandler.showSnackBar(scaffoldKey, "Changes saved successfully!");

      // Esperar un momento para que el usuario vea el mensaje antes de salir
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error saving changes: $e');
      MyMessageHandler.showSnackBar(scaffoldKey, "Error saving changes, try again");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: const AppbarBackButton(),
          backgroundColor: Colors.white,
          centerTitle: true,
          title: AppbarTitle(title: 'Edit Store'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: formkey,
                child: SingleChildScrollView(
                  // Añadido para evitar overflow
                  child: Column(
                    children: [
                      // --- STORE LOGO ---
                      Column(
                        children: [
                          Text(
                            "Store Logo",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: NetworkImage(widget.data['storeLogo']),
                              ),
                              Column(
                                children: [
                                  YellowButton(
                                    label: 'Change',
                                    onPressed: pickStoreLogo,
                                    width: 0.25,
                                  ),
                                  const SizedBox(height: 10),
                                  if (_imageFileLogo != null)
                                    YellowButton(
                                      label: 'Reset',
                                      onPressed: () => setState(() => _imageFileLogo = null),
                                      width: 0.25,
                                    ),
                                ],
                              ),
                              if (_imageFileLogo != null)
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: FileImage(File(_imageFileLogo!.path)),
                                )
                              else
                                const SizedBox(width: 60),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Divider(color: Colors.yellow, thickness: 2.5),
                          ),
                        ],
                      ),

                      // --- COVER IMAGE ---
                      Column(
                        children: [
                          Text(
                            "Cover Image",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: NetworkImage(widget.data['coverImage']),
                              ),
                              Column(
                                children: [
                                  YellowButton(
                                    label: 'Change',
                                    onPressed: pickCoverImage,
                                    width: 0.25,
                                  ),
                                  const SizedBox(height: 10),
                                  if (_imageFileCover != null)
                                    YellowButton(
                                      label: 'Reset',
                                      onPressed: () => setState(() => _imageFileCover = null),
                                      width: 0.25,
                                    ),
                                ],
                              ),
                              if (_imageFileCover != null)
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: FileImage(File(_imageFileCover!.path)),
                                )
                              else
                                const SizedBox(width: 60),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Divider(color: Colors.yellow, thickness: 2.5),
                          ),
                        ],
                      ),

                      // --- FORM FIELDS ---
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) return 'Store name cannot be empty';
                            return null;
                          },
                          onSaved: (value) => storeName = value!,
                          initialValue: widget.data['storeName'],
                          decoration: textFormDecor.copyWith(
                            label: const Text('Store Name'),
                            hintText: 'Enter store name',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) return 'Phone number cannot be empty';
                            return null;
                          },
                          onSaved: (value) => phoneNumber = value!,
                          initialValue: widget.data['phone'],
                          decoration: textFormDecor.copyWith(
                            label: const Text('Phone'),
                            hintText: 'Enter phone number',
                          ),
                        ),
                      ),

                      // --- BUTTONS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            YellowButton(
                              label: 'Cancel',
                              onPressed: () => Navigator.pop(context),
                              width: 0.25,
                            ),
                            YellowButton(label: 'Save Changes', onPressed: saveChanges, width: 0.5),
                          ],
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

var textFormDecor = InputDecoration(
  labelStyle: const TextStyle(color: Colors.purple),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.yellow, width: 1),
    borderRadius: BorderRadius.circular(10),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
    borderRadius: BorderRadius.circular(10),
  ),
);
