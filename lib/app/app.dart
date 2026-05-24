import 'package:flutter/material.dart';
import 'package:flutter_recipes/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:flutter_recipes/features/recipes/presentation/pages/recipes_page.dart';

class RecipesApp extends StatelessWidget {
  const RecipesApp({super.key, required this.recipeRepository});

  final RecipeRepository recipeRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Recipes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE76F51)),
        useMaterial3: true,
      ),
      home: RecipesPage(recipeRepository: recipeRepository),
    );
  }
}
