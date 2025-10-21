import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gcc/Admin/UploadProduct.dart';
import 'package:gcc/Admin/adminorders.dart';
import 'package:gcc/Admin/adminprofile.dart';
import 'package:gcc/Admin/adminrevenue.dart';
import 'package:gcc/Admin/mainadminhome.dart';
import 'package:gcc/utils/Notifications.dart';
import 'package:gcc/utils/hexcolor.dart';

class AdminHome extends StatefulWidget {
  final int initialSelectedIndex;
  const AdminHome({super.key, required this.initialSelectedIndex});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with TickerProviderStateMixin {
  late PageController _pageController;
  int _selectedIndex = 0;
  late final int initialSelectedIndex;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    updateToken();
    getnotificationpermission();
    setState(() {
      _selectedIndex = widget.initialSelectedIndex;
    });
    _pageController = PageController(initialPage: _selectedIndex);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    DefaultCacheManager().emptyCache();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> getnotificationpermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> updateToken() async {
    var fcmToken = await FirebaseMessaging.instance.getToken();
    var user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final email = user.email;
      var token = await FirebaseFirestore.instance
          .collection('fcmTokens')
          .doc(email)
          .get();

      if (token.exists) {
        await FirebaseFirestore.instance
            .collection('fcmTokens')
            .doc(email)
            .update({'token': fcmToken});
      } else {
        await FirebaseFirestore.instance
            .collection('fcmTokens')
            .doc(email)
            .set({'token': fcmToken});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Notifications()),
                );
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: Colors.black87,
                      size: 24,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          MainAdminHome(),
          AdminOrdersPage(),
          AdminRevenue(),
          AdminProfile(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Roboto',
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              fontFamily: 'Roboto',
            ),
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_rounded, 0),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(FontAwesomeIcons.clipboardList, 1),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.analytics_rounded, 2),
                label: 'Revenue',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_rounded, 3),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Color(0xFF1B5E20),
            unselectedItemColor: Colors.grey[400],
            onTap: _onItemTapped,
          ),
        ),
      ),
      drawer: CustomDrawer(
        handleNavigation: handleNavigation,
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF1B5E20).withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? Color(0xFF1B5E20) : Colors.grey[400],
      ),
    );
  }

  void handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }
}

class CustomDrawer extends StatefulWidget {
  final Function(int) handleNavigation;

  const CustomDrawer({super.key, required this.handleNavigation});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final User = FirebaseAuth.instance.currentUser;

  Future<String?> getUsername() async {
    String? email;
    try {
      var userDocument = await FirebaseFirestore.instance
          .collection('Users')
          .doc(User!.email)
          .collection('userinfo')
          .doc('userinfo')
          .get();

      if (userDocument.exists) {
        email = userDocument.get('email') ?? "Demo";
      }
    } catch (e) {
      print("Error getting username: $e");
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Drawer(
      width: width * 0.85,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<String?>(
          future: getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1B5E20),
                          Color(0xFF2E7D32),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminProfile(),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Color(0xFFF1F8E9),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF1B5E20),
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello Admin 👋',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontFamily: 'Roboto',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      snapshot.data ?? 'Administrator',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: snapshot.data!.length <= 22
                                            ? 16
                                            : 13,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(top: 16, bottom: 16),
                      children: [
                        _buildDrawerItem(
                          context,
                          icon: Icons.home_rounded,
                          title: 'Home',
                          onTap: () {
                            widget.handleNavigation(0);
                            Navigator.pop(context);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: FontAwesomeIcons.clipboardList,
                          title: 'Orders',
                          onTap: () {
                            widget.handleNavigation(1);
                            Navigator.pop(context);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: Icons.analytics_rounded,
                          title: 'Revenue',
                          onTap: () {
                            widget.handleNavigation(2);
                            Navigator.pop(context);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: Icons.person_rounded,
                          title: 'Profile',
                          onTap: () {
                            widget.handleNavigation(3);
                            Navigator.pop(context);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: Icons.add,
                          title: 'Add Category',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, "/adminaddcategory");
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
