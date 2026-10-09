import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/food_category.dart';
import 'meal_category_card.dart';

class MealCategoryHorizontalList extends StatelessWidget {
  const MealCategoryHorizontalList({super.key});

  static const List<MealCategoryItem> _items = [
    MealCategoryItem(
      labelKey: 'pairing_meat',
      food: FoodCategory.meat,
      backgroundColor: Color(0xFF6B1F32),
      svgAsset: 'assets/ic_meat.svg',
      fallbackIcon: Icons.restaurant,
    ),
    MealCategoryItem(
      labelKey: 'pairing_pasta',
      food: FoodCategory.pasta,
      backgroundColor: Color(0xFFC86438),
      fallbackIcon: Icons.ramen_dining,
    ),
    MealCategoryItem(
      labelKey: 'pairing_cheese',
      food: FoodCategory.cheese,
      backgroundColor: Color(0xFFCFA035),
      fallbackIcon: Icons.lunch_dining,
    ),
    MealCategoryItem(
      labelKey: 'pairing_sushi',
      food: FoodCategory.seafood,
      backgroundColor: Color(0xFF2C5570),
      fallbackIcon: Icons.set_meal,
    ),
    MealCategoryItem(
      labelKey: 'pairing_salad',
      food: FoodCategory.vegetarian,
      backgroundColor: Color(0xFF38633F),
      fallbackIcon: Icons.rice_bowl,
    ),
    MealCategoryItem(
      labelKey: 'pairing_poultry',
      food: FoodCategory.poultry,
      backgroundColor: Color(0xFFA0522D),
      fallbackIcon: Icons.egg_alt,
    ),
    MealCategoryItem(
      labelKey: 'pairing_pork',
      food: FoodCategory.pork,
      backgroundColor: Color(0xFF9E4B5B),
      fallbackIcon: Icons.kebab_dining,
    ),
    MealCategoryItem(
      labelKey: 'pairing_dessert',
      food: FoodCategory.dessert,
      backgroundColor: Color(0xFF6A3F7A),
      fallbackIcon: Icons.cake,
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
