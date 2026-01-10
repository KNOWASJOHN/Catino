import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'providers/notification_provider.dart';
import 'pages/home_page.dart';
import 'components/common/navbar.dart';
import 'components/common/header.dart';
import 'components/notifications/notification_panel.dart';
import 'components/common/search_bar.dart';
import 'pages/profile_page.dart';
import 'pages/print_page.dart';
import 'pages/cart_page.dart';
import 'pages/food_page.dart';
import 'components/animations/page_transition.dart';
import 'components/animations/circle_reveal_transition.dart';
import 'pages/login_page.dart';
import 'services/auth/supabase_auth_service.dart' as auth;
import 'services/notifications/print_notification_service.dart';
import 'services/notifications/order_notification_service.dart';
import 'config/supabase_config.dart';
import 'providers/cart_provider.dart';
import 'utils/logger_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _logger = AppLogger.getLogger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.initialize(level: Level.INFO);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    // Cannot continue without Supabase
    throw Exception('Failed to initialize application services');
  }

  // Initialize Print Notification Service
  try {
    await PrintNotificationService().initialize();
  } catch (e) {
    // Continue even if notification service fails
  }

  // Initialize Order Notification Service
  try {
    await OrderNotificationService().initialize();
  } catch (e) {
    // Continue even if notification service fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: StreamBuilder(
          stream: auth.SupabaseAuthService().authStateChanges,
          builder: (context, snapshot) {
            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Show login page if not authenticated
            if (!snapshot.hasData || snapshot.data?.session == null) {
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

  // FCM removed - using Supabase for notifications
  void _initializeFCM() async {
    // FCM service removed
    _logger.info('FCM service removed - using Supabase');
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
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Close panel when clicking outside
                setState(() {
                  _showNotificationPanel = false;
                });
              },
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  Positioned(
                    right: 5,
                    top: 30,
                    child: GestureDetector(
                      onTap: () {
                        // Prevent closing when clicking inside the panel
                      },
                      child: NotificationPanel(
                        onClose: () {
                          setState(() {
                            _showNotificationPanel = false;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
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
