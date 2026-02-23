import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/notification_provider.dart';
import '../../theme/theme.dart';

class Header extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;

  const Header({super.key, this.onNotificationTap, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          color: AppColors.glassHeader,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    SizedBox(width: 4),
                    Image.asset(
                      'assets/logo/Catino.png',
                      width: 45,
                      height: 45,
                    ),
                    SizedBox(width: 2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome to',
                          style: AppTextStyles.headerWelcome,
                        ),
                        Text(
                          'Catino',
                          style: AppTextStyles.headerAppName,
                        ),
                      ],
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: onSearchTap,
                      child: Icon(Icons.search, size: 25, color: Colors.black),
                    ),
                    SizedBox(width: 35),
                    Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        final unreadCount = notificationProvider.unreadCount;
                        return GestureDetector(
                          onTap: onNotificationTap,
                          child: SizedBox(
                            width: 25,
                            height: 25,
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.notifications,
                                    size: 25,
                                    color: Colors.black,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.redShade400,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          AppShadows.badgeShadow(AppColors.redShade400),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        style: AppTextStyles.badgeLabel,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
