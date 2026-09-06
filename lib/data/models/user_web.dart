import '../../core/utils/uuid.dart';

/// Local account - web-safe mirror of native [User].
class User {
  User({
    int? id,
    String? uid,
    this.businessUid,
    this.username = '',
    this.email = '',
    this.passwordHash = '',
    this.passwordSalt = '',
    this.fullName,
    this.phone,
    this.onboardingComplete = false,
    this.newShopSetup = false,
    DateTime? createdAt,
  })  : id = id ?? 0,
        uid = uid ?? uuidV7(),
        createdAt = createdAt ?? DateTime.now();

  int id;

  /// Server-aligned user UUID (set from the API on register/login).
  String uid;

  /// Server business id this user belongs to (set from the API).
  String? businessUid;

  String username;
  String email;

  /// Empty when the account exists only server-side (logged in online).
  String passwordHash;
  String passwordSalt;

  String? fullName;
  String? phone;

  /// Whether the user has completed the mandatory onboarding steps.
  bool onboardingComplete;

  /// Whether the user has completed the initial Setup Shop wizard (step 1-3).
  bool newShopSetup;

  DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> j) => User(
        uid: j['id'] as String? ?? j['uid'] as String? ?? uuidV7(),
        businessUid: j['business_id'] as String? ?? j['businessUid'] as String?,
        username: j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        passwordHash: j['passwordHash'] as String? ?? '',
        passwordSalt: j['passwordSalt'] as String? ?? '',
        fullName: j['full_name'] as String? ?? j['fullName'] as String?,
        phone: j['phone'] as String?,
        onboardingComplete: j['onboarding_complete'] as bool? ??
            j['onboardingComplete'] as bool? ??
            false,
        newShopSetup: j['new_shop_setup'] as bool? ??
            j['newShopSetup'] as bool? ??
            false,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : (j['createdAt'] != null
                ? DateTime.parse(j['createdAt'] as String)
                : DateTime.now()),
      );

  Map<String, dynamic> toJson() => {
        'id': uid,
        if (businessUid != null) 'business_id': businessUid,
        'username': username,
        'email': email,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        'onboarding_complete': onboardingComplete,
        'new_shop_setup': newShopSetup,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
