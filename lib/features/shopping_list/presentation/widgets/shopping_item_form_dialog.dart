import 'package:flutter/material.dart';

import '../../data/models/shopping_item_model.dart';

Future<ShoppingItemModel?> showShoppingItemFormDialog(
  BuildContext context, {
  ShoppingItemModel? item,
}) async {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: item?.title ?? '');
  final quantityController = TextEditingController(text: item?.quantity ?? '');
  bool isPurchased = item?.isPurchased ?? false;

  try {
    final result = await showDialog<ShoppingItemModel>(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.sizeOf(dialogContext).width;
        final maxDialogWidth = 560.0;
        final dialogWidth =
            (screenWidth - 48).clamp(280.0, maxDialogWidth) as double;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(item == null ? 'Novo item' : 'Editar item'),
              content: SizedBox(
                width: dialogWidth,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Item',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o item.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a quantidade.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Comprado'),
                        value: isPurchased,
                        onChanged: (value) {
                          setState(() {
                            isPurchased = value;
                          });
                        },
                      ),
                    ],
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
                    if (!formKey.currentState!.validate()) return;

                    Navigator.of(dialogContext).pop(
                      ShoppingItemModel(
                        id: item?.id,
                        title: titleController.text.trim(),
                        quantity: quantityController.text.trim(),
                        isPurchased: isPurchased,
                        createdAt: item?.createdAt ?? DateTime.now(),
                        userId: item?.userId,
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
    titleController.dispose();
    quantityController.dispose();
  }
}
