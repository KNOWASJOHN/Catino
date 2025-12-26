import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: FirebaseConfig.apiKey,
      authDomain: FirebaseConfig.authDomain,
      databaseURL: FirebaseConfig.databaseURL,
      projectId: FirebaseConfig.projectId,
      storageBucket: FirebaseConfig.storageBucket,
      messagingSenderId: FirebaseConfig.messagingSenderId,
      appId: FirebaseConfig.appId,
      measurementId: FirebaseConfig.measurementId,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
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

  final List<Widget> _pages = [
    const HomePage(),
    const Food(),
    const PrintPage(),
    const Cart(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
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
      ),
    );
  }
}
