import 'package:flutter/material.dart';

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
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _foodItems = [
    {'name': 'Burger', 'price': 12.99, 'image': 'assets/Elements/burger.jpg'},
    {'name': 'Pizza', 'price': 15.99, 'image': 'assets/Elements/pizza.jpg'},
    {'name': 'Juice', 'price': 5.99, 'image': 'assets/Elements/juice.jpg'},
  ];

  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _foodItems;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
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
        _filteredItems = _foodItems;
      } else {
        _filteredItems = _foodItems
            .where((item) =>
                item['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
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
          child: ScaleTransition(
            scale: _scaleAnimation,
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
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
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey.shade600),
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
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                const BorderSide(color: Colors.black, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Results
                    if (_filteredItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off,
                                size: 60, color: Colors.grey.shade400),
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
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final String name = item['name'] ?? '';
                            final double price = item['price'] ?? 0.0;
                            final String image = item['image'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                _closeSearch();
                              },
                              child: Container(
                                height: 80,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.asset(
                                        image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.08),
                                              Colors.black.withValues(alpha: 0.65),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 16,
                                      right: 16,
                                      bottom: 16,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontFamily: 'Unbounded',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '\$${price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontFamily: 'Unbounded',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.limeAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}