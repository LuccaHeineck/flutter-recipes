import 'package:flutter/material.dart';

import '../../data/models/shopping_item_model.dart';

class ShoppingListItem extends StatelessWidget {
  const ShoppingListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onTogglePurchased,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingItemModel item;
  final VoidCallback onTap;
  final ValueChanged<bool> onTogglePurchased;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Row(
            children: [
              Checkbox(
                value: item.isPurchased,
                onChanged: (value) {
                  if (value == null) return;
                  onTogglePurchased(value);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
