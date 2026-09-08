import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/chatbot_modal.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../products/products_screen.dart';
import '../../sales/sales_export.dart';
import '../dashboard_controller.dart';
import 'donut_chart.dart';
import 'revenue_area_chart.dart';

/// Full desktop dashboard layout matching the Figma design language and
/// professional responsive grid architecture across all device viewports.
class DesktopDashboardView extends ConsumerWidget {
  const DesktopDashboardView({
    super.key,
    required this.summary,
    required this.period,
    this.isLoading = false,
  });

  final DashboardSummary summary;
  final DashboardPeriod period;
  final bool isLoading;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: ref.read(dashboardCustomRangeProvider) ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          ),
    );
    if (range != null) {
      ref.read(dashboardCustomRangeProvider.notifier).set(range);
      ref.read(dashboardPeriodProvider.notifier).set(DashboardPeriod.custom);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (isLoading) {
      return Shimmer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
          children: [
            // 1. Header with greeting & date / export controls
            _buildHeader(context, ref, theme, primary),
            const SizedBox(height: 24),

            // 2. Four KPI cards skeleton row
            _buildKpiSkeletonRow(),
            const SizedBox(height: 24),

            // 3. Middle row: Revenue Overview + Top Selling Products skeletons
            _buildMiddleSkeletonRow(),
            const SizedBox(height: 28),

            // 4. "AT A GLANCE" Section Header
            Text(
              'AT A GLANCE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Bottom row skeletons
            _buildBottomSkeletonRow(),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
      children: [
        // ── 1. Header with greeting & date / export controls ─────────────────
        _buildHeader(context, ref, theme, primary),
        const SizedBox(height: 24),

        // ── 2. Four KPI cards row ────────────────────────────────────────────
        _buildKpiCardsRow(theme, primary),
        const SizedBox(height: 24),

        // ── 3. Middle row: Revenue Overview + Top Selling Products ───────────
        _buildMiddleRow(context, ref, theme, primary),
        const SizedBox(height: 28),

        // ── 4. "AT A GLANCE" Section Header ──────────────────────────────────
        Text(
          'AT A GLANCE',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 14),

        // ── 5. Bottom row: 3 cards (Payment Methods, Transactions, Low Stock) ─
        _buildBottomRow(context, ref, theme, primary),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Color primary,
  ) {
    final greeting = '${_getGreeting()}, Admin! 👋';
    final customRange = ref.watch(dashboardCustomRangeProvider);

    String dateLabel;
    if (period == DashboardPeriod.today) {
      dateLabel = DateFormat('MMMM d, yyyy').format(DateTime.now());
    } else if (period == DashboardPeriod.yesterday) {
      dateLabel = DateFormat('MMMM d, yyyy').format(
        DateTime.now().subtract(const Duration(days: 1)),
      );
    } else if (period == DashboardPeriod.week) {
      dateLabel = 'This Week';
    } else if (period == DashboardPeriod.month) {
      dateLabel = DateFormat('MMMM yyyy').format(DateTime.now());
    } else if (customRange != null) {
      dateLabel =
          '${DateFormat('MMM d').format(customRange.start)} – ${DateFormat('MMM d').format(customRange.end)}';
    } else {
      dateLabel = DateFormat('MMMM d, yyyy').format(DateTime.now());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting & subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening with your shop today.",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Date pill dropdown
        PopupMenuButton<DashboardPeriod>(
          initialValue: period,
          onSelected: (p) {
            ref.read(dashboardPeriodProvider.notifier).set(p);
            if (p == DashboardPeriod.custom) {
              _pickCustomRange(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: DashboardPeriod.today,
              child: Text('Today'),
            ),
            const PopupMenuItem(
              value: DashboardPeriod.yesterday,
              child: Text('Yesterday'),
            ),
            const PopupMenuItem(
              value: DashboardPeriod.week,
              child: Text('This Week'),
            ),
            const PopupMenuItem(
              value: DashboardPeriod.month,
              child: Text('This Month'),
            ),
            const PopupMenuItem(
              value: DashboardPeriod.custom,
              child: Text('Custom Range...'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // AI Chatbot pill button
        AppPressable(
          onTap: () => ChatbotModal.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_rounded, size: 16, color: primary),
                const SizedBox(width: 6),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Export Report pill button
        AppPressable(
          onTap: () {
            final sales = ref.read(saleListStreamProvider).value ?? [];
            exportSalesToExcel(context, ref, sales);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.file_download_outlined, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Export Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4 KPI CARDS (RESPONSIVE GRID / ROW)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKpiCardsRow(ThemeData theme, Color primary) {
    // Trend strings
    final revGrowth = summary.revenueGrowth;
    final revTrendText = revGrowth != null
        ? '${revGrowth >= 0 ? '↑' : '↓'} ${revGrowth.abs().toStringAsFixed(1)}% vs yesterday'
        : '— No comparison';
    final revTrendColor = theme.colorScheme.onSurfaceVariant;

    final txGrowth = summary.transactionsGrowth;
    final txTrendText = txGrowth != null
        ? '${txGrowth >= 0 ? '↑' : '↓'} ${txGrowth.abs().toStringAsFixed(1)}% vs yesterday'
        : '— No comparison';
    final txTrendColor = theme.colorScheme.onSurfaceVariant;

    final lowStockText = summary.lowStockCount > 0
        ? '↓ ${summary.lowStockCount} need reorder'
        : '✓ All well-stocked';
    final lowStockColor = summary.lowStockCount > 0
        ? primary
        : theme.colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildKpiCard(
            theme: theme,
            icon: Icons.payments_outlined,
            title: 'Total Revenue',
            value: formatPeso(summary.revenue),
            subtitle: revTrendText,
            subtitleColor: revTrendColor,
          ),
          _buildKpiCard(
            theme: theme,
            icon: Icons.shopping_bag_outlined,
            title: 'Total Transactions',
            value: '${summary.salesCount}',
            subtitle: txTrendText,
            subtitleColor: txTrendColor,
          ),
          _buildKpiCard(
            theme: theme,
            icon: Icons.inventory_2_outlined,
            title: 'Total Products',
            value: '${summary.productsCount}',
            subtitle: '— Active in shop',
            subtitleColor: theme.colorScheme.onSurfaceVariant,
          ),
          _buildKpiCard(
            theme: theme,
            icon: Icons.warning_amber_rounded,
            title: 'Low Stock Items',
            value: '${summary.lowStockCount}',
            subtitle: lowStockText,
            subtitleColor: lowStockColor,
          ),
        ];

        // 1. Desktop Wide & Standard (>= 840px): 4 cards in a single row
        if (constraints.maxWidth >= 840) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 14),
              Expanded(child: cards[1]),
              const SizedBox(width: 14),
              Expanded(child: cards[2]),
              const SizedBox(width: 14),
              Expanded(child: cards[3]),
            ],
          );
        }

        // 2. Tablet / Compact Desktop (520px - 839px): Balanced 2x2 grid
        if (constraints.maxWidth >= 520) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        // 3. Narrow / Mobile (< 520px): Stack vertically
        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
            const SizedBox(height: 12),
            cards[2],
            const SizedBox(height: 12),
            cards[3],
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color subtitleColor,
  }) {
    final primary = theme.colorScheme.primary;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular icon badge matching mobile MetricCard
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, color: primary, size: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Label, value, trend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelCaps.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MIDDLE ROW (Revenue Overview + Top Selling Products)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMiddleRow(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Color primary,
  ) {
    final revCard = _buildRevenueOverviewCard(ref, theme, primary);
    final topCard = _buildTopSellingCard(context, ref, theme, primary);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              revCard,
              const SizedBox(height: 18),
              topCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 62, child: revCard),
            const SizedBox(width: 18),
            Expanded(flex: 38, child: topCard),
          ],
        );
      },
    );
  }

  Widget _buildRevenueOverviewCard(WidgetRef ref, ThemeData theme, Color primary) {
    return GlassContainer(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Overview',
                style: AppTextStyles.headingMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _buildPeriodPill(ref, theme),
            ],
          ),
          const SizedBox(height: 18),

          // Area Chart
          RevenueAreaChart(
            values: summary.chartData,
            labels: summary.chartLabels,
            lineColor: primary,
            height: 220,
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Bottom summary strip
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  theme: theme,
                  label: 'Total Revenue',
                  value: formatPeso(summary.revenue),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildSummaryMetric(
                  theme: theme,
                  label: 'Total Transactions',
                  value: '${summary.salesCount}',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildSummaryMetric(
                  theme: theme,
                  label: 'Average Order Value',
                  value: formatPeso(summary.avgTicket),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Color primary,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Selling Products',
                style: AppTextStyles.headingMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _buildPeriodPill(ref, theme),
            ],
          ),
          const SizedBox(height: 18),

          // Product items list
          if (summary.topSelling.isEmpty)
            Container(
              height: 240,
              alignment: Alignment.center,
              child: Text(
                'No sales recorded in this period',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...List.generate(summary.topSelling.length, (index) {
              final item = summary.topSelling[index];
              final maxQty = summary.topSelling.first.quantity;
              final ratio = maxQty > 0 ? (item.quantity / maxQty).clamp(0.05, 1.0) : 0.05;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Rank
                    SizedBox(
                      width: 16,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 34,
                        height: 34,
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        child: AppImage(
                          imageUrl: item.imageUrl,
                          imagePath: item.imagePath,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.inventory_2_outlined,
                          placeholderIconSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Name & Progress bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Qty
                    Text(
                      '${item.quantity} pcs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Link: View all products
          InkWell(
            onTap: () => context.go(RoutePaths.products),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all products',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodPill(WidgetRef ref, ThemeData theme) {
    return PopupMenuButton<DashboardPeriod>(
      tooltip: 'Filter period',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.colorScheme.surfaceContainerHigh,
      onSelected: (p) => ref.read(dashboardPeriodProvider.notifier).set(p),
      itemBuilder: (context) => [
        const PopupMenuItem(value: DashboardPeriod.today, child: Text('Today')),
        const PopupMenuItem(value: DashboardPeriod.yesterday, child: Text('Yesterday')),
        const PopupMenuItem(value: DashboardPeriod.week, child: Text('This Week')),
        const PopupMenuItem(value: DashboardPeriod.month, child: Text('This Month')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              summary.periodLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM ROW: 3 Cards (Sales by Payment, Transactions, Low Stock Alert)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomRow(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Color primary,
  ) {
    final paymentCard = _buildPaymentMethodsCard(theme);
    final txCard = _buildTransactionsCard(theme);
    final stockCard = _buildLowStockCard(context, ref, theme, primary);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 1. Extra Wide screens (>= 1200px): 3 columns side-by-side
        if (constraints.maxWidth >= 1200) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 35, child: paymentCard),
              const SizedBox(width: 18),
              Expanded(flex: 35, child: txCard),
              const SizedBox(width: 18),
              Expanded(flex: 30, child: stockCard),
            ],
          );
        }

        // 2. Standard Desktop / Laptops / Tablets (720px - 1199px):
        // Row 1: 2 equal-width columns for the 2 charts (plenty of room for donuts & legends!)
        // Row 2: Full-width Low Stock Alert card
        if (constraints.maxWidth >= 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: paymentCard),
                  const SizedBox(width: 18),
                  Expanded(child: txCard),
                ],
              ),
              const SizedBox(height: 18),
              stockCard,
            ],
          );
        }

        // 3. Narrow / Mobile (< 720px): Stack all 3 cards cleanly
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            paymentCard,
            const SizedBox(height: 16),
            txCard,
            const SizedBox(height: 16),
            stockCard,
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodsCard(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final paymentShades = [
      primary,
      primary.withValues(alpha: 0.65),
      primary.withValues(alpha: 0.35),
    ];

    return _buildCardContainer(
      theme: theme,
      title: 'Sales by Payment Method',
      child: LayoutBuilder(
        builder: (context, cardBox) {
          final isNarrow = cardBox.maxWidth < 340;
          final donut = DonutChart(
            size: isNarrow ? 96 : 110,
            strokeWidth: 16,
            slices: List.generate(summary.paymentMethods.length, (i) {
              final p = summary.paymentMethods[i];
              return DonutSlice(
                label: p.method,
                value: p.amount,
                color: paymentShades[i % paymentShades.length],
              );
            }),
          );

          final legend = Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(summary.paymentMethods.length, (i) {
              final p = summary.paymentMethods[i];
              final sliceColor = paymentShades[i % paymentShades.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sliceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.method,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatPeso(p.amount)} (${p.percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );

          return Column(
            children: [
              const SizedBox(height: 8),
              if (isNarrow) ...[
                Center(child: donut),
                const SizedBox(height: 14),
                legend,
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    donut,
                    const SizedBox(width: 18),
                    Expanded(child: legend),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatPeso(summary.revenue),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionsCard(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final statusShades = [
      primary,
      primary.withValues(alpha: 0.55),
      primary.withValues(alpha: 0.28),
    ];

    return _buildCardContainer(
      theme: theme,
      title: 'Transactions Overview',
      child: LayoutBuilder(
        builder: (context, cardBox) {
          final isNarrow = cardBox.maxWidth < 340;
          final donut = DonutChart(
            size: isNarrow ? 96 : 110,
            strokeWidth: 16,
            slices: List.generate(summary.transactionStatuses.length, (i) {
              final s = summary.transactionStatuses[i];
              return DonutSlice(
                label: s.status,
                value: s.count.toDouble(),
                color: statusShades[i % statusShades.length],
              );
            }),
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${summary.salesCount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );

          final breakdown = Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(summary.transactionStatuses.length, (i) {
              final s = summary.transactionStatuses[i];
              final sliceColor = statusShades[i % statusShades.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sliceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.count} (${s.percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );

          return Column(
            children: [
              const SizedBox(height: 8),
              if (isNarrow) ...[
                Center(child: donut),
                const SizedBox(height: 14),
                breakdown,
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    donut,
                    const SizedBox(width: 18),
                    Expanded(child: breakdown),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Success Rate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Builder(builder: (context) {
                    final completed = summary.transactionStatuses
                        .where((s) => s.status == 'Completed')
                        .firstOrNull;
                    final rate = completed != null ? completed.percentage.toStringAsFixed(0) : '100';
                    return Text(
                      '$rate%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: primary,
                      ),
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLowStockCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Color primary,
  ) {
    return _buildCardContainer(
      theme: theme,
      title: 'Low Stock Alert',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          if (summary.lowStockItems.isEmpty)
            Container(
              height: 115,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'All items well-stocked',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final isWideCard = box.maxWidth >= 600;
                final items = summary.lowStockItems.take(4).toList();

                if (isWideCard && items.length > 1) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 38,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildLowStockItemRow(theme, item, primary);
                    },
                  );
                }

                return Column(
                  children: items.take(3).map((item) => _buildLowStockItemRow(theme, item, primary)).toList(),
                );
              },
            ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              ref.read(productLowStockFilterProvider.notifier).trigger();
              context.go(RoutePaths.products);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all low stock items',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockItemRow(ThemeData theme, dynamic item, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 24,
              height: 24,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: AppImage(
                imageUrl: item.imageUrl,
                imagePath: item.imagePath,
                fit: BoxFit.cover,
                placeholderIcon: Icons.inventory_2_outlined,
                placeholderIconSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.stockQty} pcs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required ThemeData theme,
    required String title,
    required Widget child,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildKpiSkeletonRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = List.generate(4, (_) => const SkeletonKpiCard());
        if (constraints.maxWidth >= 840) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 14),
              Expanded(child: cards[1]),
              const SizedBox(width: 14),
              Expanded(child: cards[2]),
              const SizedBox(width: 14),
              Expanded(child: cards[3]),
            ],
          );
        }
        if (constraints.maxWidth >= 520) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 14),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }
        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            cards[1],
            const SizedBox(height: 12),
            cards[2],
            const SizedBox(height: 12),
            cards[3],
          ],
        );
      },
    );
  }

  Widget _buildMiddleSkeletonRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonRevenueOverviewCard(),
              SizedBox(height: 18),
              SkeletonTopSellingCard(),
            ],
          );
        }
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 62, child: SkeletonRevenueOverviewCard()),
            SizedBox(width: 18),
            Expanded(flex: 38, child: SkeletonTopSellingCard()),
          ],
        );
      },
    );
  }

  Widget _buildBottomSkeletonRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const paymentCard = SkeletonDonutCard(title: 'Sales by Payment Method');
        const txCard = SkeletonDonutCard(title: 'Transaction Status');
        const stockCard = SkeletonLowStockCard();

        if (constraints.maxWidth >= 1200) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 35, child: paymentCard),
              SizedBox(width: 18),
              Expanded(flex: 35, child: txCard),
              SizedBox(width: 18),
              Expanded(flex: 30, child: stockCard),
            ],
          );
        }
        if (constraints.maxWidth >= 720) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: paymentCard),
                  SizedBox(width: 18),
                  Expanded(child: txCard),
                ],
              ),
              SizedBox(height: 18),
              stockCard,
            ],
          );
        }
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            paymentCard,
            SizedBox(height: 14),
            txCard,
            SizedBox(height: 14),
            stockCard,
          ],
        );
      },
    );
  }
}
