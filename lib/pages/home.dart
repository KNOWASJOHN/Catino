import 'package:flutter/material.dart';
import 'package:cantino/components/usercard.dart';
import 'package:cantino/page_components/foodsection.dart';
import 'package:cantino/components/scroll_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 100), // Same effect as before
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// TOP USER CARD
              const UserCard(),

              const SizedBox(height: 20),

              /// FOOD SECTION BELOW USER CARD
              const FoodSection(),
              const SizedBox(height: 20),
              const Scrollcard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
