import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/business_settings.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/user.dart';

/// Owns the single Isar instance for the app. Open once at startup, then
/// inject into repositories. UI never touches Isar directly (CLAUDE.md).
class IsarService {
  IsarService._(this.isar);

  final Isar isar;

  static Future<IsarService> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        UserSchema,
        BusinessSettingsSchema,
        CategorySchema,
        ProductSchema,
        SaleSchema,
        ExpenseSchema,
      ],
      directory: dir.path,
      name: 'dc_motorcycle_inventory',
    );
    return IsarService._(isar);
  }
}
