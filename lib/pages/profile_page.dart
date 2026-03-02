import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'package:flutter/foundation.dart';
import '../services/auth/supabase_auth_service.dart';
import '../services/log.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final SupabaseAuthService _authService = SupabaseAuthService();

  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String student_id = '';
  String branch = '';
  String semester = '';
  String hostel = '';
  String profilePicUrl = '';

  bool notificationsEnabled = true;
  String dietaryPreference = 'Both';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _authService.startListeningToUserData();
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    if (!forceRefresh) setState(() => _isLoading = true);
    final userData = await _authService.getUserData(forceRefresh: forceRefresh);
    if (userData != null && mounted) {
      setState(() {
        userName = userData['user_name'] ?? 'User';
        userEmail = userData['email'] ?? '';
        userPhone = userData['phone'] ?? '';
        student_id = userData['student_id'] ?? '';
        branch = userData['branch'] ?? '';
        semester = userData['semester'] ?? '';
        hostel = userData['hostel'] ?? '';
        profilePicUrl = userData['profilePicUrl'] ?? '';
        notificationsEnabled = userData['notifications_enabled'] ?? true;
        dietaryPreference = userData['dietary_preference'] ?? 'Both';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        color: AppColors.primaryCta,
        backgroundColor: Colors.white,
        onRefresh: () => _loadUserData(forceRefresh: true),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverHeader(context),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          _buildInfoCard(),
                          const SizedBox(height: 12),
                          _buildPreferencesCard(),
                          const SizedBox(height: 12),
                          _buildAccountCard(),
                          const SizedBox(height: 12),
                          _buildLogoutButton(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Sliver App Bar / Header ──────────────────────────────────────────────

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width * 0.5,
      collapsedHeight: 0,
      toolbarHeight: 0,
      pinned: false,
      floating: true,
      snap: true,
      backgroundColor: Colors.grey.shade100,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryCta.withOpacity(0.85),
                AppColors.primaryCtaGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isEmpty ? 'Your Profile' : userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Unbounded',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (student_id.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            student_id,
                            style: const TextStyle(
                              fontFamily: 'Unbounded',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        if (branch.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$branch · Sem $semester',
                              style: const TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: Colors.white.withOpacity(0.25),
          child: CircleAvatar(
            radius: 39,
            backgroundColor: Colors.white,
            backgroundImage: profilePicUrl.isNotEmpty
                ? NetworkImage(profilePicUrl)
                : null,
            child: profilePicUrl.isEmpty
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryCta,
                    ),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
            onTap: () {
              if (kDebugMode) logInfo('Change profile picture');
            },
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: AppColors.primaryCta,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Cards ────────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return _Card(
      children: [
        _InfoRow(Icons.person_outline_rounded, 'Name', userName),
        _Divider(),
        _InfoRow(Icons.phone_outlined, 'Phone', userPhone),
        _Divider(),
        _InfoRow(Icons.email_outlined, 'Email', userEmail),
        _Divider(),
        _InfoRow(Icons.home_outlined, 'Hostel & Room', hostel),
        _Divider(),
        _InfoRow(Icons.history_rounded, 'Last Order', 'No orders yet'),
      ],
    );
  }

  Widget _buildPreferencesCard() {
    return _Card(
      label: 'Preferences',
      children: [
        // Notifications toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.primaryCta,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Order Notifications',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: notificationsEnabled,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.primaryCta,
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primaryCta.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primaryCta
                      : Colors.grey.shade400,
                ),
                onChanged: (newValue) async {
                  setState(() => notificationsEnabled = newValue);
                  final updated = await _authService.updateUserData({
                    'notifications_enabled': newValue,
                  });
                  if (updated) {
                    final fresh = await _authService.getUserData(
                      forceRefresh: true,
                    );
                    if (fresh != null && mounted) {
                      setState(() {
                        notificationsEnabled =
                            fresh['notifications_enabled'] ?? newValue;
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
        _Divider(),
        // Dietary preference
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 20,
                color: AppColors.primaryCta,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Diet',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: dietaryPreference,
                  dropdownColor: Colors.white,
                  iconEnabledColor: AppColors.primaryCta,
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 11,
                    color: AppColors.primaryCta,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  items: ['Vegetarian', 'Non-Vegetarian', 'Both'].map((v) {
                    return DropdownMenuItem(value: v, child: Text(v));
                  }).toList(),
                  onChanged: (newValue) async {
                    if (newValue == null) return;
                    setState(() => dietaryPreference = newValue);
                    final updated = await _authService.updateUserData({
                      'dietary_preference': newValue,
                    });
                    if (updated) {
                      final fresh = await _authService.getUserData(
                        forceRefresh: true,
                      );
                      if (fresh != null && mounted) {
                        setState(() {
                          dietaryPreference =
                              fresh['dietary_preference'] ?? newValue;
                        });
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return _Card(
      label: 'Account',
      children: [
        _ActionRow(
          icon: Icons.history_rounded,
          label: 'Order History',
          onTap: () {
            if (kDebugMode) logInfo('Navigate to Order History');
          },
        ),
        _Divider(),
        _ActionRow(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: () {
            if (kDebugMode) logInfo('Navigate to Edit Profile');
          },
        ),
        _Divider(),
        _ActionRow(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () {
            if (kDebugMode) logInfo('Navigate to Change Password');
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Log Out',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ── Logout Dialog ────────────────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Log Out?',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'You will be signed out of your account.',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: Colors.grey.shade500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String? label;
  final List<Widget> children;

  const _Card({this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                label!,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black38,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryCta),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 12,
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
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryCta),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.shade200,
      indent: 48,
      endIndent: 0,
    );
  }
}
