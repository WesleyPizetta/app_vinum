import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import 'meal_category_card.dart';

class MealCategoryHorizontalList extends StatelessWidget {
  const MealCategoryHorizontalList({super.key});

  static const List<MealCategoryItem> _items = [
    MealCategoryItem(
      labelKey: 'pairing_meat',
      backgroundColor: Color(0xFF6B1F32),
      svgAsset: 'assets/ic_meat.svg',
      fallbackIcon: Icons.restaurant,
    ),
    MealCategoryItem(
      labelKey: 'pairing_pasta',
      backgroundColor: Color(0xFFC86438),
      fallbackIcon: Icons.ramen_dining,
    ),
    MealCategoryItem(
      labelKey: 'pairing_cheese',
      backgroundColor: Color(0xFFCFA035),
      fallbackIcon: Icons.lunch_dining,
    ),
    MealCategoryItem(
      labelKey: 'pairing_sushi',
      backgroundColor: Color(0xFF2C5570),
      fallbackIcon: Icons.set_meal,
    ),
    MealCategoryItem(
      labelKey: 'pairing_salad',
      backgroundColor: Color(0xFF38633F),
      fallbackIcon: Icons.rice_bowl,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimens.spacing12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return MealCategoryCard(item: item);
        },
      ),
    );
  }
}
