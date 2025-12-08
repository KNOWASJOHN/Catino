import 'package:flutter/material.dart';

class FoodSection extends StatelessWidget {
  const FoodSection({super.key});

  Widget foodBox(
    String name,
    String imagePath,
    String description,
    double price,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 5,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w100,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 5,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                '\₹ ${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.limeAccent,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 5,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // <-- REQUIRED
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      padding: const EdgeInsets.all(8.0),
      children: [
        foodBox(
          "Burger",
          "assets/Elements/burger.jpg",
          "Delicious beef burger",
          12.99,
        ),
        foodBox(
          "Pizza",
          "assets/Elements/pizza.jpg",
          "Cheesy pepperoni pizza",
          15.99,
        ),
        foodBox(
          "Juice",
          "assets/Elements/juice.jpg",
          "Fresh orange juice",
          5.99,
        ),
        foodBox(
          "Fruits",
          "assets/Elements/burger.jpg",
          "Mixed fruit platter",
          8.99,
        ),
      ],
    );
  }
}
