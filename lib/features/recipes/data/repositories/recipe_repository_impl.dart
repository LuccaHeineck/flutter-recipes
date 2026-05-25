import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../../domain/repositories/recipe_repository.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'recipes';

  @override
  Future<void> addRecipe(RecipeModel recipe) async {
    await _firestore.collection(_collection).add(recipe.toMap());
  }

  @override
  Future<void> updateRecipe(RecipeModel recipe) async {
    final id = recipe.id;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Recipe id is required to update a recipe.');
    }

    await _firestore.collection(_collection).doc(id).set(recipe.toMap());
  }

  @override
  Stream<List<RecipeModel>> watchRecipes(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final recipes = snap.docs
              .map(RecipeModel.fromFirestore)
              .toList(growable: false);

          return recipes
            ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
        });
  }

  @override
  Future<List<RecipeModel>> getAllRecipes(String userId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final recipes = snap.docs
        .map(RecipeModel.fromFirestore)
        .toList(growable: false);

    return recipes
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
