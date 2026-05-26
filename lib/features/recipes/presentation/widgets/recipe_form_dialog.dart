import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/recipe_model.dart';

Future<RecipeModel?> showRecipeFormDialog(
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
    required BuildContext context,
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

  Widget buildPrepTimeControl(
    BuildContext context,
    void Function(void Function()) setState,
  ) {
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
                          buildPrepTimeControl(context, setState),
                          const SizedBox(height: 16),
                          buildSectionTitle(
                            context: context,
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
                            context: context,
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

                    if (ingredientsError != null || instructionsError != null) {
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

    return result;
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
