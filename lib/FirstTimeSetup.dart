import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeSetup extends StatefulWidget {
  @override
  _FirstTimeSetupState createState() => _FirstTimeSetupState();
}

class _FirstTimeSetupState extends State<FirstTimeSetup> {
  XFile? _image;

  // Méthode pour sélectionner une image depuis la galerie
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera); // Utilisation de la caméra pour la photo
    setState(() {
      _image = pickedFile;
    });
  }

  // Méthode pour enregistrer l'image
  Future<void> _saveImage() async {
    if (_image != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user_image', _image!.path); // Enregistre le chemin de l'image
      print("Image enregistrée à : ${_image!.path}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Première utilisation')),
      body: Column(
        children: [
          if (_image != null)
            Image.file(File(_image!.path)) // Affiche l'image sélectionnée
          else
            Text('Aucune image sélectionnée'),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Prendre une photo'),
          ),
          ElevatedButton(
            onPressed: _saveImage,
            child: Text('Enregistrer l\'image'),
          ),
        ],
      ),
    );
  }
}
