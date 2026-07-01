import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/sync/secure_backup_service.dart';
import '../../shared/widgets/glass_container.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  final _exportFormKey = GlobalKey<FormState>();
  final _importFormKey = GlobalKey<FormState>();

  final _exportPasswordController = TextEditingController();
  final _importPasswordController = TextEditingController();

  bool _obscureExportPassword = true;
  bool _obscureImportPassword = true;
  bool _isLoading = false;
  String _loadingMessage = '';

  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _exportPasswordController.dispose();
    _importPasswordController.dispose();
    super.dispose();
  }

  void _showLoading(String message) {
    setState(() {
      _isLoading = true;
      _loadingMessage = message;
    });
  }

  void _hideLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleExport() async {
    if (!_exportFormKey.currentState!.validate()) return;

    _showLoading('Generating secure backup...');
    try {
      final password = _exportPasswordController.text;
      final backupService = ref.read(secureBackupServiceProvider);

      // 1. Serialize all data to JSON
      final jsonString = await backupService.exportDatabaseToJson();

      // 2. Encrypt
      final encryptedBytes = SecureBackupService.encryptPayload(jsonString, password);

      // 3. Write to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/dc_backup_$timestamp.bin');
      await file.writeAsBytes(encryptedBytes);

      _hideLoading();

      // 4. Trigger Native Share sheet
      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/octet-stream')],
            subject: 'DC Motorshop Backup Data',
            sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          ),
        );
      }
    } catch (e) {
      _hideLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleImport() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a backup file first'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    if (!_importFormKey.currentState!.validate()) return;

    // Show warning dialog first
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
              const SizedBox(width: 8),
              Text('Overwrite Local Data?', style: AppTextStyles.headingMedium.copyWith(fontSize: 18)),
            ],
          ),
          content: const Text(
            'This action is permanent and destructive. All of your current inventory, sales, expenses, users, and business settings will be completely replaced by the data in this backup file. Are you absolutely sure you want to proceed?',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Overwrite'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    _showLoading('Decrypting and restoring data...');
    try {
      final password = _importPasswordController.text;
      final fileBytes = await File(_selectedFile!.path!).readAsBytes();

      // 1. Decrypt (validates HMAC and password)
      final jsonString = SecureBackupService.decryptPayload(fileBytes, password);

      // 2. Clear collections and insert data into Isar
      final backupService = ref.read(secureBackupServiceProvider);
      await backupService.importDatabaseFromJson(jsonString);

      _hideLoading();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _hideLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is FormatException
                  ? 'Decryption failed: Incorrect password or corrupted backup file'
                  : 'Import failed: ${e.toString()}',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Import/Export Data'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info block
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device-to-Device Transfer',
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use this feature to securely move your motorshop data between phones. Your data is encrypted with a password you define, preventing unauthorized access.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: Local item photos that have not been synced to the cloud will not be transferred.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: EXPORT
                Text(
                  'EXPORT DATA',
                  style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _exportFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export current shop data',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Creates an encrypted backup file containing all users, settings, inventory catalog, expenses, and sales receipts.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _exportPasswordController,
                          obscureText: _obscureExportPassword,
                          style: AppTextStyles.body,
                          decoration: InputDecoration(
                            labelText: 'Backup Password',
                            hintText: 'Enter password to encrypt file',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureExportPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureExportPassword = !_obscureExportPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a backup encryption password';
                            }
                            if (value.trim().length < 4) {
                              return 'Password must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _handleExport,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Export & Share Backup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // SECTION: IMPORT
                Text(
                  'IMPORT DATA',
                  style: AppTextStyles.labelCaps.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _importFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restore from backup file',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Loads data from a previously exported backup file. Note: This will overwrite all your current local data.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // File selector widget
                        InkWell(
                          onTap: _pickBackupFile,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedFile != null
                                    ? primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedFile != null
                                  ? primary.withOpacity(0.05)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedFile != null
                                      ? Icons.insert_drive_file_rounded
                                      : Icons.file_present_rounded,
                                  color: _selectedFile != null
                                      ? primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile != null
                                            ? _selectedFile!.name
                                            : 'No file selected',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: _selectedFile != null
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_selectedFile != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedFile != null ? 'Change' : 'Choose File',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_selectedFile != null) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _importPasswordController,
                            obscureText: _obscureImportPassword,
                            style: AppTextStyles.body,
                            decoration: InputDecoration(
                              labelText: 'Decryption Password',
                              hintText: 'Enter password used to encrypt file',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureImportPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureImportPassword = !_obscureImportPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the decryption password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _handleImport,
                            icon: const Icon(Icons.settings_backup_restore_rounded),
                            label: const Text('Decrypt & Restore Backup'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: theme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
