import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:provider/provider.dart';
import '../../models/food_item.dart';
import '../../services/data/supabase_food_service.dart';
import '../../providers/cart_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
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
        color: AppColors.barrierMedium,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.dialogGradientStart,
                        AppColors.dialogGradientMid,
                        AppColors.dialogGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xxxl),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: AppShadows.dialog,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xxxl),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -40,
                          right: -40,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -30,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight.withOpacity(0.04),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                              child: Row(
                                children: [
                                  const Text(
                                    'Search Food',
                                    style: TextStyle(
                                      fontFamily: 'Unbounded',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _closeSearch,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.15),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Search Field
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: TextField(
                                style: const TextStyle(
                                  fontFamily: 'Unbounded',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                                controller: _searchController,
                                autofocus: true,
                                onChanged: _filterItems,
                                decoration: InputDecoration(
                                  hintText: 'Search food, category, tags...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 18,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            _filterItems('');
                                          },
                                          child: Icon(
                                            Icons.clear_rounded,
                                            size: 16,
                                            color: Colors.white.withOpacity(0.4),
                                          ),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: AppColors.surfaceCard,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            // Results
                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            else if (_filteredItems.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(AppRadius.lg),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.search_off_rounded,
                                        size: 28,
                                        color: AppColors.primary.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchController.text.isEmpty
                                          ? 'Start typing to search'
                                          : 'No results found',
                                      style: TextStyle(
                                        fontFamily: 'Unbounded',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Flexible(
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.black, Colors.transparent],
                                      stops: [0.78, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      return Consumer<CartProvider>(
                                        builder: (context, cartProvider, child) {
                                          return GestureDetector(
                                            onTap: _closeSearch,
                                            child: Container(
                                              height: 110,
                                              margin: const EdgeInsets.only(bottom: 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                                border: Border.all(
                                                  color: AppColors.borderHighlight,
                                                  width: 1,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: item.imageUrl.isNotEmpty
                                                        ? Image.network(
                                                            item.imageUrl,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Container(
                                                                color: AppColors.surfaceCard,
                                                                child: Icon(
                                                                  Icons.image_not_supported_outlined,
                                                                  size: 32,
                                                                  color: Colors.white.withOpacity(0.2),
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : Container(
                                                            color: AppColors.surfaceCard,
                                                            child: Icon(
                                                              Icons.fastfood_outlined,
                                                              size: 32,
                                                              color: Colors.white.withOpacity(0.2),
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
                                                            Colors.black.withValues(alpha: 0.05),
                                                            Colors.black.withValues(alpha: 0.72),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 14,
                                                    right: 14,
                                                    top: 12,
                                                    bottom: 12,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal: 5,
                                                                      vertical: 2,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: item.isVegetarian
                                                                          ? const Color(0xFF00C853).withOpacity(0.85)
                                                                          : Colors.red.shade700.withOpacity(0.85),
                                                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                                                    ),
                                                                    child: Text(
                                                                      item.isVegetarian ? 'VEG' : 'NON-VEG',
                                                                      style: const TextStyle(
                                                                        color: Colors.white,
                                                                        fontSize: 7,
                                                                        fontWeight: FontWeight.w700,
                                                                        fontFamily: 'Unbounded',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Expanded(
                                                                    child: Text(
                                                                      item.name,
                                                                      style: const TextStyle(
                                                                        fontFamily: 'Unbounded',
                                                                        fontSize: 13,
                                                                        fontWeight: FontWeight.w600,
                                                                        color: Colors.white,
                                                                      ),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                item.category,
                                                                style: TextStyle(
                                                                  fontFamily: 'Unbounded',
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.w400,
                                                                  color: Colors.white.withValues(alpha: 0.65),
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    '₹${item.price.toStringAsFixed(0)}',
                                                                    style: const TextStyle(
                                                                      fontFamily: 'Unbounded',
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w700,
                                                                      color: AppColors.primaryBright,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Icon(
                                                                    Icons.access_time_rounded,
                                                                    size: 10,
                                                                    color: Colors.white.withOpacity(0.5),
                                                                  ),
                                                                  const SizedBox(width: 3),
                                                                  Text(
                                                                    '${item.preparationTime} min',
                                                                    style: TextStyle(
                                                                      fontSize: 9,
                                                                      color: Colors.white.withOpacity(0.5),
                                                                      fontFamily: 'Unbounded',
                                                                      fontWeight: FontWeight.w300,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        GestureDetector(
                                                          onTap: () {
                                                            cartProvider.addItem(item.id);
                                                            final fToast = FToast()..init(context);
                                                            fToast.showToast(
                                                              toastDuration: const Duration(seconds: 1),
                                                              gravity: ToastGravity.BOTTOM,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(
                                                                  horizontal: 14,
                                                                  vertical: 10,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: AppColors.primary,
                                                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                                                  boxShadow: [AppShadows.accentGlow(AppColors.primary)],
                                                                ),
                                                                child: const Text(
                                                                  'Added to cart',
                                                                  style: TextStyle(
                                                                    fontFamily: 'Unbounded',
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Stack(
                                                            clipBehavior: Clip.none,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.all(9),
                                                                decoration: BoxDecoration(
                                                                  gradient: const LinearGradient(
                                                                    colors: [
                                                                      AppColors.primary,
                                                                      AppColors.primaryLight,
                                                                    ],
                                                                    begin: Alignment.topLeft,
                                                                    end: Alignment.bottomRight,
                                                                  ),
                                                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                                                  boxShadow: [AppShadows.accentGlow(AppColors.primary)],
                                                                ),
                                                                child: const Icon(
                                                                  Icons.add_shopping_cart_rounded,
                                                                  color: Colors.white,
                                                                  size: 18,
                                                                ),
                                                              ),
                                                              if ((cartProvider.cart[item.id] ?? 0) > 0)
                                                                Positioned(
                                                                  top: -6,
                                                                  right: -6,
                                                                  child: Container(
                                                                    padding: const EdgeInsets.all(3),
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.surfaceCard,
                                                                      shape: BoxShape.circle,
                                                                      border: Border.all(
                                                                        color: AppColors.primary,
                                                                        width: 1.5,
                                                                      ),
                                                                    ),
                                                                    constraints: const BoxConstraints(
                                                                      minWidth: 18,
                                                                      minHeight: 18,
                                                                    ),
                                                                    child: Text(
                                                                      '${cartProvider.cart[item.id]}',
                                                                      style: const TextStyle(
                                                                        color: AppColors.primary,
                                                                        fontSize: 9,
                                                                        fontWeight: FontWeight.w700,
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
                      ],
                    ),
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
