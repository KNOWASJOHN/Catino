import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../common/skeleton_loader.dart';

class ScrollCardModel {
  final String id;
  final String image;
  final String title;
  final String description;

  ScrollCardModel({
    required this.id,
    required this.image,
    required this.title,
    required this.description,
  });

  factory ScrollCardModel.fromMap(Map<dynamic, dynamic> map) {
    return ScrollCardModel(
      id: map['id'] ?? '',
      image: map['image'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }

  factory ScrollCardModel.fromSupabaseMap(Map<String, dynamic> map) {
    return ScrollCardModel(
      id: map['id'] ?? '',
      image: map['image'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class Scrollcard extends StatefulWidget {
  const Scrollcard({super.key});

  @override
  State<Scrollcard> createState() => _ScrollcardState();
}

class _ScrollcardState extends State<Scrollcard> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  Timer? _resumeTimer;
  Timer? _pollingTimer;
  bool _isUserInteracting = false;

  List<ScrollCardModel> _cards = [];
  List<ScrollCardModel> _cachedCards = [];
  bool _loading = true;
  String? _error;
  StreamSubscription? _cardsSubscription;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Try realtime subscription first
    _listenToScrollCards();

    // If realtime fails, fallback to regular fetch after a short delay
    await Future.delayed(const Duration(seconds: 2));
    if (_loading || _error != null) {
      _fallbackToRestApi();
    }
  }

  void _listenToScrollCards() {
    try {
      final supabase = Supabase.instance.client;
      _cardsSubscription = supabase
          .from('scroll_cards')
          .stream(primaryKey: ['id'])
          .eq('is_active', true)
          .order('display_order')
          .listen(
            (data) {
              _retryCount = 0; // Reset retry count on success
              final List<ScrollCardModel> cards = [];
              for (var item in data) {
                cards.add(ScrollCardModel.fromSupabaseMap(item));
              }
              // Compare with cache
              if (!_areCardListsEqual(cards, _cachedCards)) {
                if (mounted) {
                  setState(() {
                    _cards = cards;
                    _cachedCards = List<ScrollCardModel>.from(cards);
                    _loading = false;
                    _error = null;
                  });
                  _startAutoScroll();
                }
              }
            },
            onError: (e) {
              if (mounted) {
                _fallbackToRestApi();
              }
            },
          );
    } catch (e) {
      _fallbackToRestApi();
    }
  }

  Future<void> _fallbackToRestApi() async {
    print('Falling back to REST API polling');
    _cardsSubscription?.cancel();

    // Initial fetch
    await _fetchCardsWithRest();

    // Set up polling every 30 seconds
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchCardsWithRest();
    });
  }

  Future<void> _fetchCardsWithRest() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('scroll_cards')
          .select()
          .eq('is_active', true)
          .order('display_order');

      final List<ScrollCardModel> cards = [];
      for (var item in response) {
        cards.add(ScrollCardModel.fromSupabaseMap(item));
      }

      if (!_areCardListsEqual(cards, _cachedCards)) {
        if (mounted) {
          setState(() {
            _cards = cards;
            _cachedCards = List<ScrollCardModel>.from(cards);
            _loading = false;
            _error = null;
          });
          _startAutoScroll();
        }
      } else if (_loading) {
        // First load, cards are same or empty
        if (mounted) {
          setState(() {
            _cards = cards;
            _loading = false;
            if (cards.isEmpty) {
              _error = null;
            }
          });
          if (cards.isNotEmpty) {
            _startAutoScroll();
          }
        }
      }
      _retryCount = 0; // Reset on success
    } catch (e) {
      _retryCount++;

      if (mounted) {
        setState(() {
          _loading = false;
          if (_cards.isEmpty) {
            // Only show error if we have no cached data
            _error =
                'Unable to load cards. ${_retryCount < _maxRetries ? "Retrying..." : "Please check your connection."}';
          }
        });
      }

      // Retry with exponential backoff
      if (_retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: 2 * _retryCount));
        if (mounted) {
          _fetchCardsWithRest();
        }
      }
    }
  }

  bool _areCardListsEqual(List<ScrollCardModel> a, List<ScrollCardModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].image != b[i].image ||
          a[i].title != b[i].title ||
          a[i].description != b[i].description) {
        return false;
      }
    }
    return true;
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_cards.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients &&
          !_isUserInteracting &&
          _cards.isNotEmpty) {
        if (_currentPage < _cards.length - 1) {
          _currentPage++;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _currentPage = 0;
          _pageController.jumpToPage(0);
        }
      }
    });
  }

  void _onUserInteractionStart() {
    setState(() {
      _isUserInteracting = true;
    });
    _resumeTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _pollingTimer?.cancel();
    _cardsSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.height * 0.4;
    if (_loading) {
      return const Center(child: ScrollCardSkeleton());
    }
    if (_error != null && _cards.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                    _retryCount = 0;
                  });
                  _fetchCardsWithRest();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_cards.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: const Center(child: Text('No cards available.')),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: GestureDetector(
            onPanStart: (_) => _onUserInteractionStart(),
            onPanEnd: (_) => _onUserInteractionEnd(),
            onPanCancel: () => _onUserInteractionEnd(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                final String image = card.image;
                final String title = card.title;
                final String description = card.description;

                ImageProvider imageProvider;
                if (image.isNotEmpty &&
                    (image.startsWith('http://') ||
                        image.startsWith('https://'))) {
                  imageProvider = NetworkImage(image);
                } else if (image.isNotEmpty && image.startsWith('assets/')) {
                  imageProvider = AssetImage(image);
                } else {
                  imageProvider = const AssetImage(
                    'assets/Elements/placeholder.jpg',
                  );
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Unbounded',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Unbounded',
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black,
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
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _cards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 12 : 8,
              height: _currentPage == index ? 12 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Colors.black
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
