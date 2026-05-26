import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../data/models/shopping_item_model.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../widgets/shopping_item_form_dialog.dart';
import '../widgets/shopping_list_item.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    final result = await showShoppingItemFormDialog(context, item: item);

    if (result != null) {
      await _saveItem(messenger, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = shoppingListRepository.watchItems(userId);

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

              return ShoppingListItem(
                item: item,
                onTap: () => _openItemForm(context, item: item),
                onTogglePurchased: (value) => _saveItem(
                  ScaffoldMessenger.of(context),
                  item.copyWith(isPurchased: value),
                ),
                onEdit: () => _openItemForm(context, item: item),
                onDelete: () => _confirmDelete(context, item),
              );
            },
          );
        },
      ),
    );
  }
}
