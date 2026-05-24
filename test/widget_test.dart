import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_recipes/features/recipes/data/models/recipe_model.dart';

void main() {
  test('sample recipe model has expected data', () {
    final sample = RecipeModel.sample();

    expect(sample.name, isNotEmpty);
    expect(sample.ingredients, isNotEmpty);
    expect(sample.prepTimeMinutes, greaterThan(0));
    expect(sample.toMap().containsKey('createdAt'), isTrue);
  });
}
