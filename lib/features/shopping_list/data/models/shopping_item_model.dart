import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItemModel {
  const ShoppingItemModel({
    this.id,
    this.userId,
    required this.title,
    required this.quantity,
    required this.isPurchased,
    required this.createdAt,
  });

  final String? id;
  final String? userId;
  final String title;
  final String quantity;
  final bool isPurchased;
  final DateTime createdAt;

  factory ShoppingItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return ShoppingItemModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      quantity: (data['quantity'] as String?) ?? '',
      isPurchased: (data['isPurchased'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'userId': userId,
      'quantity': quantity,
      'isPurchased': isPurchased,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ShoppingItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? quantity,
    bool? isPurchased,
    DateTime? createdAt,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static ShoppingItemModel sample() {
    return ShoppingItemModel(
      title: 'Tomate',
      quantity: '2 kg',
      isPurchased: false,
      createdAt: DateTime.now(),
    );
  }
}
