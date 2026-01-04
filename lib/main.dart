import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'pages/home.dart';
import 'components/navbar.dart';
import 'components/header.dart';
import 'page_components/notification_panel.dart';
import 'page_components/searchbar.dart';
import 'profile.dart';
import 'print.dart';
import 'cart.dart';
import 'pages/food.dart';
import 'components/page_transition.dart';
import 'components/circle_reveal_transition.dart';
import 'pages/loginpage.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options for all platforms
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM background message handler BEFORE runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: StreamBuilder(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Show login page if not authenticated
            if (!snapshot.hasData) {
              return const LoginPage();
            }

            // Show main app if authenticated
            return const MainScreen();
          },
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<double> _navItemPositions = List.filled(5, 0.0);
  double _navBarVerticalPosition = 0.0;
  bool _isAnimating = false;
  Offset _animationStartPosition = const Offset(0, 0);
  bool _showNotificationPanel = false;
  bool _showSearchMenu = false;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const FoodListPage(),
      const Cart(),
      const PrintPage(),
      const Profile(),
    ];
    _initializeFCM();
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedIndex', index);
  }

  void _initializeFCM() async {
    try {
      await FCMService().initialize();
      print('FCM initialized successfully');
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0),
            elevation: 0,
            toolbarHeight: 60,
            scrolledUnderElevation: 0,
            flexibleSpace: Header(
              onNotificationTap: () {
                setState(() {
                  _showNotificationPanel = !_showNotificationPanel;
                });
              },
              onSearchTap: () {
                setState(() {
                  _showSearchMenu = true;
                });
              },
            ),
          ),
          body: Stack(
            children: [
              PageTransition(
                index: _selectedIndex,
                child: _pages[_selectedIndex],
              ),
              CircleRevealTransition(
                startPosition: _animationStartPosition,
                isAnimating: _isAnimating,
                onComplete: () {
                  setState(() {
                    _isAnimating = false;
                  });
                },
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            isTransitioning: _isAnimating,
            onPositionsUpdated: (positions, verticalPos) {
              setState(() {
                _navItemPositions = positions;
                _navBarVerticalPosition = verticalPos;
              });
            },
            onItemSelected: (index) {
              if (index != _selectedIndex &&
                  _navItemPositions[index] != 0.0 &&
                  !_isAnimating) {
                _saveSelectedIndex(index); // Add this line
                setState(() {
                  _animationStartPosition = Offset(
                    _navItemPositions[index],
                    _navBarVerticalPosition,
                  );
                  _isAnimating = true;
                });
                Future.delayed(const Duration(milliseconds: 850), () {
                  if (mounted) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  }
                });
              }
            },
          ),
        ),
        if (_showNotificationPanel)
          Positioned(
            right: 5,
            top: 30,
            child: NotificationPanel(
              onClose: () {
                setState(() {
                  _showNotificationPanel = false;
                });
              },
            ),
          ),
        if (_showSearchMenu)
          SearchMenu(
            onClose: () {
              setState(() {
                _showSearchMenu = false;
              });
            },
          ),
      ],
    );
  }
}
