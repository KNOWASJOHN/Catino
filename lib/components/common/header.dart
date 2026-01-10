import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/notification_provider.dart';

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
          color: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
            child: Row(
              children: [
                SizedBox(width: 4),
                Icon(Icons.storefront, size: 35, color: Colors.black),
                SizedBox(width: 2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'Catino',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
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
                                    color: Colors.red.shade400,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade400.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Unbounded',
                                    ),
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
    );
  }
}
