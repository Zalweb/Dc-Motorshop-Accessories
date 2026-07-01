import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_options.dart';
import '../../shared/widgets/glass_container.dart';

const _kTimezones = <String>[
  'Asia/Manila (GMT+8)',
  'Asia/Singapore (GMT+8)',
  'Asia/Tokyo (GMT+9)',
  'Asia/Bangkok (GMT+7)',
  'UTC (GMT+0)',
];

const _kCurrencies = <String>[
  'PHP — Philippine Peso',
  'USD — US Dollar',
  'SGD — Singapore Dollar',
  'JPY — Japanese Yen',
];

/// Shop-wide branding and business details. Edits persist automatically — the
/// logo, accent theme, and business info propagate live to the dashboard,
/// More screen, and receipts via [businessSettingsStreamProvider].
class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _qrLinkController;

  String? _logoPath;
  late String _themeColor;
  late String _timezone;
  late String _currency;
  bool _initialized = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _qrLinkController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _qrLinkController.dispose();
    super.dispose();
  }

  /// Persists the current form state into the single settings record. The
  /// stream provider re-emits, so every screen reading it refreshes instantly.
  Future<void> _persist() async {
    await ref.read(settingsRepositoryProvider).update((s) {
      final name = _nameController.text.trim();
      s.businessName = name.isEmpty ? s.businessName : name;
      s.address = _emptyToNull(_addressController.text);
      s.phone = _emptyToNull(_phoneController.text);
      s.email = _emptyToNull(_emailController.text);
      s.receiptQrLink = _emptyToNull(_qrLinkController.text);
      s.logoPath = _logoPath;
      s.themeColor = _themeColor;
      s.timezone = _timezone;
      s.currency = _currency;
    });
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Debounced save for free-text fields so we don't write on every keystroke.
  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _persist);
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _logoPath = file.path);
    await _persist();
  }

  Future<void> _removeLogo() async {
    setState(() => _logoPath = null);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final settingsVal = ref.watch(businessSettingsStreamProvider);
    final theme = Theme.of(context);

    return settingsVal.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error loading settings: $error')),
      ),
      data: (settings) {
        if (settings == null) {
          return const Scaffold(body: Center(child: Text('No business settings found.')));
        }

        if (!_initialized) {
          _nameController.text = settings.businessName;
          _addressController.text = settings.address ?? '';
          _phoneController.text = settings.phone ?? '';
          _emailController.text = settings.email ?? '';
          _qrLinkController.text = settings.receiptQrLink ?? '';
          _logoPath = settings.logoPath;
          _themeColor = settings.themeColor;
          _timezone = settings.timezone;
          _currency = settings.currency;
          _initialized = true;
        }

        final businessName = _nameController.text.trim().isEmpty
            ? settings.businessName
            : _nameController.text.trim();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('General'),
                Text(
                  businessName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _brandingCard(theme, businessName),
              const SizedBox(height: 20),
              _businessDetailsCard(theme),
              const SizedBox(height: 20),
              _receiptsCard(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _brandingCard(ThemeData theme, String businessName) {
    final accent = theme.colorScheme.primary;
    final selectedOption = kThemeOptions.firstWhere(
      (o) => o.name == _themeColor,
      orElse: () => kThemeOptions.firstWhere((o) => o.name == 'Blue'),
    );

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            iconColor: Color(0xFF8B5CF6),
            icon: Icons.palette_rounded,
            title: 'Branding',
            subtitle: 'Logo and color theme appear on receipts and the web dashboard.',
          ),
          const SizedBox(height: 20),

          // Add-a-logo box.
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _DashedBox(
                    color: accent,
                    child: _logoPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _logoPath!.startsWith('http')
                                ? Image.network(
                                    _logoPath!,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_logoPath!),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        Icon(Icons.image_outlined, color: accent, size: 28),
                                  ),
                          )
                        : Icon(Icons.image_outlined, color: accent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _logoPath != null ? 'Logo added' : 'Add a logo',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _logoPath != null
                              ? 'Tap to change. Shows on receipts and the dashboard.'
                              : 'A square PNG or JPG looks best on receipts.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_logoPath != null)
                    IconButton(
                      onPressed: _removeLogo,
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.danger),
                      tooltip: 'Remove logo',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text('Color theme', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _ThemeGrid(
            selected: _themeColor,
            onSelected: (name) {
              setState(() => _themeColor = name);
              _persist();
            },
          ),
          const SizedBox(height: 20),

          // Live preview row.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                _logoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _logoPath!.startsWith('http')
                            ? Image.network(
                                _logoPath!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_logoPath!),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _initialAvatar(businessName, selectedOption.color),
                              ),
                      )
                    : _initialAvatar(businessName, selectedOption.color),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedOption.name} theme',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: selectedOption.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar(String name, Color color) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _businessDetailsCard(ThemeData theme) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            iconColor: Color(0xFF2563EB),
            icon: Icons.apartment_rounded,
            title: 'Business details',
            subtitle: 'These show on receipts and reports.',
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Business name', required: true),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (_) {
              setState(() {}); // refresh appbar subtitle + preview
              _onTextChanged();
            },
            decoration: const InputDecoration(hintText: 'Your shop name'),
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Address'),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            onChanged: (_) => _onTextChanged(),
            decoration: const InputDecoration(hintText: 'Street, Barangay, City'),
          ),
          const SizedBox(height: 6),
          _HelperText('Printed on customer receipts.'),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Phone'),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            onChanged: (_) => _onTextChanged(),
            decoration: const InputDecoration(hintText: '09XX XXX XXXX'),
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Email'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _onTextChanged(),
            decoration: const InputDecoration(hintText: 'shop@email.com'),
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Timezone'),
          const SizedBox(height: 8),
          _Dropdown(
            value: _timezone,
            items: _kTimezones,
            onChanged: (value) {
              setState(() => _timezone = value);
              _persist();
            },
          ),
          const SizedBox(height: 6),
          _HelperText('Used for daily totals & reports.'),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Currency'),
          const SizedBox(height: 8),
          _Dropdown(
            value: _currency,
            items: _kCurrencies,
            onChanged: (value) {
              setState(() => _currency = value);
              _persist();
            },
          ),
          const SizedBox(height: 6),
          _HelperText('Currency shown on prices and totals.'),
        ],
      ),
    );
  }

  Widget _receiptsCard(ThemeData theme) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            iconColor: Color(0xFF8B5CF6),
            icon: Icons.qr_code_rounded,
            title: 'Receipts',
            subtitle: 'Add a QR to every printed receipt so customers can scan to find you online.',
          ),
          const SizedBox(height: 20),
          _FieldLabel(text: 'Receipt QR link'),
          const SizedBox(height: 8),
          TextField(
            controller: _qrLinkController,
            keyboardType: TextInputType.url,
            onChanged: (_) => _onTextChanged(),
            decoration: const InputDecoration(hintText: 'https://facebook.com/yourshop'),
          ),
          const SizedBox(height: 6),
          _HelperText('Your FB page, online ordering link, or GCash QR URL. Leave empty to hide.'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        if (required)
          Text(' *', style: AppTextStyles.body.copyWith(color: AppColors.danger)),
      ],
    );
  }
}

class _HelperText extends StatelessWidget {
  const _HelperText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.value, required this.items, required this.onChanged});

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = items.contains(value) ? items : [value, ...items];
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant),
      items: [
        for (final item in options)
          DropdownMenuItem(value: item, child: Text(item, style: AppTextStyles.body)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final option in kThemeOptions)
              SizedBox(
                width: itemWidth,
                child: _ThemeChip(
                  option: option,
                  selected: option.name == selected,
                  onTap: () => onSelected(option.name),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.option, required this.selected, required this.onTap});

  final ThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lighter = Color.lerp(option.color, Colors.white, 0.35)!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? option.color.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? option.color : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Two overlapping shade circles.
            SizedBox(
              width: 26,
              height: 16,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: CircleAvatar(radius: 8, backgroundColor: option.color),
                  ),
                  Positioned(
                    left: 10,
                    child: CircleAvatar(radius: 8, backgroundColor: lighter),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                option.name,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? option.color : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square dashed-border tile used as the logo drop target.
class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
