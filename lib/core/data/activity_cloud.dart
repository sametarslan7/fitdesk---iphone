import 'package:cloud_firestore/cloud_firestore.dart';

/// Tamamlanmış bir egzersizin saklanan hali.
typedef ActivityRecord = ({String exerciseId, DateTime at});

/// Kullanıcının egzersiz kaydının buluttaki kopyası. Testler [forUser]ı
/// sahtesiyle değiştirir.
abstract class ActivityCloud {
  static ActivityCloud Function(String uid) forUser =
      FirestoreActivityCloud.new;

  /// Kaydın tamamı; her değişiklikte (çevrimdışı yazmalar dahil) yeniden
  /// yayınlanır.
  Stream<List<ActivityRecord>> watch();

  /// Aynı kayıt (egzersiz + an) iki kez yazılırsa tek kayıt kalır.
  Future<void> addAll(List<ActivityRecord> records);
}

/// `users/{uid}/activity/{an_egzersiz}` belgeleri. Belge kimliği kayıttan
/// türetildiği için yeniden deneme ve cihazdan aktarım çift kayıt üretmez.
class FirestoreActivityCloud implements ActivityCloud {
  FirestoreActivityCloud(String uid)
    : _collection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activity');

  final CollectionReference<Map<String, dynamic>> _collection;

  static String _docId(ActivityRecord r) =>
      '${r.at.millisecondsSinceEpoch}_${r.exerciseId}';

  @override
  Stream<List<ActivityRecord>> watch() => _collection.snapshots().map(
    (snapshot) => [
      for (final doc in snapshot.docs)
        if ((doc.data()['exerciseId'], doc.data()['at']) case (
          final String id,
          final Timestamp at,
        ))
          (exerciseId: id, at: at.toDate()),
    ],
  );

  @override
  Future<void> addAll(List<ActivityRecord> records) async {
    // Firestore bir toplu yazmada en fazla 500 işlem kabul ediyor.
    for (var i = 0; i < records.length; i += 500) {
      final batch = FirebaseFirestore.instance.batch();
      for (final r in records.skip(i).take(500)) {
        batch.set(_collection.doc(_docId(r)), {
          'exerciseId': r.exerciseId,
          'at': Timestamp.fromDate(r.at),
        });
      }
      await batch.commit();
    }
  }
}
