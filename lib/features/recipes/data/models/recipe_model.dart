import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeModel {
  const RecipeModel({
    this.id,
    required this.name,
    required this.category,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    required this.createdAt,
  });

  final String? id;
  final String name;
  final String category;
  final List<String> ingredients;
  final String instructions;
  final int prepTimeMinutes;
  final DateTime createdAt;

  factory RecipeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return RecipeModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'geral',
      ingredients: ((data['ingredients'] as List?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      instructions: (data['instructions'] as String?) ?? '',
      prepTimeMinutes: (data['prepTimeMinutes'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTimeMinutes': prepTimeMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RecipeModel copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? ingredients,
    String? instructions,
    int? prepTimeMinutes,
    DateTime? createdAt,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static RecipeModel sample() {
    return RecipeModel(
      name: 'Spaghetti Al Pomodoro',
      category: 'italiana',
      ingredients: const <String>[
        '400g de espaguete',
        '800g de tomate pelado',
        '2 dentes de alho',
        'Azeite de oliva',
        'Manjericao fresco',
        'Sal e pimenta',
      ],
      instructions:
          'Cozinhe o macarrao em agua com sal. Refogue alho no azeite, adicione tomate, cozinhe por 15 minutos, ajuste sal e pimenta. Misture com o espaguete e finalize com manjericao.',
      prepTimeMinutes: 30,
      createdAt: DateTime.now(),
    );
  }
}
