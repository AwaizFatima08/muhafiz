import 'package:cloud_firestore/cloud_firestore.dart';

class CardNumberGenerator {
  static const String _prefix = 'EC';

  /// Generates next card number in format EC-YYYY-XXXX
  /// Queries Firestore to find the highest existing number for the year
  /// and increments it. Thread-safe via Firestore transaction.
  static Future<String> generate(FirebaseFirestore db) async {
    final year = DateTime.now().year.toString();
    final counterRef = db.collection('_counters').doc('card_number_$year');

    int nextNumber = 0;

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      if (snapshot.exists) {
        nextNumber = (snapshot.data()?['last_number'] ?? 0) + 1;
      } else {
        nextNumber = 1;
      }
      transaction.set(counterRef, {'last_number': nextNumber});
    });

    final paddedNumber = nextNumber.toString().padLeft(4, '0');
    return '$_prefix-$year-$paddedNumber';
  }

  /// Validates card number format EC-YYYY-XXXX
  static bool isValid(String cardNumber) {
    final regex = RegExp(r'^EC-\d{4}-\d{4}$');
    return regex.hasMatch(cardNumber);
  }
}
