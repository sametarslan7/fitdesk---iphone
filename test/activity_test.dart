import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitdesk/core/data/activity.dart';
import 'package:fitdesk/core/data/exercise_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final neck = ExerciseCatalog.byId('neck_side_stretch')!;
  final eyes = ExerciseCatalog.byId('eye_20_20_20')!;
  final shoulder = ExerciseCatalog.byId('shoulder_rolls')!;

  /// 21 Ekim 2026 Çarşamba; hafta 19 Ekim Pazartesi başlar.
  final wednesday = DateTime(2026, 10, 21, 15);

  ActivityController sample() => ActivityController()
    ..record(neck, at: DateTime(2026, 10, 10, 9)) // önceki önceki hafta
    ..record(neck, at: DateTime(2026, 10, 16, 9)) // geçen Cuma
    ..record(neck, at: DateTime(2026, 10, 19, 9))
    ..record(neck, at: DateTime(2026, 10, 19, 14))
    ..record(eyes, at: DateTime(2026, 10, 20, 11))
    ..record(shoulder, at: DateTime(2026, 10, 21, 10));

  test('Haftalık sayılar, bugün ve toplamlar kayıttan hesaplanır', () {
    final activity = sample();
    expect(activity.weekCounts(wednesday), [2, 1, 1, 0, 0, 0, 0]);
    expect(activity.today(wednesday).single.exercise, shoulder);
    expect(activity.total, 6);
    expect(
      activity.totalSeconds,
      4 * neck.durationSeconds +
          eyes.durationSeconds +
          shoulder.durationSeconds,
    );
  });

  test('Seri bugün egzersiz yoksa dünden sayılır, boşlukta kopar', () {
    final activity = sample();
    expect(activity.currentStreak(wednesday), 3);
    expect(activity.currentStreak(DateTime(2026, 10, 22, 8)), 3);
    expect(activity.currentStreak(DateTime(2026, 10, 23, 8)), 0);
    expect(activity.longestStreak, 3);
    expect(activity.weeklyPeak, 4);
  });

  test('Bu ayın bölgeleri çoktan aza sıralanır', () {
    final top = sample().topAreasThisMonth(wednesday);
    expect(top.length, 3);
    expect(top.first.area.id, BodyAreas.neck.id);
    expect(top.first.count, 4);
    expect(sample().topAreasThisMonth(DateTime(2026, 11, 2)), isEmpty);
  });

  test('Rozetler koşullar sağlanınca kazanılır', () {
    final empty = ActivityController();
    expect(empty.badges(5).where((b) => b.earned), isEmpty);

    final activity = sample();
    var badges = activity.badges(1);
    expect(badges[0].earned, isTrue); // İlk Adım
    expect(badges[1].earned, isFalse); // Göz Dinlendirici
    expect(badges[2].earned, isFalse); // Haftalık Şampiyon

    // 12–18 Ekim haftasının her günü hedef (1) tutturulur.
    for (var day = 12; day <= 18; day++) {
      activity.record(eyes, at: DateTime(2026, 10, day, 10));
    }
    badges = activity.badges(1);
    expect(badges[1].earned, isFalse);
    expect(badges[2].earned, isTrue);
    expect(activity.badges(2)[2].earned, isFalse);
  });

  test('Kayıt cihaza yazılır ve yeniden yüklenir', () async {
    sample();
    await pumpEventQueue();
    final reloaded = ActivityController();
    await reloaded.load();
    expect(reloaded.total, 6);
    expect(reloaded.weekCounts(wednesday), [2, 1, 1, 0, 0, 0, 0]);
  });
}
