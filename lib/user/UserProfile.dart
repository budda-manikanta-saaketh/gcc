import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gcc/utils/signOut.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String userName = '';
  String userEmail = '';
  String profileImage = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .collection("userinfo")
          .doc("userinfo")
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final profileImages = data['Profile Image'] as List<dynamic>? ?? [];

        setState(() {
          userName = data['Full Name'] ?? '';
          userEmail = data['email'] ?? user.email!;
          profileImage = profileImages.isNotEmpty ? profileImages[0] : "";
          isLoading = false;
        });
      } else {
        setState(() {
          userName = user.displayName ?? 'User Name';
          userEmail = user.email ?? '';
          profileImage = "";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade50,
            Colors.white,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(0),
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.green.shade100,
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.green,
                                backgroundImage: profileImage.isNotEmpty
                                    ? NetworkImage(profileImage)
                                    : null,
                                child: profileImage.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white,
                                      )
                                    : null, // Show icon only if no image
                              ),
                            ),
                          )),
                      const SizedBox(height: 20),
                      Text(
                        userName.isNotEmpty
                            ? _toCamelCase(userName)
                            : 'User Name',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // The rest of your menu and settings sections
                _buildMenuSection(context),
              ],
            ),
    );
  }

  String _toCamelCase(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        // Menu Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildProfileOption(context, Icons.edit, 'Edit Profile',
                  'Update your info', Colors.teal),
              _buildDivider(),
              _buildProfileOption(context, Icons.shopping_bag_outlined,
                  'My Orders', 'View all your orders', Colors.blue),
              _buildDivider(),
              _buildProfileOption(context, Icons.favorite_outline, 'Wishlist',
                  'Your saved items', Colors.red),
              _buildDivider(),
              _buildProfileOption(context, Icons.location_on_outlined,
                  'Addresses', 'Manage delivery addresses', Colors.orange),
              _buildDivider(),
              _buildProfileOption(context, Icons.payment_outlined,
                  'Payment Methods', 'Manage payment options', Colors.purple),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Settings Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildProfileOption(context, Icons.notifications_outlined,
                  'Notifications', 'Manage notifications', Colors.amber),
              _buildDivider(),
              _buildProfileOption(context, Icons.settings_outlined, 'Settings',
                  'App preferences', Colors.grey),
              _buildDivider(),
              _buildProfileOption(context, Icons.help_outline, 'Help & Support',
                  'Get help', Colors.teal),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Logout Button
        _buildLogoutButton(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title,
      String subtitle, Color iconColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          switch (title) {
            case "Addresses":
              Navigator.pushNamed(context, "/useraddress");
              break;
            case "My Orders":
              Navigator.pushNamed(context, "/userorders");
              break;
            case "Edit Profile":
              Navigator.pushNamed(context, "/usereditprofile");
              break;
            case "Wishlist":
              Navigator.pushNamed(context, "/userwishlist");
              break;
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 68,
      endIndent: 16,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            handleSignOut(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
