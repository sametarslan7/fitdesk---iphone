import 'package:flutter/widgets.dart';

import '../storage/app_prefs.dart';
import 'exercise_catalog.dart';

/// Kullanıcının favori egzersizleri; cihazda saklanır.
class FavoritesController extends ChangeNotifier {
  /// Eklenme sırasını korur (son eklenen sonda).
  final _ids = <String>{};

  Future<void> load() async {
    final saved = await AppPrefs.favoriteExerciseIds();
    // Katalogdan kaldırılmış egzersizler sessizce düşer.
    _ids
      ..clear()
      ..addAll(saved.where((id) => ExerciseCatalog.byId(id) != null));
    notifyListeners();
  }

  bool contains(Exercise exercise) => _ids.contains(exercise.id);

  List<Exercise> get exercises => [
    for (final id in _ids) ?ExerciseCatalog.byId(id),
  ];

  void toggle(Exercise exercise) {
    if (!_ids.remove(exercise.id)) _ids.add(exercise.id);
    notifyListeners();
    AppPrefs.setFavoriteExerciseIds(_ids.toList());
  }
}

/// Favorileri alt ağaca sağlar; değişince dinleyen sayfalar yeniden çizilir.
class FavoritesScope extends InheritedNotifier<FavoritesController> {
  const FavoritesScope({
    super.key,
    required FavoritesController controller,
    required super.child,
  }) : super(notifier: controller);

  static FavoritesController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FavoritesScope>()!.notifier!;
}
