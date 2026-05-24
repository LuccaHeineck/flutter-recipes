import '../../data/models/recipe_model.dart';

abstract class RecipeRepository {
  Future<void> addRecipe(RecipeModel recipe);
  Future<void> updateRecipe(RecipeModel recipe);
  Stream<List<RecipeModel>> watchRecipes();
  Future<List<RecipeModel>> getAllRecipes();
  Future<void> deleteRecipe(String id);
}
