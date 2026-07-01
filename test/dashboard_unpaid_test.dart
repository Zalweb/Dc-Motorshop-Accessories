import 'package:dc_motorcycle_inventory/core/providers.dart';
import 'package:dc_motorcycle_inventory/data/models/business_settings.dart';
import 'package:dc_motorcycle_inventory/data/models/sale.dart';
import 'package:dc_motorcycle_inventory/features/dashboard/dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Sale _sale({required String status, required double total}) => Sale()
  ..saleNumber = 'S-0001'
  ..status = status
  ..subtotal = total
  ..total = total
  ..createdAt = DateTime.now();

Future<DashboardSummary> _summaryWith({required bool includeUnpaid}) async {
  final settings = BusinessSettings()..includeUnpaidInReports = includeUnpaid;
  final container = ProviderContainer(
    overrides: [
      saleListStreamProvider.overrideWith(
        (ref) => Stream.value([
          _sale(status: 'paid', total: 100),
          _sale(status: 'unpaid', total: 40),
        ]),
      ),
      expenseListStreamProvider.overrideWith((ref) => Stream.value([])),
      businessSettingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
    ],
  );
  addTearDown(container.dispose);

  container.listen(dashboardSummaryProvider, (_, _) {}, fireImmediately: true);
  await pumpEventQueue();

  return container.read(dashboardSummaryProvider);
}

void main() {
  test('unpaid sale is excluded from revenue when the setting is off', () async {
    final summary = await _summaryWith(includeUnpaid: false);
    expect(summary.revenue, 100);
  });

  test('unpaid sale counts toward revenue when the setting is on', () async {
    final summary = await _summaryWith(includeUnpaid: true);
    expect(summary.revenue, 140);
  });
}
