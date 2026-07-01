import 'package:isar_community/isar.dart';

import '../../core/utils/uuid.dart';

part 'business_settings.g.dart';

/// Single-row shop configuration captured during onboarding. Uses a fixed id
/// so there is always exactly one settings record.
@collection
class BusinessSettings {
  Id id = singletonId;

  static const singletonId = 0;

  /// Server-aligned business UUID (set from the API on register/login).
  String uid = uuidV7();

  String businessName = 'DC Motorshop & Accessories';
  String businessType = 'Motorcycle Shop';

  /// Optional local file path to the shop logo image.
  String? logoPath;

  // ── Business details (printed on receipts & reports, see General screen) ───
  /// Street address shown on customer receipts.
  String? address;

  /// Contact phone number (Philippine format, e.g. 09171234567).
  String? phone;

  /// Contact email shown on receipts.
  String? email;

  /// IANA-style timezone label used for daily totals & reports.
  String timezone = 'Asia/Manila (GMT+8)';

  /// Currency label shown on prices and totals.
  String currency = 'PHP — Philippine Peso';

  /// Optional URL encoded into the receipt QR (FB page, ordering link, GCash).
  String? receiptQrLink;

  List<String> categories = ['Parts', 'Services'];
  List<String> workflowStages = ['Pending', 'Processing', 'Completed'];

  /// Accent theme name chosen in onboarding (e.g. "Blue"). See ThemeOption.
  String themeColor = 'Blue';

  /// Ids of completed setup-checklist items.
  List<String> completedChecklistItems = [];

  // ── Inventory settings (see InventorySettingsScreen) ──────────────────────
  /// Let a sale push stock below zero. Off = checkout is blocked when a line
  /// exceeds on-hand stock.
  bool allowSellWhenOutOfStock = false;

  /// Record change still owed when the shop hands back less change than due.
  bool trackPartialChange = false;

  /// Count unpaid (utang) sales toward revenue, profit, and COGS. Off = they
  /// only count once the customer pays.
  bool includeUnpaidInReports = true;

  // Sync metadata.
  DateTime updatedAt = DateTime.now();
  bool isDirty = true;
}
