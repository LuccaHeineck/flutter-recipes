import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/shopping_item_model.dart';
import '../../domain/repositories/shopping_list_repository.dart';

class ShoppingListPage extends StatelessWidget {
  const ShoppingListPage({
    super.key,
    required this.shoppingListRepository,
    required this.userId,
    this.onLogout,
  });

  final ShoppingListRepository shoppingListRepository;
  final String userId;
  final Future<void> Function()? onLogout;

  Future<void> _saveItem(
    ScaffoldMessengerState messenger,
    ShoppingItemModel item,
  ) async {
    try {
      final scopedItem = item.copyWith(userId: userId);

      if (item.id == null) {
        await shoppingListRepository.addItem(scopedItem);
      } else {
        await shoppingListRepository.updateItem(scopedItem);
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Item salvo com sucesso.')),
      );
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Falha ao salvar item.')),
      );
    }
  }

  Future<void> _deleteItem(
    ScaffoldMessengerState messenger,
    ShoppingItemModel item,
  ) async {
    try {
      await shoppingListRepository.deleteItem(item.id!);
      messenger.showSnackBar(const SnackBar(content: Text('Item excluído.')));
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Falha ao excluir item.')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ShoppingItemModel item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir item'),
          content: Text('Deseja excluir "${item.title}"?'),
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
      await _deleteItem(messenger, item);
    }
  }

  Future<void> _openItemForm(
    BuildContext context, {
    ShoppingItemModel? item,
  }) async {
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController(text: item?.title ?? '');
    final quantityController = TextEditingController(
      text: item?.quantity ?? '',
    );
    bool isPurchased = item?.isPurchased ?? false;

    try {
      final result = await showDialog<ShoppingItemModel>(
        context: context,
        builder: (dialogContext) {
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          final maxDialogWidth = kIsWeb ? 560.0 : 420.0;
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
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(
                        ShoppingItemModel(
                          id: item?.id,
                          title: titleController.text.trim(),
                          quantity: quantityController.text.trim(),
                          isPurchased: isPurchased,
                          createdAt: item?.createdAt ?? DateTime.now(),
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
        await _saveItem(messenger, result);
      }
    } finally {
      titleController.dispose();
      quantityController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = shoppingListRepository.watchItems(userId);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
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
        onPressed: () => _openItemForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo item'),
      ),
      body: StreamBuilder<List<ShoppingItemModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar itens.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('Nenhum item ainda. Toque em + para adicionar.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: items.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openItemForm(context, item: item),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isPurchased,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            _saveItem(
                              ScaffoldMessenger.of(context),
                              item.copyWith(isPurchased: value),
                            );
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(item.quantity),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Ações do item',
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _openItemForm(context, item: item);
                                break;
                              case 'delete':
                                _confirmDelete(context, item);
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir'),
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
