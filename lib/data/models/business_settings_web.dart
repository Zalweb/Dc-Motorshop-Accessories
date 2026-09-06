import '../../core/utils/uuid.dart';

/// Single-row shop configuration - web-safe mirror of native [BusinessSettings].
class BusinessSettings {
  BusinessSettings({
    int? id,
    String? uid,
    this.businessName = 'DC Motorshop & Accessories',
    this.businessType = 'Motorcycle Shop',
    this.logoPath,
    this.address,
    this.phone,
    this.email,
    this.timezone = 'Asia/Manila (GMT+8)',
    this.currency = 'PHP — Philippine Peso',
    this.receiptQrLink,
    List<String>? categories,
    List<String>? workflowStages,
    this.themeColor = 'Blue',
    List<String>? completedChecklistItems,
    this.allowSellWhenOutOfStock = false,
    this.trackPartialChange = false,
    this.includeUnpaidInReports = true,
    DateTime? updatedAt,
    this.isDirty = true,
  })  : id = id ?? BusinessSettings.singletonId,
        uid = uid ?? uuidV7(),
        categories = categories ?? ['Parts', 'Services'],
        workflowStages = workflowStages ?? ['Pending', 'Processing', 'Completed'],
        completedChecklistItems = completedChecklistItems ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  static const singletonId = 0;

  int id;

  /// Server-aligned business UUID (set from the API on register/login).
  String uid;

  String businessName;
  String businessType;

  /// Optional local file path or remote URL to the shop logo image.
  String? logoPath;

  /// Street address shown on customer receipts.
  String? address;

  /// Contact phone number (Philippine format, e.g. 09171234567).
  String? phone;

  /// Contact email shown on receipts.
  String? email;

  /// IANA-style timezone label used for daily totals & reports.
  String timezone;

  /// Currency label shown on prices and totals.
  String currency;

  /// Optional URL encoded into the receipt QR (FB page, ordering link, GCash).
  String? receiptQrLink;

  List<String> categories;
  List<String> workflowStages;

  /// Accent theme name chosen in onboarding (e.g. "Blue").
  String themeColor;

  /// Ids of completed setup-checklist items.
  List<String> completedChecklistItems;

  bool allowSellWhenOutOfStock;
  bool trackPartialChange;
  bool includeUnpaidInReports;

  DateTime updatedAt;
  bool isDirty;

  factory BusinessSettings.fromJson(Map<String, dynamic> j) => BusinessSettings(
        uid: j['id'] as String? ?? j['uid'] as String? ?? uuidV7(),
        businessName: j['business_name'] as String? ?? 'DC Motorshop & Accessories',
        businessType: j['business_type'] as String? ?? 'Motorcycle Shop',
        logoPath: j['logo_url'] as String? ?? j['logoPath'] as String?,
        address: j['address'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        timezone: j['timezone'] as String? ?? 'Asia/Manila (GMT+8)',
        currency: j['currency'] as String? ?? 'PHP — Philippine Peso',
        receiptQrLink: j['receipt_qr_link'] as String? ?? j['receiptQrLink'] as String?,
        categories: j['categories'] != null
            ? List<String>.from(j['categories'] as List)
            : ['Parts', 'Services'],
        workflowStages: j['workflow_stages'] != null
            ? List<String>.from(j['workflow_stages'] as List)
            : ['Pending', 'Processing', 'Completed'],
        themeColor: j['theme_color'] as String? ?? j['themeColor'] as String? ?? 'Blue',
        completedChecklistItems: j['completed_checklist_items'] != null
            ? List<String>.from(j['completed_checklist_items'] as List)
            : (j['completedChecklistItems'] != null
                ? List<String>.from(j['completedChecklistItems'] as List)
                : <String>[]),
        allowSellWhenOutOfStock:
            j['allow_sell_when_out_of_stock'] as bool? ?? j['allowSellWhenOutOfStock'] as bool? ?? false,
        trackPartialChange: j['track_partial_change'] as bool? ?? j['trackPartialChange'] as bool? ?? false,
        includeUnpaidInReports:
            j['include_unpaid_in_reports'] as bool? ?? j['includeUnpaidInReports'] as bool? ?? true,
        updatedAt: j['updated_at'] != null
            ? DateTime.parse(j['updated_at'] as String)
            : (j['updatedAt'] != null
                ? DateTime.parse(j['updatedAt'] as String)
                : DateTime.now()),
        isDirty: false,
      );

  Map<String, dynamic> toJson() => {
        'id': uid,
        'business_name': businessName,
        'business_type': businessType,
        if (logoPath != null) 'logo_url': logoPath,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        'timezone': timezone,
        'currency': currency,
        if (receiptQrLink != null) 'receipt_qr_link': receiptQrLink,
        'theme_color': themeColor,
        'allow_sell_when_out_of_stock': allowSellWhenOutOfStock,
        'track_partial_change': trackPartialChange,
        'include_unpaid_in_reports': includeUnpaidInReports,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}
