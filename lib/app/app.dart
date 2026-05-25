import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_recipes/core/auth/auth_service.dart';
import 'package:flutter_recipes/features/auth/presentation/pages/auth_page.dart';
import 'package:flutter_recipes/features/home/presentation/pages/home_shell_page.dart';
import 'package:flutter_recipes/features/recipes/domain/repositories/recipe_repository.dart';

class RecipesApp extends StatelessWidget {
  const RecipesApp({super.key, required this.recipeRepository});

  final RecipeRepository recipeRepository;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Recipes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE76F51)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return HomeShellPage(
              authService: authService,
              recipeRepository: recipeRepository,
              userId: snapshot.data!.uid,
            );
          }

          return AuthPage(authService: authService);
        },
      ),
    );
  }
}
