import '../../data/models/shopping_item_model.dart';

abstract class ShoppingListRepository {
  Future<void> addItem(ShoppingItemModel item);
  Future<void> updateItem(ShoppingItemModel item);
  Stream<List<ShoppingItemModel>> watchItems(String userId);
  Future<List<ShoppingItemModel>> getAllItems(String userId);
  Future<void> deleteItem(String id);
}
