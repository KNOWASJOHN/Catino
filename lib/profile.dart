import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthService _authService = AuthService();
  
  // User data - will be loaded from cache/Firebase
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userPhone = 'Loading...';
  String studentId = 'Loading...';
  String branch = 'Loading...';
  String semester = 'Loading...';
  String hostel = 'Loading...';
  String profilePicUrl = '';

  bool notificationsEnabled = true;
  String dietaryPreference = 'Both';

  // Sample order data - will be replaced with real data later
  String lastOrderedItem = 'No orders yet';
  List<String> favoriteItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Start listening to real-time updates
    _authService.startListeningToUserData();
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    // Load from cache first (or Firebase if forced refresh)
    final userData = await _authService.getUserData(forceRefresh: forceRefresh);
    if (userData != null && mounted) {
      setState(() {
        userName = userData['name'] ?? 'User';
        userEmail = userData['email'] ?? '';
        userPhone = userData['phone'] ?? '';
        studentId = userData['studentId'] ?? '';
        branch = userData['branch'] ?? '';
        semester = userData['semester'] ?? '';
        hostel = userData['hostel'] ?? '';
        profilePicUrl = userData['profilePicUrl'] ?? '';
        notificationsEnabled = userData['notificationsEnabled'] ?? true;
        dietaryPreference = userData['dietaryPreference'] ?? 'Both';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData(forceRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header with Picture and Basic Info
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),

              _buildProfileHeader(),

              const SizedBox(height: 20),

              // User Info Section
              _buildSection(
                title: 'Personal Information',
                children: [
                  _buildInfoTile(Icons.person, 'Name', userName),
                  _buildInfoTile(Icons.phone, 'Phone', userPhone),
                  _buildInfoTile(Icons.email, 'Email', userEmail),
                ],
              ),

            const SizedBox(height: 16),

            // Academic Info Section
            _buildSection(
              title: 'Academic Details',
              children: [
                _buildInfoTile(Icons.badge, 'Student ID', studentId),
                _buildInfoTile(Icons.school, 'Branch', branch),
                _buildInfoTile(Icons.calendar_today, 'Semester', semester),
                _buildInfoTile(Icons.home, 'Hostel & Room', hostel),
              ],
            ),

            const SizedBox(height: 16),

            // Order History Section
            _buildSection(
              title: 'Order & Favorites',
              children: [
                _buildActionTile(
                  Icons.history,
                  'Order History',
                  'View all your past orders',
                  () {
                    // Navigate to order history page
                    print('Navigate to Order History');
                  },
                ),
                _buildInfoTile(Icons.fastfood, 'Last Ordered', lastOrderedItem),
                _buildFavoritesList(),
              ],
            ),

            const SizedBox(height: 16),

            // Preferences Section
            _buildSection(
              title: 'Preferences',
              children: [
                _buildSwitchTile(
                  Icons.notifications,
                  'Order Notifications',
                  'Get updates on order status',
                  notificationsEnabled,
                  (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
                _buildDietaryPreference(),
              ],
            ),

            const SizedBox(height: 16),

            // Account Management Section
            _buildSection(
              title: 'Manage Account',
              children: [
                _buildActionTile(
                  Icons.edit,
                  'Edit Profile',
                  'Update your personal information',
                  () {
                    // Navigate to edit profile page
                    print('Navigate to Edit Profile');
                  },
                ),
                _buildActionTile(
                  Icons.lock,
                  'Change Password',
                  'Update your login credentials',
                  () {
                    // Navigate to change password page
                    print('Navigate to Change Password');
                  },
                ),
                _buildActionTile(
                  Icons.logout,
                  'Logout',
                  'Sign out of your account',
                  () {
                    _showLogoutDialog();
                  },
                  isDestructive: true,
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.limeAccent.shade700, Colors.limeAccent.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: profilePicUrl.isEmpty
                      ? Icon(Icons.person, size: 50, color: Colors.black)
                      : ClipOval(
                          child: Image.network(
                            profilePicUrl,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                    icon: Icon(Icons.camera_alt, color: Colors.black, size: 18),
                    onPressed: () {
                      // Handle profile picture change
                      print('Change profile picture');
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentId,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.limeAccent.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50
                    : Colors.limeAccent.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? Colors.red : Colors.black,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.limeAccent.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) async {
              onChanged(newValue);
              // Update in Firebase
              await _authService.updateUserData({
                'notificationsEnabled': newValue,
              });
            },
            activeColor: Colors.limeAccent.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryPreference() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.limeAccent.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant_menu, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dietary Preference',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Filter food items',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: dietaryPreference,
            underline: const SizedBox(),
            items: ['Vegetarian', 'Non-Vegetarian', 'Both'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(fontFamily: 'Unbounded', fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) async {
              if (newValue != null) {
                setState(() {
                  dietaryPreference = newValue;
                });
                // Update in Firebase
                await _authService.updateUserData({
                  'dietaryPreference': newValue,
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.limeAccent.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.favorite, size: 20, color: Colors.black),
              ),
              const SizedBox(width: 16),
              const Text(
                'Favorite Items',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: favoriteItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.limeAccent.shade700),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.limeAccent.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontFamily: 'Unbounded', fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authService.signOut();
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
