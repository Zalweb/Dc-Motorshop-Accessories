import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'user.g.dart';

/// Local account. Offline sign-up stores a salted hash; when online, auth goes
/// through the backend and [uid] holds the server's user id.
@collection
class User {
  Id id = Isar.autoIncrement;

  /// Server-aligned user UUID (set from the API on register/login).
  @Index(unique: true)
  String uid = uuidV7();

  /// Server business id this user belongs to (set from the API).
  String? businessUid;

  @Index(unique: true, caseSensitive: false)
  late String username;

  @Index(unique: true, caseSensitive: false)
  late String email;

  /// Empty when the account exists only server-side (logged in online).
  String passwordHash = '';
  String passwordSalt = '';

  String? fullName;
  String? phone;

  /// Whether the user has completed the mandatory onboarding steps.
  bool onboardingComplete = false;

  /// Whether the user has completed the initial Setup Shop wizard (step 1-3).
  bool newShopSetup = false;

  DateTime createdAt = DateTime.now();
}
