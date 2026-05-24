import 'package:flutter/material.dart';
import 'package:flutter_recipes/app/app.dart';
import 'package:flutter_recipes/core/firebase/firebase_initializer.dart';
import 'package:flutter_recipes/features/recipes/data/repositories/recipe_repository_impl.dart';
import 'package:flutter_recipes/features/recipes/domain/repositories/recipe_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<void> _bootstrapFuture = _bootstrap();
  RecipeRepository? _recipeRepository;

  Future<void> _bootstrap() async {
    await FirebaseInitializer.initialize();
    _recipeRepository = RecipeRepositoryImpl();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Falha ao inicializar o app.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RecipesApp(recipeRepository: _recipeRepository!);
      },
    );
  }
}
