import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// SharedPreferences key shared with FinancialCalendarScreen so both screens
/// agree on which days the shop is closed.
const _closedDatesKey = 'calendar_closed_dates';

/// Richer per-date metadata (reason + note) owned by the Business Calendar.
const _closedMetaKey = 'calendar_closed_meta';

/// Why a day is marked closed. Mirrors the reason cards in 22.1.jpg.
enum ClosedReason {
  holiday('Holiday', 'Public or company holiday'),
  dayOff('Day off', 'Recurring weekly rest day'),
  maintenance('Maintenance', 'Closed for repairs'),
  other('Other', 'Anything else');

  const ClosedReason(this.label, this.subtitle);

  final String label;
  final String subtitle;

  static ClosedReason fromStorage(String? key) =>
      ClosedReason.values.firstWhere((r) => r.name == key, orElse: () => ClosedReason.holiday);
}

class _ClosedDay {
  const _ClosedDay({required this.reason, required this.note});

  final ClosedReason reason;
  final String note;
}

/// Business calendar — tag the days the shop is closed so daily expense and
/// sales-target math only spreads across operating days. See 22.jpg / 22.1.jpg.
class BusinessCalendarScreen extends ConsumerStatefulWidget {
  const BusinessCalendarScreen({super.key});

  @override
  ConsumerState<BusinessCalendarScreen> createState() => _BusinessCalendarScreenState();
}

class _BusinessCalendarScreenState extends ConsumerState<BusinessCalendarScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final Map<String, _ClosedDay> _closed = {};

  static final _keyFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(_closedDatesKey) ?? [];
    final metaRaw = prefs.getString(_closedMetaKey);
    final meta = metaRaw == null ? <String, dynamic>{} : jsonDecode(metaRaw) as Map<String, dynamic>;

    final loaded = <String, _ClosedDay>{};
    for (final date in dates) {
      final entry = meta[date] as Map<String, dynamic>?;
      loaded[date] = _ClosedDay(
        reason: ClosedReason.fromStorage(entry?['reason'] as String?),
        note: (entry?['note'] as String?) ?? '',
      );
    }
    if (mounted) setState(() => _closed..clear()..addAll(loaded));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _closed.keys.toList();
    await prefs.setStringList(_closedDatesKey, keys);
    final meta = _closed.map(
      (date, day) => MapEntry(date, {'reason': day.reason.name, 'note': day.note}),
    );
    await prefs.setString(_closedMetaKey, jsonEncode(meta));
    ref.read(calendarClosedDatesProvider.notifier).set(keys);
  }

  bool _isClosed(DateTime date) => _closed.containsKey(_keyFormat.format(date));

  void _markClosed(DateTime date, ClosedReason reason, String note) {
    setState(() => _closed[_keyFormat.format(date)] = _ClosedDay(reason: reason, note: note));
    _persist();
  }

  void _reopen(DateTime date) {
    setState(() => _closed.remove(_keyFormat.format(date)));
    _persist();
  }

  void _changeMonth(int delta) {
    setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta));
  }

  void _jumpToToday() {
    setState(() => _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    final totalDays = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    var closedCount = 0;
    for (var d = 1; d <= totalDays; d++) {
      if (_isClosed(DateTime(_selectedMonth.year, _selectedMonth.month, d))) closedCount++;
    }
    final operatingDays = totalDays - closedCount;
    final rate = totalDays == 0 ? 0 : (operatingDays / totalDays * 100).round();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgBase : AppColors.bgBaseLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgBase : AppColors.bgBaseLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Business calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildWhyCard(isDark, textSecondary),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'OPERATING',
                  value: '$operatingDays',
                  subtext: 'days open',
                  color: AppColors.active,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'CLOSED',
                  value: '$closedCount',
                  subtext: 'days off',
                  color: AppColors.danger,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'RATE',
                  value: '$rate%',
                  subtext: 'of month',
                  color: AppColors.active,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildMonthSelector(textSecondary),
          const SizedBox(height: 16),
          _buildCalendar(isDark, totalDays),
          const SizedBox(height: 16),
          _buildLegend(textSecondary),
          const SizedBox(height: 28),
          _buildUpcoming(isDark, textSecondary),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWhyCard(bool isDark, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14, height: 1.4, color: textSecondary),
                children: [
                  TextSpan(
                    text: 'Why this matters: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    ),
                  ),
                  const TextSpan(
                    text: "we spread your rent, bills, and daily sales goal only across the "
                        "days you're open. If your rest days and holidays aren't marked here, your "
                        "daily expenses will look smaller and your daily target will look easier "
                        "than they really are — and your profit numbers won't match real life.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtext,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.06 : 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Column(
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: _jumpToToday,
              child: Text('tap to jump to today', style: TextStyle(fontSize: 13, color: textSecondary)),
            ),
          ],
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildCalendar(bool isDark, int totalDays) {
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final leadingPad = monthStart.weekday % 7; // Sunday = 0
    final totalCells = leadingPad + totalDays;
    final trailingPad = (7 - (totalCells % 7)) % 7;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingPad + totalDays + trailingPad,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (ctx, index) {
              if (index < leadingPad || index >= leadingPad + totalDays) {
                return const SizedBox.shrink();
              }
              final day = index - leadingPad + 1;
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final isClosed = _isClosed(date);

              return _buildDayCell(day: day, date: date, isToday: isToday, isClosed: isClosed, isDark: isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required bool isToday,
    required bool isClosed,
    required bool isDark,
  }) {
    Color textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    BoxBorder? border;
    Color? fill;

    if (isClosed) {
      fill = AppColors.danger.withValues(alpha: 0.12);
      border = Border.all(color: AppColors.danger.withValues(alpha: 0.5));
      textColor = AppColors.danger;
    } else if (isToday) {
      border = Border.all(color: AppColors.active, width: 2);
      textColor = AppColors.active;
    }

    return GestureDetector(
      onTap: () => _openSheet(date),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('$day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
            if (isClosed)
              Positioned(
                bottom: 8,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color textSecondary) {
    Widget item(Widget swatch, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, color: textSecondary)),
          ],
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.active, width: 2),
            ),
          ),
          'Today',
        ),
        const SizedBox(width: 20),
        item(
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
            ),
            child: const Center(
              child: SizedBox(
                width: 5,
                height: 5,
                child: DecoratedBox(decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
              ),
            ),
          ),
          'Closed',
        ),
        const SizedBox(width: 20),
        item(
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: textSecondary.withValues(alpha: 0.5)),
            ),
          ),
          'Open',
        ),
      ],
    );
  }

  Widget _buildUpcoming(bool isDark, Color textSecondary) {
    final today = DateTime.now();
    final todayKey = _keyFormat.format(DateTime(today.year, today.month, today.day));
    final upcoming = _closed.keys.where((k) => k.compareTo(todayKey) >= 0).toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming closed dates', style: AppTextStyles.headingMedium.copyWith(fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.active.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '${upcoming.length}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.active),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          _buildUpcomingEmpty(isDark, textSecondary)
        else
          ...upcoming.map((k) => _buildUpcomingItem(k, isDark, textSecondary)),
      ],
    );
  }

  Widget _buildUpcomingEmpty(bool isDark, Color textSecondary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_outlined, size: 40, color: AppColors.active),
          const SizedBox(height: 12),
          Text(
            'No closed dates ahead',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text('Tap a date to mark a holiday or rest day', style: TextStyle(fontSize: 13, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem(String key, bool isDark, Color textSecondary) {
    final day = _closed[key]!;
    final date = DateTime.parse(key);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.note.isNotEmpty ? '${day.reason.label} · ${day.note}' : day.reason.label,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: textSecondary),
            onPressed: () => _reopen(date),
            tooltip: 'Reopen this day',
          ),
        ],
      ),
    );
  }

  Future<void> _openSheet(DateTime date) async {
    final existing = _closed[_keyFormat.format(date)];
    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkClosedSheet(date: date, existing: existing),
    );
    if (result == null) return;
    if (result.reopen) {
      _reopen(date);
    } else {
      _markClosed(date, result.reason!, result.note);
    }
  }
}

