import 'package:flutter/material.dart';

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

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
  bool _isUserInteracting = false;

  List<ScrollCardModel> _cards = [];
  List<ScrollCardModel> _cachedCards = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _cardsSubscription;


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _listenToScrollCards();
  }

  void _listenToScrollCards() {
    final ref = FirebaseDatabase.instance.ref('scroll_cards');
    _cardsSubscription = ref.onValue.listen((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<ScrollCardModel> cards = [];
        data.forEach((key, value) {
          if (value != null) {
            cards.add(ScrollCardModel.fromMap(value));
          }
        });
        // Compare with cache
        if (!_areCardListsEqual(cards, _cachedCards)) {
          setState(() {
            _cards = cards;
            _cachedCards = List<ScrollCardModel>.from(cards);
            _loading = false;
            _error = null;
          });
          _startAutoScroll();
        }
      } else {
        setState(() {
          _loading = false;
          _error = 'No cards found.';
          _cards = [];
          _cachedCards = [];
        });
      }
    }, onError: (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load cards: $e';
      });
    });
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
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && !_isUserInteracting && _cards.isNotEmpty) {
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
      setState(() {
        _isUserInteracting = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    _cardsSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.height * 0.4;
    if (_loading) {
      return SizedBox(
        height: cardHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: cardHeight,
        child: Center(child: Text(_error!)),
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

                // Always fetch from Firebase (network), fallback to placeholder if empty
                ImageProvider imageProvider;
                if (image.isNotEmpty && (image.startsWith('http://') || image.startsWith('https://'))) {
                  imageProvider = NetworkImage(image);
                } else if (image.isNotEmpty && image.startsWith('assets/')) {
                  imageProvider = AssetImage(image);
                } else {
                  imageProvider = const AssetImage('assets/Elements/placeholder.jpg');
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
