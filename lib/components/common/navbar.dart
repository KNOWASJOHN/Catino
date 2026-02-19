import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/cart_provider.dart';



/// CustomBottomNavBar with liquid bubble warp effect and gradient border

class CustomBottomNavBar extends StatefulWidget {

  final Function(int) onItemSelected;

  final int currentIndex;

  final bool isTransitioning;

  final Function(List<double>, double)? onPositionsUpdated;



  const CustomBottomNavBar({

    super.key,

    required this.onItemSelected,

    this.currentIndex = 0,

    this.isTransitioning = false,

    this.onPositionsUpdated,

  });



  @override

  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();

}



class _CustomBottomNavBarState extends State<CustomBottomNavBar>

    with TickerProviderStateMixin {

  late int _selectedIndex;

  late int _previousIndex;

  late AnimationController _bubbleController;

  late Animation<double> _bubbleAnimation;

  

  // GlobalKeys for tracking nav item positions

  final List<GlobalKey> _navItemKeys = List.generate(5, (_) => GlobalKey());

  final GlobalKey _stackKey = GlobalKey();

  

  // Store the render positions of each nav item center

  final List<double> _itemPositions = List.filled(5, 0.0);

  bool _positionsInitialized = false;



  @override

  void initState() {

    super.initState();

    _selectedIndex = widget.currentIndex;

    _previousIndex = widget.currentIndex;

    _bubbleController = AnimationController(

      duration: const Duration(milliseconds: 800),

      vsync: this,

    );

    _bubbleAnimation = Tween<double>(begin: 0, end: 1).animate(

      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOutCubic),

    );

    

    WidgetsBinding.instance.addPostFrameCallback((_) {

      _updateItemPositions();

    });

  }



  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = _selectedIndex;
      _selectedIndex = widget.currentIndex;
      _bubbleController.forward(from: 0.0);
    }
    // Recalculate positions on widget update (including orientation changes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateItemPositions();
    });
  }



  @override

  void dispose() {

    _bubbleController.dispose();

    super.dispose();

  }



  /// Programmatically select a tab — identical to tapping the nav item.
  void selectIndex(int index) {
    if (_selectedIndex != index && !widget.isTransitioning) {
      setState(() {
        _previousIndex = _selectedIndex;
        _selectedIndex = index;
      });
      _updateItemPositions();
      _bubbleController.forward(from: 0.0);
      widget.onItemSelected(index);
    }
  }

  void _updateItemPositions() {

    final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;

    if (stackBox == null) return;



    double navBarTop = 0;

    for (int i = 0; i < _navItemKeys.length; i++) {

      final RenderBox? box = _navItemKeys[i].currentContext?.findRenderObject() as RenderBox?;

      if (box != null) {

        // Get position relative to the Stack for bubble positioning

        final offset = box.localToGlobal(Offset.zero, ancestor: stackBox);

        final centerX = offset.dx + (box.size.width / 2);

        _itemPositions[i] = centerX;

        

        // Get global position for parent callback

        if (i == 0) {

          final globalOffset = box.localToGlobal(Offset.zero);

          navBarTop = globalOffset.dy + (box.size.height / 2);

        }

      }

    }

    

    if (mounted) {

      setState(() {

        _positionsInitialized = true;

      });

      // Notify parent of updated positions

      widget.onPositionsUpdated?.call(_itemPositions, navBarTop);

    }

  }



  double _getBubbleLeftPosition() {

    if (!_positionsInitialized || _itemPositions[_selectedIndex] == 0) {

      return 0;

    }

    

    final startPos = _itemPositions[_previousIndex];

    final endPos = _itemPositions[_selectedIndex];

    final bubbleRadius = 24.0;

    

    final currentPos = startPos + (_bubbleAnimation.value * (endPos - startPos));

    return currentPos - bubbleRadius;

  }



  // Liquid warp effect calculations

  double _getHorizontalSquish() {

    final progress = _bubbleAnimation.value;

    if (progress < 0.5) {

      return 1.0 + (0.3 * progress * 2);

    } else {

      return 1.3 - (0.3 * (progress - 0.5) * 2);

    }

  }



  double _getVerticalSquish() {

    final progress = _bubbleAnimation.value;

    if (progress < 0.5) {

      return 1.0 - (0.2 * progress * 2);

    } else {

      return 0.8 + (0.2 * (progress - 0.5) * 2);

    }

  }



  double _getRotationAngle() {

    final progress = _bubbleAnimation.value;

    final distance = (_itemPositions[_selectedIndex] - _itemPositions[_previousIndex]).abs();

    final direction = _selectedIndex > _previousIndex ? 1.0 : -1.0;

    

    final maxRotation = (distance / 100) * 0.3;

    

    if (progress < 0.3) {

      return direction * maxRotation * (progress / 0.3);

    } else if (progress < 0.7) {

      return direction * maxRotation;

    } else {

      return direction * maxRotation * (1 - ((progress - 0.7) / 0.3));

    }

  }



  @override

  Widget build(BuildContext context) {

    // Trigger position recalculation when screen orientation or size changes

    WidgetsBinding.instance.addPostFrameCallback((_) {

      _updateItemPositions();

    });



    return Container(

      color: const Color.fromARGB(0, 0, 0, 0),

      padding: EdgeInsets.only(

        bottom: MediaQuery.of(context).padding.bottom + 13,

        left: 16,

        right: 16,

        top: 8,

      ),

      child: SizedBox(

        height: 72,

        child: Stack(

          children: [

            // Frosted glass background with proper semi-transparent color

            ClipRRect(

              borderRadius: BorderRadius.circular(50),

              child: BackdropFilter(

                filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),

                child: Container(

                  decoration: BoxDecoration(

                    color: const Color.fromARGB(0, 0, 0, 0).withValues(alpha: 0.10),

                    borderRadius: BorderRadius.circular(40),

                    border: Border.all(

                      color: const Color.fromARGB(0, 255, 255, 255).withValues(alpha: 0.25),

                      width: 1.5,

                    ),

                  ),

                  child: _buildNavBarContent(),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildNavBarContent() {

    return Container(

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(50),

        gradient: LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [

            Colors.white.withValues(alpha: 0.2),

            Colors.white.withValues(alpha: 0.1),

            Colors.white.withValues(alpha: 0.2),

          ],

        ),

      ),

      child: LayoutBuilder(

        builder: (context, constraints) {

          return SizedBox(

            height: 72,

            width: constraints.maxWidth,

            child: Stack(

              key: _stackKey,

              children: [

                // Liquid bubble with warp effects

                if (_positionsInitialized)

                  AnimatedBuilder(

                    animation: _bubbleAnimation,

                    builder: (context, child) {

                      final left = _getBubbleLeftPosition();

                      final horizontalSquish = _getHorizontalSquish();

                      final verticalSquish = _getVerticalSquish();

                      final rotation = _getRotationAngle();

                      return Positioned(

                        left: left,

                        top: 10,

                        child: Transform(

                          transform: Matrix4.identity()

                            ..scaleByVector3(Vector3(horizontalSquish, verticalSquish, 1.0))

                            ..rotateZ(rotation),

                          alignment: Alignment.center,

                          child: Container(

                            width: 48,

                            height: 48,

                            decoration: BoxDecoration(

                              shape: BoxShape.circle,

                              color: Colors.lime.shade400,

                              gradient: LinearGradient(

                                begin: Alignment.topLeft,

                                end: Alignment.bottomRight,

                                colors: [

                                  Colors.lime.shade300,

                                  Colors.lime.shade500,

                                ],

                              ),

                              boxShadow: [

                                BoxShadow(

                                  color: Colors.lime.shade400.withValues(alpha: 0.5),

                                  blurRadius: 12,

                                  spreadRadius: 2,

                                  offset: Offset(0, 2 * (1 - verticalSquish)),

                                ),

                              ],

                            ),

                            child: Stack(

                              children: [

                                // Liquid shine effect

                                Positioned(

                                  top: 8,

                                  left: 8,

                                  child: Container(

                                    width: 12,

                                    height: 12,

                                    decoration: BoxDecoration(

                                      shape: BoxShape.circle,

                                      color: Colors.white.withValues(alpha: 0.3),

                                    ),

                                  ),

                                ),

                                // Ripple effect during movement

                                if (_bubbleAnimation.value > 0 && _bubbleAnimation.value < 1)

                                  Positioned(

                                    top: 24 - (24 * verticalSquish),

                                    left: 24 - (24 * horizontalSquish),

                                    child: Container(

                                      width: 48 * horizontalSquish,

                                      height: 48 * verticalSquish,

                                      decoration: BoxDecoration(

                                        shape: BoxShape.circle,

                                        border: Border.all(

                                          color: Colors.white.withValues(alpha: 0.2 * (1 - _bubbleAnimation.value.abs() * 2 - 0.5).abs()),

                                          width: 1.5,

                                        ),

                                      ),

                                    ),

                                  ),

                              ],

                            ),

                          ),

                        ),

                      );

                    },

                  ),

                // Navigation items

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [

                    _buildNavItem(0, Icons.home, 'Home', _navItemKeys[0]),

                    _buildNavItem(1, Icons.fastfood, 'Food', _navItemKeys[1]),

                    Consumer<CartProvider>(

                      builder: (context, cartProvider, child) {

                        return _buildCartNavItem(2, Icons.shopping_cart_checkout_outlined, 'Cart', _navItemKeys[2], cartProvider.itemCount);

                      },

                    ),

                    _buildNavItem(3, Icons.print, 'Print', _navItemKeys[3]),

                    _buildNavItem(4, Icons.person_outline, 'Profile', _navItemKeys[4]),
                  ],
                ),

              ],

            ),

          );

        },

      ),

    );

  }



  Widget _buildNavItem(int index, IconData icon, String label, GlobalKey key) {

    final isSelected = _selectedIndex == index;

    

    return Expanded(

      child: GestureDetector(

        onTap: () {

          if (_selectedIndex != index && !widget.isTransitioning) {

            setState(() {

              _previousIndex = _selectedIndex;

              _selectedIndex = index;

            });

            _updateItemPositions();

            _bubbleController.forward(from: 0.0);

            widget.onItemSelected(index);

          }

        },

        child: Center(

          child: SizedBox(

            key: key,

            width: 48,

            height: 48,

            child: Center(

              child: Icon(

                icon,

                size: 24,

                color: isSelected ? Colors.grey.shade800 : Colors.grey.shade400,

                semanticLabel: label,

              ),

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildCartNavItem(int index, IconData icon, String label, GlobalKey key, int cartCount) {

    final isSelected = _selectedIndex == index;

    

    return Expanded(

      child: GestureDetector(

        onTap: () {

          if (_selectedIndex != index && !widget.isTransitioning) {

            setState(() {

              _previousIndex = _selectedIndex;

              _selectedIndex = index;

            });

            _updateItemPositions();

            _bubbleController.forward(from: 0.0);

            widget.onItemSelected(index);

          }

        },

        child: Center(

          child: SizedBox(

            key: key,

            width: 48,

            height: 48,

            child: Stack(

              children: [

                Center(

                  child: Icon(

                    icon,

                    size: 24,

                    color: isSelected ? Colors.grey.shade800 : Colors.grey.shade400,

                    semanticLabel: label,

                  ),

                ),

                if (cartCount > 0)

                  Positioned(

                    right: 6,

                    top: 5,

                    child: Container(

                      padding: const EdgeInsets.all(4),

                      decoration: BoxDecoration(

                        color: Colors.red.shade400,

                        shape: BoxShape.circle,

                        boxShadow: [

                          BoxShadow(

                            color: Colors.red.shade400.withValues(alpha: 0.3),

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

                        cartCount > 99 ? '99+' : cartCount.toString(),

                        style: TextStyle(

                          color: Colors.grey.shade800,

                          fontSize: 10,

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

        ),

      ),

    );

  }

}



class MyHomePage extends StatelessWidget {

  const MyHomePage({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Custom Bottom NavBar Demo'),

      ),

      body: const Center(

        child: Text('Content goes here'),

      ),

      bottomNavigationBar: CustomBottomNavBar(

        currentIndex: 0,

        onItemSelected: (index) {},

      ),

    );

  }

}