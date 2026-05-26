import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_recipes/features/recipes/data/models/recipe_model.dart';
import 'package:flutter_recipes/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:flutter_recipes/features/recipes/presentation/widgets/recipe_form_dialog.dart';
import 'package:flutter_recipes/features/recipes/presentation/widgets/recipe_list_item.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({
    super.key,
    required this.recipeRepository,
    required this.userId,
    this.onLogout,
  });

  final RecipeRepository recipeRepository;
  final String userId;
  final Future<void> Function()? onLogout;

  Future<void> _saveRecipe(
    ScaffoldMessengerState messenger,
    RecipeModel recipe,
  ) async {
    try {
      final scopedRecipe = recipe.copyWith(userId: userId);

      if (recipe.id == null) {
        await recipeRepository.addRecipe(scopedRecipe);
      } else {
        await recipeRepository.updateRecipe(scopedRecipe);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Receita salva com sucesso.')),
      );
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Falha ao salvar receita.')),
      );
    }
  }

  Future<void> _deleteRecipe(
    ScaffoldMessengerState messenger,
    RecipeModel recipe,
  ) async {
    try {
      await recipeRepository.deleteRecipe(recipe.id!);
      messenger.showSnackBar(
        const SnackBar(content: Text('Receita excluída.')),
      );
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Falha ao excluir receita.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, RecipeModel recipe) async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir receita'),
          content: Text('Deseja excluir "${recipe.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteRecipe(messenger, recipe);
    }
  }

  String _buildShareMessage(RecipeModel recipe) {
    final ingredientLines = recipe.ingredients
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => '- $item')
        .join('\n');

    final instructionLines = recipe.instructions
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final instructionsText = instructionLines
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');

    return [
      '🍽️ ${recipe.name}',
      'Categoria: ${recipe.category}',
      'Tempo de preparo: ${recipe.prepTimeMinutes} min',
      '',
      'Ingredientes:',
      ingredientLines,
      '',
      'Modo de preparo:',
      instructionsText,
    ].join('\n');
  }

  Future<void> _shareRecipe(
    ScaffoldMessengerState messenger,
    RecipeModel recipe,
  ) async {
    try {
      await Share.share(
        _buildShareMessage(recipe),
        subject: 'Receita: ${recipe.name}',
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel compartilhar a receita.'),
        ),
      );
    }
  }

  Future<void> _openRecipeForm(
    BuildContext context, {
    RecipeModel? recipe,
  }) async {
    final result = await showRecipeFormDialog(context, recipe: recipe);
    final messenger = ScaffoldMessenger.of(context);

    if (result != null) {
      await _saveRecipe(messenger, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = recipeRepository.watchRecipes(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        actions: [
          if (onLogout != null)
            IconButton(
              onPressed: onLogout,
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecipeForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova receita'),
      ),
      body: StreamBuilder<List<RecipeModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar receitas.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!;
          if (recipes.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma receita desta conta ainda. Clique para criar uma.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: recipes.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final messenger = ScaffoldMessenger.of(context);

              return RecipeListItem(
                recipe: recipe,
                onTap: () => _openRecipeForm(context, recipe: recipe),
                onEdit: () => _openRecipeForm(context, recipe: recipe),
                onDelete: () => _confirmDelete(context, recipe),
                onShare: () => _shareRecipe(messenger, recipe),
              );
            },
          );
        },
      ),
    );
  }
}
