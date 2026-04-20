import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final updateInfoProvider = FutureProvider<UpdateInfo?>((ref) async {
  return UpdateService.checkForUpdate();
});

// ── Check and show update dialog if needed ────────────────────────────────────
Future<void> checkAndShowUpdate(BuildContext context, WidgetRef ref) async {
  final info = await ref.read(updateInfoProvider.future);
  if (info == null || !info.hasUpdate) return;
  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (_) => UpdateDialog(info: info),
  );
}

// ── Dialog widget ─────────────────────────────────────────────────────────────
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _progress = 0;
  bool _downloading = false;
  bool _downloaded = false;
  String? _apkPath;
  String? _error;
  CancelToken? _cancelToken;

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });

    _cancelToken = CancelToken();

    final path = await UpdateService.downloadApk(
      widget.info.downloadUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      cancelToken: _cancelToken,
    );

    if (!mounted) return;

    if (path != null) {
      setState(() {
        _downloading = false;
        _downloaded = true;
        _apkPath = path;
      });
    } else {
      setState(() {
        _downloading = false;
        _error = 'Falha no download. Tente novamente.';
      });
    }
  }

  Future<void> _install() async {
    if (_apkPath == null) return;
    try {
      await OpenFile.open(_apkPath!);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = 'Não foi possível instalar. Abra o arquivo manualmente.');
      }
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.system_update_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Atualização disponível',
              style: TextStyle(
                  color: AppColors.textPrimary, fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Versão atual',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      '${widget.info.currentVersion} (${widget.info.currentBuild})',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.textMuted, size: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Nova versão',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    Text(
                      '${widget.info.latestVersion} (${widget.info.latestBuild})',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Changelog
          if (widget.info.changelog.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.info.changelog,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (widget.info.forceUpdate) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Esta atualização é obrigatória.',
                      style: TextStyle(
                          color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Progress bar
          if (_downloading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        if (!widget.info.forceUpdate && !_downloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agora não',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        if (!_downloaded)
          TextButton(
            onPressed: _downloading ? null : _download,
            child: _downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text('Baixar',
                    style: TextStyle(color: AppColors.primary)),
          )
        else
          ElevatedButton.icon(
            onPressed: _install,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.install_mobile_rounded, size: 16),
            label: const Text('Instalar agora'),
          ),
      ],
    );
  }
}
