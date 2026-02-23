import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A sleek network error card that automatically appears as a centered
/// popup card when connectivity is lost and dismisses when restored.
class NetworkErrorCard extends StatefulWidget {
  /// Optional callback fired when the user taps "Try Again".
  final VoidCallback? onRetry;

  const NetworkErrorCard({super.key, this.onRetry});

  @override
  State<NetworkErrorCard> createState() => _NetworkErrorCardState();
}

class _NetworkErrorCardState extends State<NetworkErrorCard>
    with SingleTickerProviderStateMixin {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _isOffline = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // Rebuild when reverse animation finishes so the scrim is removed from the tree
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted) setState(() {});
      }
    });

    _checkConnectivity();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final offline = results.contains(ConnectivityResult.none);
      _setOffline(offline);
    });
  }

  Future<void> _checkConnectivity() async {
    setState(() => _isChecking = true);
    try {
      final results = await _connectivity.checkConnectivity();
      final offline = results.contains(ConnectivityResult.none);
      _setOffline(offline);
    } catch (_) {
      _setOffline(true);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _setOffline(bool offline) {
    if (!mounted) return;
    if (offline == _isOffline) return;
    setState(() => _isOffline = offline);
    if (offline) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _handleRetry() async {
    setState(() => _isChecking = true);
    widget.onRetry?.call();
    await Future.delayed(const Duration(milliseconds: 600));
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline &&
        !_animController.isAnimating &&
        _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 380;
    final iconSize = isSmallScreen ? 64.0 : 80.0;

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Semi-transparent scrim behind the card
            GestureDetector(
              onTap: () {}, // Block taps from passing through
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),

            // Centered card
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: isSmallScreen ? 32 : 40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Wi-Fi icon with exclamation badge ---
                      SizedBox(
                        width: iconSize * 1.1,
                        height: iconSize * 1.1,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.wifi,
                              size: iconSize,
                              color: AppColors.networkErrorSurface,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: iconSize * 0.38,
                                height: iconSize * 0.38,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: iconSize * 0.32,
                                    height: iconSize * 0.32,
                                    decoration: const BoxDecoration(
                                      color: AppColors.networkErrorBadge,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.priority_high_rounded,
                                      size: iconSize * 0.21,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 28),

                      // --- Heading ---
                      Text(
                        'Ooops!',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: isSmallScreen ? 22 : 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.networkErrorSurface,
                          letterSpacing: -0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- Subtitle ---
                      Text(
                        'No Internet connection found.\nCheck your connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w300,
                          color: const Color(0xFF8A8A9A),
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // --- Try Again Button ---
                      SizedBox(
                        width: isSmallScreen ? 160 : 190,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _handleRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.networkErrorSurface,
                            disabledBackgroundColor: const Color(
                              0xFF1B1F3B,
                            ).withOpacity(0.6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Try Again',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                    decoration: TextDecoration.none,
                                  ),
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
      ),
    );
  }
}
