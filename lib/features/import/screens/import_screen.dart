import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../providers/import_provider.dart';
import '../../../core/theme/app_colors.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  @override
  void initState() {
    super.initState();
    // Check permission on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(importNotifierProvider.notifier).checkPermission();
      ref.read(importNotifierProvider.notifier).refreshCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Index')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPermissionSection(importState),
            const SizedBox(height: 24),
            if (importState.isImporting || importState.progress.total > 0)
              _buildProgressSection(importState),
            if (!importState.isImporting && importState.progress.total == 0)
              _buildEmptyState(importState),
            if (importState.error != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(importState.error!),
            ],
            if (importState.progress.failed > 0 &&
                !importState.isImporting) ...[
              const SizedBox(height: 16),
              _buildRetrySection(importState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSection(ImportState importState) {
    final hasPermission =
        importState.permissionState == PermissionState.authorized ||
        importState.permissionState == PermissionState.limited;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasPermission ? Icons.check_circle : Icons.photo_library,
                  color: hasPermission
                      ? AppColors.success
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Media Access',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasPermission
                  ? importState.permissionState == PermissionState.limited
                        ? 'Limited access — some photos may not be visible.'
                        : 'Full media access granted.'
                  : 'Permission required to discover screenshots on your device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!hasPermission) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  ref.read(importNotifierProvider.notifier).requestPermission();
                },
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Grant Access'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ImportState importState) {
    final hasPermission =
        importState.permissionState == PermissionState.authorized ||
        importState.permissionState == PermissionState.limited;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Index Screenshots',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Discover and index your existing screenshots without duplicating them.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: hasPermission && !importState.isDiscovering
                  ? () {
                      ref
                          .read(importNotifierProvider.notifier)
                          .discoverAndImport();
                    }
                  : null,
              icon: importState.isDiscovering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(
                importState.isDiscovering
                    ? 'Discovering...'
                    : 'Discover & Index',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(ImportState importState) {
    final progress = importState.progress;
    final processed =
        progress.completed + progress.failed + progress.duplicates;
    final fraction = progress.total > 0 ? processed / progress.total : 0.0;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.isRunning ? 'Indexing...' : 'Indexing Complete',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (progress.isRunning)
                  TextButton(
                    onPressed: () {
                      ref.read(importNotifierProvider.notifier).cancelImport();
                    },
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.isRunning ? fraction : 1.0,
                backgroundColor: AppColors.surfaceHigh,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$processed / ${progress.total}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  Icons.check_circle,
                  AppColors.success,
                  '${progress.completed} imported',
                ),
                if (progress.duplicates > 0)
                  _buildStatChip(
                    Icons.content_copy,
                    AppColors.warning,
                    '${progress.duplicates} duplicates',
                  ),
                if (progress.failed > 0)
                  _buildStatChip(
                    Icons.error,
                    AppColors.danger,
                    '${progress.failed} failed',
                  ),
                if (progress.pending > 0 && progress.isRunning)
                  _buildStatChip(
                    Icons.pending,
                    AppColors.textMuted,
                    '${progress.pending} pending',
                  ),
              ],
            ),
            if (progress.currentFile != null &&
                progress.currentFile!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                progress.currentFile!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: AppColors.danger.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetrySection(ImportState importState) {
    return FilledButton.icon(
      onPressed: () {
        ref.read(importNotifierProvider.notifier).retryFailed();
      },
      icon: const Icon(Icons.refresh, size: 18),
      label: Text('Retry ${importState.progress.failed} Failed'),
      style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
    );
  }
}
