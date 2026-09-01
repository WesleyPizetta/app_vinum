import 'package:flutter/material.dart';

class HighlightWine {
  final String id;
  final String name;
  final double rating;
  final String viewsCountLabel;
  final bool isFavorite;
  final Color bannerColor;

  const HighlightWine({
    required this.id,
    required this.name,
    required this.rating,
    required this.viewsCountLabel,
    this.isFavorite = false,
    required this.bannerColor,
  });

  HighlightWine copyWith({
    String? id,
    String? name,
    double? rating,
    String? viewsCountLabel,
    bool? isFavorite,
    Color? bannerColor,
  }) {
    return HighlightWine(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      viewsCountLabel: viewsCountLabel ?? this.viewsCountLabel,
      isFavorite: isFavorite ?? this.isFavorite,
      bannerColor: bannerColor ?? this.bannerColor,
    );
  }
}
