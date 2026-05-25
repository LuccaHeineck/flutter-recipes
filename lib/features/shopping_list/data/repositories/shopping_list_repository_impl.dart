import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/shopping_item_model.dart';
import '../../domain/repositories/shopping_list_repository.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  ShoppingListRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'shopping_items';

  @override
  Future<void> addItem(ShoppingItemModel item) async {
    await _firestore.collection(_collection).add(item.toMap());
  }

  @override
  Future<void> updateItem(ShoppingItemModel item) async {
    final id = item.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Shopping item id is required to update an item.');
    }

    await _firestore.collection(_collection).doc(id).set(item.toMap());
  }

  @override
  Stream<List<ShoppingItemModel>> watchItems(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map(ShoppingItemModel.fromFirestore)
              .toList(growable: false);

          return items
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
        });
  }

  @override
  Future<List<ShoppingItemModel>> getAllItems(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final items = snap.docs
        .map(ShoppingItemModel.fromFirestore)
        .toList(growable: false);

    return items
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<void> deleteItem(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
