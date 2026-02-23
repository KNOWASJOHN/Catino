import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme/theme.dart';

/// Reusable modern toast helper using FToast.
/// Usage:
///   AppToast.show(context, 'Message');
///   AppToast.show(context, 'Error', isError: true);
///   AppToast.show(context, 'Warning', isWarning: true);
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    final color = isError
        ? AppColors.statusError
        : isWarning
        ? AppColors.statusWarning
        : AppColors.primary;

    final icon = isError
        ? Icons.error_outline_rounded
        : isWarning
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    final fToast = FToast()..init(context);
    fToast.showToast(
      toastDuration: const Duration(seconds: 2),
      gravity: ToastGravity.BOTTOM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
