import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Uygulamadaki egzersiz kataloğu. Şimdilik örnek içerik; gerçek içerik
/// mantığı (kaynak, güncelleme) ileride ayrıca ele alınacak.

class BodyArea {
  const BodyArea({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.description,
    required this.tip,
  });

  final String id;
  final String name;

  /// Kartta adın altındaki kısa açıklama ("Tutulma & Gerginlik").
  final String subtitle;
  final IconData icon;

  /// Bölge sayfasının üstündeki tanıtım metni.
  final String description;

  /// Bölge sayfasının altındaki fizyoterapist notu.
  final String tip;
}

enum Difficulty {
  veryEasy('Çok Kolay'),
  easy('Kolay'),
  medium('Orta');

  const Difficulty(this.label);
  final String label;
}

enum Posture {
  seated('Oturarak'),
  standing('Ayakta');

  const Posture(this.label);
  final String label;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.area,
    required this.durationSeconds,
    required this.difficulty,
    required this.posture,
    required this.summary,
    required this.steps,
    this.popular = false,
  });

  final String id;
  final String name;
  final BodyArea area;
  final int durationSeconds;
  final Difficulty difficulty;
  final Posture posture;

  /// Listede adın altında görünen tek cümle.
  final String summary;

  /// "Nasıl uygulanır?" adımları.
  final List<String> steps;

  /// Popüler listesinde gösterilir (favori yokken).
  final bool popular;
}

abstract final class BodyAreas {
  static const neck = BodyArea(
    id: 'neck',
    name: 'Boyun',
    subtitle: 'Tutulma & gerginlik',
    icon: Icons.airline_seat_recline_normal_rounded,
    description:
        'Gün boyu ekrana bakmaktan gerilen boyun ve trapez kaslarını '
        'gevşetmek için kısa, rahatlatıcı hareketler.',
    tip:
        'Esneme sırasında nefesini tutma, omuzlarını yukarı çekmeden rahat '
        'bırak. Ağrı değil, tatlı bir gerginlik hissetmelisin.',
  );

  static const shoulder = BodyArea(
    id: 'shoulder',
    name: 'Omuz',
    subtitle: 'Düşük omuz & trapez',
    icon: Icons.accessibility_new_rounded,
    description:
        'Klavyeye uzanırken öne düşen omuzları açan ve kürek kemiklerini '
        'hareketlendiren hareketler.',
    tip:
        'Hareketleri yavaş ve kontrollü yap. Omuzlarını kulaklarına doğru '
        'kaldırdığını fark edersen bilinçli olarak aşağı bırak.',
  );

  static const armHand = BodyArea(
    id: 'arm_hand',
    name: 'Kol & El',
    subtitle: 'Dolaşım & parmaklar',
    icon: Icons.fitness_center_rounded,
    description:
        'Uzun süre aynı pozisyonda kalan kolların ve parmakların kan '
        'dolaşımını canlandıran hareketler.',
    tip:
        'Parmaklarını zorlamadan aç ve kapat. Uyuşma ya da karıncalanma '
        'sürerse hareketi bırak.',
  );

  static const wrist = BodyArea(
    id: 'wrist',
    name: 'Bilek',
    subtitle: 'Fare & klavye yorgunluğu',
    icon: Icons.front_hand_outlined,
    description:
        'Fare ve klavye kullanımından yorulan bilekleri esneten, tendonları '
        'rahatlatan hareketler.',
    tip:
        'Bileğini esnetirken dirseğin düz ama kilitli olmasın. Keskin ağrı '
        'hissedersen gerilmeyi azalt.',
  );

  static const back = BodyArea(
    id: 'back',
    name: 'Sırt & Omurga',
    subtitle: 'Hizalama & açılma',
    icon: Icons.sports_gymnastics_rounded,
    description:
        'Kambur oturuşun etkisini azaltan, omurgayı uzatıp göğsü açan '
        'hareketler.',
    tip:
        'Dönme hareketlerinde kalçanı sandalyede sabit tut; hareket '
        'belden değil, sırtın ortasından gelsin.',
  );

