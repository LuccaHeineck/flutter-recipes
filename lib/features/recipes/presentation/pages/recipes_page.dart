import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_recipes/features/recipes/data/models/recipe_model.dart';
import 'package:flutter_recipes/features/recipes/domain/repositories/recipe_repository.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key, required this.recipeRepository});

  final RecipeRepository recipeRepository;

  Future<void> _saveRecipe(
    ScaffoldMessengerState messenger,
    RecipeModel recipe,
  ) async {
    try {
      if (recipe.id == null) {
        await recipeRepository.addRecipe(recipe);
      } else {
        await recipeRepository.updateRecipe(recipe);
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

  Future<void> _openRecipeForm(
    BuildContext context, {
    RecipeModel? recipe,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController(text: recipe?.name ?? '');
    final categoryController = TextEditingController(
      text: recipe?.category ?? 'geral',
    );
    final ingredientsController = TextEditingController(
      text: recipe?.ingredients.join('\n') ?? '',
    );
    final instructionsController = TextEditingController(
      text: recipe?.instructions ?? '',
    );
    final prepTimeController = TextEditingController(
      text: recipe?.prepTimeMinutes.toString() ?? '',
    );

    try {
      final result = await showDialog<RecipeModel>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(recipe == null ? 'Nova receita' : 'Editar receita'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  TextField(
                    controller: prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tempo de preparo (min)',
                    ),
                  ),
                  TextField(
                    controller: ingredientsController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Ingredientes',
                      hintText: 'Um ingrediente por linha',
                    ),
                  ),
                  TextField(
                    controller: instructionsController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'Instruções'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    return;
                  }

                  final ingredients = ingredientsController.text
                      .split(RegExp(r'[\n,]'))
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(growable: false);

                  final prepTime =
                      int.tryParse(prepTimeController.text.trim()) ?? 0;

                  Navigator.of(dialogContext).pop(
                    RecipeModel(
                      id: recipe?.id,
                      name: name,
                      category: categoryController.text.trim().isEmpty
                          ? 'geral'
                          : categoryController.text.trim(),
                      ingredients: ingredients,
                      instructions: instructionsController.text.trim(),
                      prepTimeMinutes: prepTime,
                      createdAt: recipe?.createdAt ?? DateTime.now(),
                    ),
                  );
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );

      if (result != null) {
        await _saveRecipe(messenger, result);
      }
    } finally {
      nameController.dispose();
      categoryController.dispose();
      ingredientsController.dispose();
      instructionsController.dispose();
      prepTimeController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = recipeRepository.watchRecipes();

    return Scaffold(
      appBar: AppBar(title: const Text('Receitas')),
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
                'Nenhuma receita ainda. Clique para criar um exemplo.',
              ),
            );
          }

          return ListView.separated(
            itemCount: recipes.length,
            separatorBuilder: (context, _) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                onTap: () => _openRecipeForm(context, recipe: recipe),
                title: Text(recipe.name),
                subtitle: Text(
                  '${recipe.category} - ${recipe.prepTimeMinutes} min',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _openRecipeForm(context, recipe: recipe);
                        break;
                      case 'delete':
                        _confirmDelete(context, recipe);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
