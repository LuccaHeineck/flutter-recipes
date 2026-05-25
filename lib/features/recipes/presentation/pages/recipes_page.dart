import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_recipes/features/recipes/data/models/recipe_model.dart';
import 'package:flutter_recipes/features/recipes/domain/repositories/recipe_repository.dart';

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
    final formKey = GlobalKey<FormState>();
    final categoryOptions = [
      'geral',
      'entrada',
      'prato principal',
      'sobremesa',
      'bebida',
    ];
    final initialCategory = (recipe?.category.trim().isNotEmpty ?? false)
        ? recipe!.category.trim()
        : 'geral';
    String selectedCategory = categoryOptions.contains(initialCategory)
        ? initialCategory
        : 'geral';
    int prepTime = (recipe?.prepTimeMinutes ?? 30).clamp(1, 1440);
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController(text: recipe?.name ?? '');
    final ingredientControllers =
        ((recipe?.ingredients.isNotEmpty ?? false)
                ? recipe!.ingredients
                : const <String>[''])
            .map((value) => TextEditingController(text: value))
            .toList(growable: true);
    final instructionControllers =
        ((recipe?.instructions ?? '')
                    .split('\n')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList(growable: false)
                    .isNotEmpty
                ? (recipe?.instructions ?? '')
                      .split('\n')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(growable: false)
                : const <String>[''])
            .map((value) => TextEditingController(text: value))
            .toList(growable: true);

    void addIngredientField(void Function(void Function()) setState) {
      setState(() {
        ingredientControllers.add(TextEditingController());
      });
    }

    void addInstructionField(void Function(void Function()) setState) {
      setState(() {
        instructionControllers.add(TextEditingController());
      });
    }

    void removeIngredientField(
      int index,
      void Function(void Function()) setState,
    ) {
      if (ingredientControllers.length == 1) {
        return;
      }
      setState(() {
        final controller = ingredientControllers.removeAt(index);
        controller.dispose();
      });
    }

    void removeInstructionField(
      int index,
      void Function(void Function()) setState,
    ) {
      if (instructionControllers.length == 1) {
        return;
      }
      setState(() {
        final controller = instructionControllers.removeAt(index);
        controller.dispose();
      });
    }

    Widget buildSectionTitle({
      required String title,
      required VoidCallback onAdd,
      required String addLabel,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
          ],
        ),
      );
    }

    Widget buildPrepTimeControl(void Function(void Function()) setState) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tempo de preparo (min)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  prepTime = (prepTime - 5).clamp(1, 1440);
                });
              },
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Text(
                '$prepTime min',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  prepTime = (prepTime + 5).clamp(1, 1440);
                });
              },
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      );
    }

    Widget buildDynamicFieldList({
      required List<TextEditingController> controllers,
      required String labelPrefix,
      required int minLines,
      required int maxLines,
      required void Function(int index) onRemove,
    }) {
      return Column(
        children: List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],
                    minLines: minLines,
                    maxLines: maxLines,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: '$labelPrefix ${index + 1}',
                    ),
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    onPressed: () => onRemove(index),
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Remover',
                    padding: const EdgeInsets.only(top: 4),
                  ),
              ],
            ),
          );
        }),
      );
    }

    try {
      final result = await showDialog<RecipeModel>(
        context: context,
        builder: (dialogContext) {
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          final maxDialogWidth = kIsWeb ? 720.0 : 460.0;
          final dialogWidth =
              (screenWidth - 48).clamp(280.0, maxDialogWidth) as double;
          final fieldBorder = OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          );
          String? ingredientsError;
          String? instructionsError;

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(recipe == null ? 'Nova receita' : 'Editar receita'),
                content: SizedBox(
                  width: dialogWidth,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: fieldBorder,
                        enabledBorder: fieldBorder.copyWith(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: fieldBorder.copyWith(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.6,
                          ),
                        ),
                        errorBorder: fieldBorder.copyWith(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        focusedErrorBorder: fieldBorder.copyWith(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome da receita.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                              ),
                              items: categoryOptions
                                  .map(
                                    (category) => DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedCategory = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 16),
                            buildPrepTimeControl(setState),
                            const SizedBox(height: 16),
                            buildSectionTitle(
                              title: 'Ingredientes',
                              addLabel: 'Adicionar',
                              onAdd: () => addIngredientField(setState),
                            ),
                            buildDynamicFieldList(
                              controllers: ingredientControllers,
                              labelPrefix: 'Ingrediente',
                              minLines: 1,
                              maxLines: 2,
                              onRemove: (index) =>
                                  removeIngredientField(index, setState),
                            ),
                            if (ingredientsError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  ingredientsError!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            buildSectionTitle(
                              title: 'Passos',
                              addLabel: 'Novo passo',
                              onAdd: () => addInstructionField(setState),
                            ),
                            buildDynamicFieldList(
                              controllers: instructionControllers,
                              labelPrefix: 'Passo',
                              minLines: 1,
                              maxLines: 4,
                              onRemove: (index) =>
                                  removeInstructionField(index, setState),
                            ),
                            if (instructionsError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  instructionsError!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final ingredients = ingredientControllers
                          .map((controller) => controller.text.trim())
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(growable: false);

                      final instructions = instructionControllers
                          .map((controller) => controller.text.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(growable: false);

                      setState(() {
                        ingredientsError = ingredients.isEmpty
                            ? 'Adicione ao menos um ingrediente.'
                            : null;
                        instructionsError = instructions.isEmpty
                            ? 'Adicione ao menos um passo de preparo.'
                            : null;
                      });

                      if (ingredientsError != null ||
                          instructionsError != null) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(
                        RecipeModel(
                          id: recipe?.id,
                          name: nameController.text.trim(),
                          category: selectedCategory,
                          ingredients: ingredients,
                          instructions: instructions.join('\n'),
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
        },
      );

      if (result != null) {
        await _saveRecipe(messenger, result);
      }
    } finally {
      nameController.dispose();
      for (final controller in ingredientControllers) {
        controller.dispose();
      }
      for (final controller in instructionControllers) {
        controller.dispose();
      }
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
              final ingredientCount = recipe.ingredients.length;
              final messenger = ScaffoldMessenger.of(context);

              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openRecipeForm(context, recipe: recipe),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Ações da receita',
                              onSelected: (value) {
                                switch (value) {
                                  case 'share':
                                    _shareRecipe(messenger, recipe);
                                    break;
                                  case 'edit':
                                    _openRecipeForm(context, recipe: recipe);
                                    break;
                                  case 'delete':
                                    _confirmDelete(context, recipe);
                                    break;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'share',
                                  child: Text('Compartilhar'),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Excluir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                              ),
                              child: Text(
                                recipe.category,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${recipe.prepTimeMinutes} min',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Theme.of(
                                  context,
                                ).colorScheme.tertiaryContainer,
                              ),
                              child: Text(
                                '$ingredientCount ingredientes',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