  static const eyes = BodyArea(
    id: 'eyes',
    name: 'Gözler',
    subtitle: '20-20-20 dinlendirme',
    icon: Icons.visibility_outlined,
    description:
        'Ekrana odaklanmaktan yorulan gözleri dinlendiren ve odaklanmayı '
        'tazeleyen kısa egzersizler.',
    tip:
        'Göz egzersizlerinde gözlüğünü çıkarabilirsin. Gözlerin sulanır ya '
        'da yanarsa birkaç kez yavaşça kırp.',
  );

  static const lowerBack = BodyArea(
    id: 'lower_back',
    name: 'Bel & Kalça',
    subtitle: 'Oturma baskısını azalt',
    icon: Icons.airline_seat_legroom_extra_rounded,
    description:
        'Uzun süre oturmanın bel ve kalçada yarattığı baskıyı azaltan '
        'hareketler.',
    tip:
        'Belini esnetirken karın kaslarını hafifçe sık. Bel fıtığı gibi bir '
        'rahatsızlığın varsa hareketleri hekimine danış.',
  );

  static const posture = BodyArea(
    id: 'posture',
    name: 'Duruş & Postür',
    subtitle: 'Omurga dikleştirme',
    icon: Icons.self_improvement_rounded,
    description:
        'Dik oturma alışkanlığını destekleyen, duruş kaslarını uyandıran '
        'hareketler.',
    tip:
        'Ekranın üst kenarı göz hizanda, ayakların yere tam basar şekilde '
        'olsun. İyi duruş, egzersizin etkisini artırır.',
  );

  static const all = [
    neck,
    shoulder,
    armHand,
    wrist,
    back,
    eyes,
    lowerBack,
    posture,
  ];
}

