import 'package:flutter/material.dart';
import 'dart:ui';

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
            padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
            child: Row(
              children: [
                SizedBox(width: 4),
                Icon(Icons.storefront, size: 35, color: Colors.black),
                SizedBox(width: 2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                SizedBox(width: 20),
                GestureDetector(
                  onTap: onNotificationTap,
                  child: Icon(
                    Icons.notifications,
                    size: 25,
                    color: Colors.black,
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
