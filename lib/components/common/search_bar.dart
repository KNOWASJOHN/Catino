import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:provider/provider.dart';
import '../../models/food_item.dart';
import '../../services/data/supabase_food_service.dart';
import '../../providers/cart_provider.dart';

class SearchMenu extends StatefulWidget {
  final VoidCallback onClose;

  const SearchMenu({super.key, required this.onClose});

  @override
  State<SearchMenu> createState() => _SearchMenuState();
}

class _SearchMenuState extends State<SearchMenu>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final SupabaseFoodService _foodService = SupabaseFoodService();

  List<FoodItem> _allFoodItems = [];
  List<FoodItem> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linearToEaseOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    try {
      final items = await _foodService.getAllFoodItems();
      if (mounted) {
        setState(() {
          _allFoodItems = items.where((item) => item.isAvailable).toList();
          _filteredItems = _allFoodItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading food items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allFoodItems;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredItems = _allFoodItems.where((item) {
          return item.name.toLowerCase().contains(lowerQuery) ||
              item.category.toLowerCase().contains(lowerQuery) ||
              item.description.toLowerCase().contains(lowerQuery) ||
              item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
      }
    });
  }

  void _closeSearch() {
    _animationController.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeSearch,
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
                child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Text(
                            'Search Food',
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _closeSearch,
                          ),
                        ],
                      ),
                    ),
                    // Search Field
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        style: const TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _filterItems,
                        decoration: InputDecoration(
                          hintText: 'Search for food...',
                          hintStyle: TextStyle(
                            fontFamily: 'Unbounded',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterItems('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Results
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_filteredItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No results found',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.white, Colors.transparent],
                              stops: [0.75, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];

                              return Consumer<CartProvider>(
                                builder: (context, cartProvider, child) {
                                  return GestureDetector(
                                    onTap: () {
                                      _closeSearch();
                                    },
                                    child: Container(
                                      height: 120,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: item.imageUrl.isNotEmpty
                                                ? Image.network(
                                                    item.imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Container(
                                                            color: Colors
                                                                .grey
                                                                .shade200,
                                                            child: Icon(
                                                              Icons.fastfood,
                                                              size: 40,
                                                              color: Colors
                                                                  .grey
                                                                  .shade400,
                                                            ),
                                                          );
                                                        },
                                                  )
                                                : Container(
                                                    color: Colors.grey.shade200,
                                                    child: Icon(
                                                      Icons.fastfood,
                                                      size: 40,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  ),
                                          ),
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.black.withValues(
                                                      alpha: 0.08,
                                                    ),
                                                    Colors.black.withValues(
                                                      alpha: 0.65,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 16,
                                            right: 16,
                                            top: 16,
                                            bottom: 16,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  item.isVegetarian
                                                                  ? const Color(
                                                                      0xFF00C853,
                                                                    )
                                                                  : Colors
                                                                        .red
                                                                        .shade700,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              item.isVegetarian
                                                                  ? 'VEG'
                                                                  : 'NON-VEG',
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontFamily:
                                                                    'Unbounded',
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              item.name,
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    'Unbounded',
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        item.category,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Unbounded',
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '₹${item.price.toStringAsFixed(2)}',
                                                            style: const TextStyle(
                                                              fontFamily:
                                                                  'Unbounded',
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .limeAccent,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Icon(
                                                            Icons.access_time,
                                                            size: 12,
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            '${item.preparationTime} min',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .white70,
                                                                  fontFamily:
                                                                      'Unbounded',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    cartProvider.addItem(
                                                      item.id,
                                                    );
                                                  },
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.priceText,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.add_shopping_cart,
                                                          color: Colors.black,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      if ((cartProvider.cart[item.id] ?? 0) > 0)
                                                        Positioned(
                                                          top: -6,
                                                          right: -6,
                                                          child: Container(
                                                            padding: const EdgeInsets.all(3),
                                                            decoration: const BoxDecoration(
                                                              color: Colors.black,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            constraints: const BoxConstraints(
                                                              minWidth: 18,
                                                              minHeight: 18,
                                                            ),
                                                            child: Text(
                                                              '${cartProvider.cart[item.id]}',
                                                              style: const TextStyle(
                                                                color: AppColors.priceText,
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
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
