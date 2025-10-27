import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gcc/utils/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class UploadFood extends StatefulWidget {
  const UploadFood({super.key});

  @override
  State<UploadFood> createState() => _UploadFoodState();
}

class _UploadFoodState extends State<UploadFood> {
  List<XFile>? images = [];
  List<String> items = [];
  String? itemtype;
  String? useremail = FirebaseAuth.instance.currentUser?.email;
  TextEditingController search = TextEditingController();
  final TextEditingController _itemname = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _consistsof = TextEditingController();
  final TextEditingController _itemdescription = TextEditingController();
  final TextEditingController _size = TextEditingController();
  final TextEditingController _availablequantity = TextEditingController();
  String dropdownValue = 'Kgs';

  late List<String> downloadurls;
  bool _isUploading = false;
  @override
  void initState() {
    create_list();
    super.initState();
  }

  @override
  void dispose() {
    search.dispose();
    _itemname.dispose();
    _price.dispose();
    _consistsof.dispose();
    _itemdescription.dispose();
    super.dispose();
  }

  void _showDocumentIdPopup(String documentId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(documentId),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _showDocumentIdPopup2(String documentId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(documentId),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> uploadImages(List<XFile> images) async {
    final storageRef = FirebaseStorage.instance.ref();
    final urls = <String>[]; // Create a list to store the download URLs

    try {
      for (var image in images) {
        final imageRef = storageRef
            .child('images/${DateTime.now()}.${image.name.split('.').last}');
        final uploadTask = imageRef.putFile(File(image.path));

        final snapshot = await uploadTask;
        final downloadURL = await snapshot.ref.getDownloadURL();
        urls.add(downloadURL); // Add the download URL to the list
      }

      return urls; // Return the list of download URLs
    } catch (error) {
      print('Error uploading images: $error');
      rethrow; // Rethrow the error to be handled by the caller
    }
  }

  void create_list() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('Categories').get();

      final List<String> categoryNames = querySnapshot.docs
          .where((doc) => doc.data().containsKey('Name'))
          .map((doc) => doc['Name'].toString())
          .where((name) => name.isNotEmpty)
          .toList();

      setState(() {
        items = categoryNames;
      });
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: GestureDetector(
          onTap: () async {
            setState(() {
              _isUploading =
                  true; // Start the upload and show progress indicator
            });

            try {
              downloadurls = await uploadImages(images!);
              final docRef =
                  FirebaseFirestore.instance.collection('Products').doc();
              final productId = docRef.id;
              await docRef.set({
                'product_Id': productId,
                'product_Name': _itemname.text,
                'product_Category': itemtype,
                'price': double.parse(_price.text),
                'consists': _consistsof.text,
                'product_Description': _itemdescription.text,
                'size': _size.text,
                'createdOn': DateTime.now(),
                'available_Quantity': int.parse(_availablequantity.text),
                'images': downloadurls,
                'user_Email': useremail,
                'total_Rating': 0,
                'rating_Count': 0,
              }).then((value) {
                _showDocumentIdPopup2(
                    "Item Added Successfully", 'Upload Successful');
              });
            } catch (e) {
              print(e); // Handle or log error
            } finally {
              setState(() {
                _isUploading =
                    false; // Hide progress indicator once upload is complete
              });
            }
          },
          child: Container(
            height: 60,
            color: HexColor("#007E03"),
            child: const Center(
              child: Text(
                "Upload",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        appBar: AppBar(
          titleSpacing: -5,
          title: const Text("Upload Product",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: 20,
              )),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.green,
        ),
        backgroundColor: Colors.white,
        body: _isUploading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    images!.isEmpty
                        ? Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.04,
                              top: width * 0.02,
                              right: width * 0.04,
                            ),
                            child: Container(
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 255, 237, 222),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                height: width * 0.78,
                                child: Stack(
                                  children: [
                                    Positioned(
                                        child: Container(
                                      decoration: BoxDecoration(
                                        color: HexColor('#2A2828'),
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10)),
                                      ),
                                      height: width * 0.10,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                              top: width * 0.02,
                                              left: width * 0.03,
                                              child: Text("Product Photos",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w600))),
                                          Positioned(
                                              right: width * 0.03,
                                              top: width * 0.02,
                                              child: GestureDetector(
                                                onTap: () {
                                                  pickImages();
                                                },
                                                child: Text("Edit",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Roboto',
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              )),
                                        ],
                                      ),
                                    )),
                                    Positioned(
                                        top: width * 0.35,
                                        left: width * 0.33,
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                pickImages();
                                              },
                                              child: Image.asset(
                                                'assets/images/Addphoto2.png',
                                                width: width * 0.13,
                                                height: width * 0.13,
                                              ),
                                            ),
                                            Text(
                                              "Click to Add Photo",
                                              style: TextStyle(
                                                fontSize: width * 0.03,
                                                color: Colors.black38,
                                              ),
                                            ),
                                          ],
                                        )),
                                    Positioned(
                                        bottom: width * 0.02,
                                        left: width * 0.02,
                                        child: GestureDetector(
                                            onTap: () {
                                              _pickImageFromCamera();
                                            },
                                            child: FaIcon(
                                                FontAwesomeIcons.camera,
                                                size: width * 0.06)))
                                  ],
                                )),
                          )
                        : Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.04,
                              top: width * 0.02,
                              right: width * 0.04,
                            ),
                            child: Container(
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 255, 249, 222),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                height: width * 0.78,
                                child: Stack(
                                  children: [
                                    Positioned(
                                        child: Container(
                                      decoration: BoxDecoration(
                                        color: HexColor('#2A2828'),
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            topRight: Radius.circular(10)),
                                      ),
                                      height: width * 0.10,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                              top: width * 0.02,
                                              left: width * 0.03,
                                              child: Text(
                                                  "Product Photos (${images!.length}/4)",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Roboto',
                                                      fontWeight:
                                                          FontWeight.w600))),
                                          Positioned(
                                              right: width * 0.03,
                                              top: width * 0.02,
                                              child: GestureDetector(
                                                onTap: () {
                                                  pickImages();
                                                },
                                                child: Text("Edit",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Roboto',
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              )),
                                        ],
                                      ),
                                    )),
                                    Padding(
                                      padding:
                                          EdgeInsets.only(top: width * 0.1),
                                      child: Container(
                                        child: Center(
                                            child: PageView.builder(
                                                itemCount: images!.length,
                                                itemBuilder: (context, index) {
                                                  return Container(
                                                      child: Image.file(File(
                                                          images![index]
                                                              .path)));
                                                })),
                                      ),
                                    ),
                                    Positioned(
                                        bottom: width * 0.02,
                                        left: width * 0.02,
                                        child: GestureDetector(
                                            onTap: () {
                                              _pickImageFromCamera();
                                            },
                                            child: FaIcon(
                                                FontAwesomeIcons.camera,
                                                size: width * 0.06)))
                                  ],
                                )),
                          ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Item name",
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.02,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: width * 0.04, left: width * 0.04),
                          child: TextField(
                            controller: _itemname,
                            decoration: InputDecoration(
                              hintText: 'Enter the Item Name',
                              hintStyle: TextStyle(fontSize: 14.0),
                              contentPadding: const EdgeInsets.only(
                                left: 5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Item Category",
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.03,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            hint: Text(
                              'Select Category',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                            items: items
                                .map((item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            value: itemtype,
                            onChanged: (value) {
                              setState(() {
                                itemtype = value;
                              });
                            },
                            buttonStyleData: const ButtonStyleData(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              height: 40,
                              width: 200,
                            ),
                            dropdownStyleData: const DropdownStyleData(
                              maxHeight: 200,
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 40,
                            ),
                            dropdownSearchData: DropdownSearchData(
                              searchController: search,
                              searchInnerWidgetHeight: 50,
                              searchInnerWidget: Container(
                                height: 50,
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 4,
                                  right: 8,
                                  left: 8,
                                ),
                                child: TextFormField(
                                  expands: true,
                                  maxLines: null,
                                  controller: search,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    hintText: 'Search for an item...',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              searchMatchFn: (item, searchValue) {
                                return item.value
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchValue.toLowerCase());
                              },
                            ),
                            //This to clear the search value when you close the menu
                            onMenuStateChange: (isOpen) {
                              if (!isOpen) {
                                search.clear();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Price",
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.02,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: width * 0.04, left: width * 0.04),
                          child: TextField(
                            controller: _price,
                            decoration: InputDecoration(
                              hintText: 'Enter The Price Of The Item',
                              hintStyle: TextStyle(fontSize: 14.0),
                              contentPadding: const EdgeInsets.only(
                                left: 5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Type",
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.07,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<String>(
                          value: dropdownValue,
                          icon: const Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                          elevation: 16,
                          dropdownColor: Colors.white,
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownValue = newValue!;
                            });
                          },
                          items: <String>['Kgs', 'Grams', 'Litres', 'ML']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Item Description",
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.02,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: width * 0.04,
                            left: width * 0.04,
                          ),
                          child: SizedBox(
                            width: width,
                            height: 100,
                            child: TextFormField(
                              controller: _itemdescription,
                              decoration: InputDecoration(
                                hintText: 'Enter The Item Description',
                                hintStyle: TextStyle(fontSize: 14.0),
                                contentPadding: const EdgeInsets.only(
                                  left: 5,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              maxLines: null,
                              expands: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Size",
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.02, bottom: width * 0.02),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: width * 0.04, left: width * 0.04),
                          child: TextField(
                            controller: _size,
                            decoration: InputDecoration(
                              hintText: 'Enter The Size',
                              hintStyle: TextStyle(fontSize: 14.0),
                              contentPadding: const EdgeInsets.only(
                                left: 5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: width * 0.06,
                        top: width * 0.024,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Available Quantity",
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: width * 0.02, bottom: width * 0.02),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: width * 0.04, left: width * 0.04),
                          child: TextField(
                            controller: _availablequantity,
                            decoration: InputDecoration(
                              hintText: 'Enter The Availability Quantity',
                              hintStyle: TextStyle(fontSize: 14.0),
                              contentPadding: const EdgeInsets.only(
                                left: 5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

//multiple image picker function from gallery
  Future<void> pickImages() async {
    final pickedImages = await ImagePicker().pickMultiImage();
    final limitedImages = pickedImages.take(1).toList();
    setState(() {
      if (images!.length < 2 && (images!.length + limitedImages.length) <= 2) {
        images = [...?images, ...limitedImages];
      } else {
        images = [...limitedImages];
      }
    });
  }

//multiple image picker function from camera
  Future _pickImageFromCamera() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        if (images!.isEmpty) {
          images = [...?images, pickedImage];
        } else {
          images = [pickedImage];
        }
      });
    }
  }
}