abstract final class ExerciseCatalog {
  static const all = <Exercise>[
    // Boyun
    Exercise(
      id: 'neck_side_stretch',
      name: 'Boyun Yan Esnetme',
      area: BodyAreas.neck,
      durationSeconds: 30,
      difficulty: Difficulty.easy,
      posture: Posture.seated,
      summary: 'Başını yavaşça yana eğerek boynunu esnet.',
      steps: [
        'Sırtın dik, omuzların rahat şekilde otur.',
        'Sağ elini başının sol üstüne koy ve başını sağ omzuna doğru nazikçe '
            'eğ.',
        'Derin nefes alarak bekle, ardından diğer tarafa geç.',
      ],
      popular: true,
    ),
    Exercise(
      id: 'neck_rotation',
      name: 'Boyun Döndürme',
      area: BodyAreas.neck,
      durationSeconds: 20,
      difficulty: Difficulty.veryEasy,
      posture: Posture.seated,
      summary: 'Başını kontrollü ve yavaşça sağa ve sola çevir.',
      steps: [
        'Çeneni yere paralel tut.',
        'Başını yavaşça sağa çevir ve 3 saniye bekle.',
        'Aynı şekilde sola çevir; birkaç kez tekrarla.',
      ],
    ),
    Exercise(
      id: 'chin_tuck',
      name: 'Çene Geri Çekme',
      area: BodyAreas.neck,
      durationSeconds: 30,
      difficulty: Difficulty.easy,
      posture: Posture.seated,
      summary: 'Çeneni geriye çekerek boynunu omurganla hizala.',
      steps: [
        'Karşıya bak ve başını dik tut.',
        'Çeneni aşağı eğmeden düz bir çizgide geriye çek.',
        '3 saniye bekle, bırak ve tekrarla.',
      ],
    ),
    // Omuz
    Exercise(
      id: 'shoulder_rolls',
      name: 'Omuz Çevirme',
      area: BodyAreas.shoulder,
      durationSeconds: 20,
      difficulty: Difficulty.veryEasy,
      posture: Posture.seated,
      summary: 'Omuzlarını geniş daireler çizerek geriye doğru çevir.',
      steps: [
        'Kollarını yanlarına bırak.',
        'Omuzlarını kulaklarına doğru kaldır, geriye ve aşağı indir.',
        'Hareketi geniş dairelerle 10 kez tekrarla.',
      ],
      popular: true,
    ),
    Exercise(
      id: 'shoulder_blade_squeeze',
      name: 'Kürek Kemiği Sıkıştırma',
      area: BodyAreas.shoulder,
      durationSeconds: 40,
      difficulty: Difficulty.medium,
      posture: Posture.seated,
      summary: 'Kürek kemiklerini birbirine yaklaştırıp göğsünü aç.',
      steps: [
        'Dik otur, kollarını yanlarında bük.',
        'Kürek kemiklerini geriye ve aşağı doğru sıkıştır.',
        '5 saniye tut, bırak; 6 kez tekrarla.',
      ],
      popular: true,
    ),
    Exercise(
      id: 'shoulder_shrug',
      name: 'Omuz Silkme & Gevşeme',
      area: BodyAreas.shoulder,
      durationSeconds: 25,
      difficulty: Difficulty.veryEasy,
      posture: Posture.standing,
      summary: 'Omuzlarını kaldırıp bir anda bırakarak gerginliği at.',
      steps: [
        'Ayakta dik dur.',
        'Nefes alırken omuzlarını kulaklarına doğru kaldır.',
        'Nefes verirken omuzlarını bir anda bırak.',
      ],
    ),
    // Kol & El
    Exercise(
      id: 'finger_spread',
      name: 'Parmak Açma Kapama',
      area: BodyAreas.armHand,
      durationSeconds: 20,
      difficulty: Difficulty.veryEasy,
      posture: Posture.seated,
      summary: 'Parmaklarını sıkıca yumruk yapıp geniş aç.',
      steps: [
        'Ellerini önüne uzat.',
        'Yumruk yap, 2 saniye tut.',
        'Parmaklarını olabildiğince geniş aç; 10 kez tekrarla.',
      ],
    ),
    Exercise(
      id: 'triceps_stretch',
      name: 'Arka Kol Esnetme',
      area: BodyAreas.armHand,
      durationSeconds: 30,
      difficulty: Difficulty.easy,
      posture: Posture.standing,
      summary: 'Kolunu başının arkasına uzatarak arka kolunu esnet.',
      steps: [
        'Sağ kolunu yukarı kaldır, dirseğini bük.',
        'Sol elinle sağ dirseğini nazikçe başının arkasına doğru it.',
        'Bekle, ardından kol değiştir.',
      ],
    ),
    // Bilek
    Exercise(
      id: 'carpal_tunnel_stretch',
      name: 'Karpal Tünel Bilek Esnetmesi',
      area: BodyAreas.wrist,
      durationSeconds: 25,
      difficulty: Difficulty.easy,
      posture: Posture.seated,
      summary: 'Avucunu öne çevirip parmaklarını geriye doğru çek.',
      steps: [
        'Sağ kolunu avucun öne bakacak şekilde uzat.',
        'Sol elinle parmaklarını nazikçe kendine doğru çek.',
        'Bekle, ardından el değiştir.',
      ],
      popular: true,
    ),
    Exercise(
      id: 'wrist_circles',
      name: 'Bilek ve Parmak Döndürme',
      area: BodyAreas.wrist,
      durationSeconds: 20,
      difficulty: Difficulty.veryEasy,
      posture: Posture.seated,
      summary: 'Bileklerini iki yöne yavaşça döndür.',
      steps: [
        'Ellerini hafif yumruk yap.',
        'Bileklerini saat yönünde 10 kez döndür.',
        'Ters yönde 10 kez tekrarla.',
      ],
    ),
    // Sırt & Omurga
    Exercise(
      id: 'seated_twist',
      name: 'Oturarak Omurga Dönüşü',
      area: BodyAreas.back,
      durationSeconds: 30,
      difficulty: Difficulty.easy,
      posture: Posture.seated,
      summary: 'Sandalyede gövdeni yavaşça yana çevir.',
      steps: [
        'Dik otur, ayaklarını yere bas.',
        'Sağ elini sandalyenin arkasına koyup gövdeni sağa çevir.',
        'Bekle, ardından diğer tarafa geç.',
      ],
    ),
    Exercise(
      id: 'chest_opener',
      name: 'Göğüs Açma',
      area: BodyAreas.back,
      durationSeconds: 30,
      difficulty: Difficulty.easy,
      posture: Posture.standing,
      summary: 'Ellerini arkada birleştirip göğsünü öne aç.',
      steps: [
        'Ayakta dur, ellerini arkanda kenetle.',
        'Kollarını hafifçe aşağı ve geriye uzat.',
        'Göğsünü aç ve derin nefes alarak bekle.',
      ],
      popular: true,
    ),
    // Gözler
    Exercise(
      id: 'eye_20_20_20',
      name: '20-20-20 Uzağa Bakma',
      area: BodyAreas.eyes,
      durationSeconds: 20,
      difficulty: Difficulty.veryEasy,
      posture: Posture.seated,
      summary: '20 saniye boyunca 6 metre uzaktaki bir noktaya bak.',
      steps: [
        'Ekrandan gözünü ayır.',
        'Yaklaşık 6 metre uzaktaki bir noktayı seç.',
        '20 saniye boyunca o noktaya odaklan.',
      ],
    ),
    Exercise(
      id: 'eye_palming',
      name: 'Avuçla Göz Dinlendirme',
      area: BodyAreas.eyes,
      durationSeconds: 30,
      difficulty: Difficulty.veryEasy,
      posture: Posture.seated,
      summary: 'Avuçlarını ısıtıp kapalı gözlerinin üzerine koy.',
      steps: [
        'Avuçlarını birbirine sürterek ısıt.',
        'Gözlerini kapat ve avuçlarını bastırmadan üzerine koy.',
        'Karanlığın tadını çıkararak yavaşça nefes al.',
      ],
    ),
    // Bel & Kalça
    Exercise(
      id: 'seated_figure_four',
      name: 'Oturarak Kalça Esnetme',
      area: BodyAreas.lowerBack,
      durationSeconds: 40,
      difficulty: Difficulty.medium,
      posture: Posture.seated,
      summary: 'Bileğini diğer dizine koyup öne doğru eğil.',
      steps: [
        'Sağ bileğini sol dizinin üzerine koy.',
        'Sırtın düz kalacak şekilde gövdeni hafifçe öne eğ.',
        'Bekle, ardından bacak değiştir.',
      ],
    ),
    Exercise(
      id: 'standing_back_bend',
      name: 'Ayakta Bel Esnetme',
      area: BodyAreas.lowerBack,
      durationSeconds: 20,
      difficulty: Difficulty.easy,
      posture: Posture.standing,
      summary: 'Ellerini beline koyup hafifçe geriye eğil.',
      steps: [
        'Ayakta dur, ellerini belinin arkasına koy.',
        'Kalçanı hafifçe öne iterek gövdeni geriye eğ.',
        'Kısa süre bekle ve yavaşça dikleş.',
      ],
    ),
    // Duruş & Postür
    Exercise(
      id: 'wall_angel',
      name: 'Duvar Meleği',
      area: BodyAreas.posture,
      durationSeconds: 40,
      difficulty: Difficulty.medium,
      posture: Posture.standing,
      summary: 'Sırtın duvarda, kollarını yukarı aşağı kaydır.',
      steps: [
        'Sırtını ve başını duvara daya.',
        'Kollarını "W" şeklinde duvara yasla.',
        'Kollarını duvardan ayırmadan yukarı ve aşağı kaydır.',
      ],
    ),
    Exercise(
      id: 'seated_posture_reset',
      name: 'Dik Oturuş Sıfırlama',
      area: BodyAreas.posture,
      durationSeconds: 15,
      difficulty: Difficulty.veryEasy,
      posture: Posture.seated,
      summary: 'Oturuşunu baştan kur: ayaklar, kalça, omurga, baş.',
      steps: [
        'Ayaklarını yere tam bas, kalçanı sandalyenin arkasına yasla.',
        'Başının tepesinden yukarı çekildiğini hayal et.',
        'Omuzlarını aşağı bırak ve birkaç derin nefes al.',
      ],
    ),
  ];

  static List<Exercise> byArea(BodyArea area) =>
      all.where((e) => e.area.id == area.id).toList();

  static int countFor(BodyArea area) =>
      all.where((e) => e.area.id == area.id).length;

  static List<Exercise> get popular => all.where((e) => e.popular).toList();

  /// Mola için önce rastgele bir bölge, sonra o bölgeden rastgele bir
  /// egzersiz seçer (bölgeler eşit şansla gelsin diye iki adımda).
  static Exercise suggestForBreak([math.Random? random]) {
    final rng = random ?? math.Random();
    final areas = BodyAreas.all.where((a) => countFor(a) > 0).toList();
    final options = byArea(areas[rng.nextInt(areas.length)]);
    return options[rng.nextInt(options.length)];
  }

  static Exercise? byId(String id) {
    for (final exercise in all) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }
}
