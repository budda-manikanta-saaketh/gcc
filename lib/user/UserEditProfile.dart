import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gcc/utils/hexcolor.dart';
import 'package:image_picker/image_picker.dart';

class UserEditProfile extends StatefulWidget {
  UserEditProfile({super.key});

  @override
  State<UserEditProfile> createState() => _UserEditProfileState();
}

class _UserEditProfileState extends State<UserEditProfile> {
  List<XFile>? images = [];
  List<String> items = [];
  int flag = 0;
  String? itemtype;
  String? useremail = FirebaseAuth.instance.currentUser?.email;
  TextEditingController _fullname = TextEditingController();
  TextEditingController _phonenumber = TextEditingController();
  TextEditingController _email = TextEditingController();
  String dropdownValue = "Male";

  late List<String> downloadurls;
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  @override
  void dispose() {
    _fullname.dispose();
    _phonenumber.dispose();
    super.dispose();
  }

  void _getUserInfo() async {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    final userinfo = await FirebaseFirestore.instance
        .collection("Users")
        .doc(userEmail)
        .collection("userinfo")
        .doc("userinfo")
        .get();
    _fullname.text = userinfo["Full Name"];
    _phonenumber.text = userinfo["Phone Number"];
    _email.text = userinfo["email"];
    dropdownValue = userinfo["Gender"];
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
    final urls = <String>[];

    try {
      for (var image in images) {
        final imageRef = storageRef
            .child('images/${DateTime.now()}.${image.name.split('.').last}');
        final uploadTask = imageRef.putFile(File(image.path));

        final snapshot = await uploadTask;
        final downloadURL = await snapshot.ref.getDownloadURL();
        urls.add(downloadURL);
      }

      return urls;
    } catch (error) {
      print('Error uploading images: $error');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      bottomNavigationBar: GestureDetector(
        onTap: () async {
          setState(() {
            _isUploading = true;
          });
          try {
            String? userEmail = FirebaseAuth.instance.currentUser?.email;
            downloadurls = await uploadImages(images!);
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userEmail)
                .collection('userinfo')
                .doc('userinfo')
                .update({
              'Profile Image': downloadurls,
              'Full Name': _fullname.text,
              'Phone Number': _phonenumber.text,
              'Gender': dropdownValue,
            }).then((value) {
              _showDocumentIdPopup2(
                  "Details Added Successfully", 'Upload Successful');
            });
          } catch (e) {
            print(e);
          } finally {
            setState(() {
              _isUploading = false;
            });
          }
        },
        child: Container(
            height: 70,
            color: HexColor("#007E03"),
            child: const Center(
              child: Text(
                "Upload",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )),
      ),
      appBar: AppBar(
        titleSpacing: -5,
        title: const Text("Profile Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
              fontSize: 20,
            )),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: HexColor("#007E03"),
      ),
      backgroundColor: Colors.white,
      body: _isUploading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: SafeArea(
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
                                              child: Text("Profile Photo",
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
                                              child: Text("Profile Photo",
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
                          "Full name",
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
                            controller: _fullname,
                            decoration: InputDecoration(
                              hintText: 'Enter Your Full Name',
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
                          "Phone Number",
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
                            controller: _phonenumber,
                            decoration: InputDecoration(
                              hintText: 'Enter Your Phone Number',
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
                          "Gender",
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
                          items: <String>['Male', 'Female']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
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
        if (images!.length < 1) {
          images = [...?images, pickedImage];
        } else {
          images = [pickedImage];
        }
      });
    }
  }
}