class _SheetResult {
  const _SheetResult({this.reason, this.note = '', this.reopen = false});

  final ClosedReason? reason;
  final String note;
  final bool reopen;
}

/// Bottom sheet from 22.1.jpg — pick a reason and optional note for a closed day.
class _MarkClosedSheet extends StatefulWidget {
  const _MarkClosedSheet({required this.date, this.existing});

  final DateTime date;
  final _ClosedDay? existing;

  @override
  State<_MarkClosedSheet> createState() => _MarkClosedSheetState();
}

class _MarkClosedSheetState extends State<_MarkClosedSheet> {
  late ClosedReason _reason = widget.existing?.reason ?? ClosedReason.holiday;
  late final TextEditingController _noteController =
      TextEditingController(text: widget.existing?.note ?? '');

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgBase : AppColors.bgBaseLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit closed day' : 'Mark as closed',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(widget.date),
                          style: TextStyle(fontSize: 15, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('REASON', style: AppTextStyles.labelCaps.copyWith(color: textSecondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _reasonCard(ClosedReason.holiday, isDark, textPrimary, textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(child: _reasonCard(ClosedReason.dayOff, isDark, textPrimary, textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _reasonCard(ClosedReason.maintenance, isDark, textPrimary, textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(child: _reasonCard(ClosedReason.other, isDark, textPrimary, textSecondary)),
                ],
              ),
              const SizedBox(height: 24),
              Text('NOTES (OPTIONAL)', style: AppTextStyles.labelCaps.copyWith(color: textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: "e.g. New Year's Day",
                  hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.border : AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.active),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.active,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(
                    context,
                    _SheetResult(reason: _reason, note: _noteController.text.trim()),
                  ),
                  child: Text(
                    _isEditing ? 'Update' : 'Mark as closed',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, const _SheetResult(reopen: true)),
                    child: Text('Reopen this day', style: TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _reasonCard(ClosedReason reason, bool isDark, Color textPrimary, Color textSecondary) {
    final selected = _reason == reason;
    return GestureDetector(
      onTap: () => setState(() => _reason = reason),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.active.withValues(alpha: 0.12)
              : (isDark ? AppColors.bgSurface : AppColors.bgSurfaceLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.active : (isDark ? AppColors.border : AppColors.borderLight),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason.label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.active : textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(reason.subtitle, style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}
