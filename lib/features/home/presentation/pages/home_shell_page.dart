import 'package:flutter/material.dart';
import 'package:flutter_recipes/core/auth/auth_service.dart';
import 'package:flutter_recipes/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:flutter_recipes/features/recipes/presentation/pages/recipes_page.dart';
import 'package:flutter_recipes/features/shopping_list/data/repositories/shopping_list_repository_impl.dart';
import 'package:flutter_recipes/features/shopping_list/presentation/pages/shopping_list_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({
    super.key,
    required this.authService,
    required this.recipeRepository,
    required this.userId,
  });

  final AuthService authService;
  final RecipeRepository recipeRepository;
  final String userId;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _currentIndex = 0;
  late final shoppingListRepository = ShoppingListRepositoryImpl();

  @override
  Widget build(BuildContext context) {
    final pages = [
      RecipesPage(
        recipeRepository: widget.recipeRepository,
        userId: widget.userId,
        onLogout: widget.authService.signOut,
      ),
      ShoppingListPage(
        shoppingListRepository: shoppingListRepository,
        userId: widget.userId,
        onLogout: widget.authService.signOut,
      ),
    ];

    return Scaffold(
      // empilha as telas
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Receitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Compras',
          ),
        ],
      ),
    );
  }
}
