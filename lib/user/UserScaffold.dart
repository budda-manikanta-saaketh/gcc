import 'package:flutter/material.dart';
import 'package:gcc/User/UserCart.dart';
import 'package:gcc/User/UserHome.dart';
import 'package:gcc/User/UserOrders.dart';
import 'package:gcc/User/UserProfile.dart';
import 'package:gcc/utils/LazyLoad.dart';

class UserScaffold extends StatefulWidget {
  final initialIndex;
  const UserScaffold({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<UserScaffold> createState() => _UserScaffoldState();
}

class _UserScaffoldState extends State<UserScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    LazyLoadPage(builder: () => const UserHome()),
    LazyLoadPage(builder: () => const UserOrders()),
    LazyLoadPage(builder: () => const UserCart()),
    LazyLoadPage(builder: () => const UserProfile()),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Girijan',
          style: TextStyle(
            color: Colors.green,
            fontFamily: "Square Slab",
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, "/usersearch");
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade500,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@girijan.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    index: 0,
                    context: context,
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long,
                    title: 'Orders',
                    index: 1,
                    context: context,
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_cart_rounded,
                    title: 'Cart',
                    index: 2,
                    context: context,
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    index: 3,
                    context: context,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(),
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.favorite_rounded,
                    title: 'Wishlist',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/userwishlist");
                    },
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.search,
                    title: 'Search',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, "/usersearch");
                    },
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {
                      // Navigate to settings
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerActionItem(
                    icon: Icons.help_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      // Navigate to help
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required BuildContext context,
  }) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade700,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade800,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.green.shade700)
            : null,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildDrawerActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.grey.shade700).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.grey.shade700,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.grey.shade800,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
