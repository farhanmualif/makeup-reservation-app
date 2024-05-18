import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

class AddPaketForm extends StatefulWidget {
  const AddPaketForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddPaketFormState createState() => _AddPaketFormState();
}

class _AddPaketFormState extends State<AddPaketForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController =
      TextEditingController(); // Added controller for description
  File? _imageFile;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _selectImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final imageTemp = File(image.path);
      setState(() => _imageFile = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate() && _imageFile != null) {
      final nama = _namaController.text;
      final harga = _hargaController.text;
      final deskripsi =
          _deskripsiController.text; // Get the description from the controller

      if (_imageFile == null) return;
      final fileName = path.basename(_imageFile!.path);
      final destination = 'files/$fileName';

      try {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref(destination)
            .child('file/');
        var uploadTask = ref.putFile(_imageFile!);
        var downloadUrl = await (await uploadTask).ref.getDownloadURL();
        // Tambahkan data paket ke Cloud Firestore
        await _firestore.collection('paket_makeup').add({
          'Name': nama,
          'Price': harga,
          'Description': deskripsi,
          "Image": downloadUrl.toString()
        });

        // Reset form setelah berhasil menambahkan paket
        _formKey.currentState!.reset();
        _imageFile = null;
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paket berhasil ditambahkan'),
          ),
        );
      } catch (e) {
        if (e is FirebaseException) {
          final FirebaseException firebaseException = e;
          if (firebaseException.code == 'storage/unauthorized') {
            // Tampilkan pesan kesalahan yang sesuai untuk pengguna
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Anda tidak memiliki izin untuk mengunggah file.'),
              ),
            );
          } else {
            // Tampilkan pesan kesalahan umum
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Terjadi kesalahan saat mengunggah file.'),
              ),
            );
          }
        } else {
          // Tangani jenis kesalahan lainnya
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan yang tidak diketahui.'),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field dan pilih gambar'),
        ),
      );
    }
    setState(() {
      _isLoading = true;
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose(); // Dispose the description controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Paket'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _imageFile == null
                        ? const Center(
                            child: Text('Pilih Gambar'),
                          )
                        : Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Paket',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama Paket tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _hargaController,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller:
                      _deskripsiController, // Use the description controller
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      print("clicked");
                      _submitForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.black, // Warna latar belakang tombol
                      foregroundColor: Colors.white, // Warna teks tombol
                      minimumSize: const Size(288, 51), // Ukuran tombol
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Bentuk tombol
                      ),
                    ),
                    child: const Text('Tambah Paket'),
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
