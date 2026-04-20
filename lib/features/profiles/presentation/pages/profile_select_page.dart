import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/iptv_provider.dart';
import '../../../../core/models/profile.dart';
import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/update_dialog.dart';

const _kAvatars = [
  '👤', '👨', '👩', '👦', '👧', '🧑', '👴', '👵',
  '🦸', '🦹', '🧙', '🧝', '🎮', '🎬', '🎵', '⚽',
];

class ProfileSelectPage extends ConsumerStatefulWidget {
  const ProfileSelectPage({super.key});

  @override
  ConsumerState<ProfileSelectPage> createState() =>
      _ProfileSelectPageState();
}

class _ProfileSelectPageState
    extends ConsumerState<ProfileSelectPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check for updates after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize remote config first
      try {
        final config = ref.read(remoteConfigServiceProvider);
        await config.initialize();
      } catch (_) {}
      if (mounted) {
        await checkAndShowUpdate(context, ref);
      }
    });
  }

  int get _maxProfiles {
    final p = ref.read(iptvProviderDataProvider);
    return p?.userInfo?.maxConnections ?? 1;
  }

  Future<void> _selectProfile(AppProfile profile) async {
    setState(() => _isLoading = true);
    await saveActiveProfileId(profile.id);
    // Sync BOTH: global notifier (triggers router) AND Riverpod (triggers providers)
    profileNotifier.setProfile(profile);
    ref.read(activeProfileProvider.notifier).state = profile;
    // Router will redirect to /live-tv automatically via profileNotifier
  }

  Future<void> _createProfile(
      List<AppProfile> existing) async {
    if (existing.length >= _maxProfiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Limite de $_maxProfiles perfil(s) atingido.\n'
              'Seu plano permite $_maxProfiles conexão(ões) simultânea(s).'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _CreateProfileDialog(),
    );
    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      final svc = ref.read(profileServiceProvider);
      if (svc == null) return;
      final profile = await svc.createProfile(
          result['name']!, result['avatar']!);
      ref.invalidate(profilesProvider);
      await _selectProfile(profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar perfil: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProfile(AppProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir perfil',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
            'Excluir "${profile.name}"? O histórico será apagado.',
            style:
                const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final svc = ref.read(profileServiceProvider);
    if (svc == null) return;
    await svc.deleteProfile(profile.id);
    ref.invalidate(profilesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final maxProfiles = _maxProfiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Header
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.neonGradient.createShader(b),
              child: const Text(
                'ZYRION PLAY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quem está assistindo?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plano permite $maxProfiles perfil(s)',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),

            // Profiles grid
            Expanded(
              child: profilesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Erro: $e',
                      style: const TextStyle(
                          color: AppColors.textMuted)),
                ),
                data: (profiles) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: profiles.length < maxProfiles
                        ? profiles.length + 1
                        : profiles.length,
                    itemBuilder: (context, i) {
                      if (i == profiles.length &&
                          profiles.length < maxProfiles) {
                        // Add profile button
                        return GestureDetector(
                          onTap: () =>
                              _createProfile(profiles),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surfaceVariant,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withOpacity(0.4),
                                    width: 2,
                                    strokeAlign: BorderSide
                                        .strokeAlignOutside,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Adicionar',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final profile = profiles[i];
                      return GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => _selectProfile(profile),
                        onLongPress: () =>
                            _deleteProfile(profile),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient:
                                    AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  profile.avatar,
                                  style: const TextStyle(
                                      fontSize: 32),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Hint
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Pressione e segure para excluir um perfil',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),

            // Logout
            TextButton.icon(
              onPressed: () async {
                await clearActiveProfileId();
                ref.read(activeProfileProvider.notifier).state =
                    null;
                // Go back to login via authNotifier
                await IptvProvider.clear();
                ref
                    .read(iptvProviderDataProvider.notifier)
                    .state = null;
                // ignore: use_build_context_synchronously
                if (mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.textMuted, size: 16),
              label: const Text(
                'Trocar conta',
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Create profile dialog ─────────────────────────────────────────────────────
class _CreateProfileDialog extends StatefulWidget {
  const _CreateProfileDialog();

  @override
  State<_CreateProfileDialog> createState() =>
      _CreateProfileDialogState();
}

class _CreateProfileDialogState
    extends State<_CreateProfileDialog> {
  final _nameCtrl = TextEditingController();
  String _selectedAvatar = _kAvatars.first;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: const Text('Novo Perfil',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar picker — fixed height grid
            SizedBox(
              height: 130,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _kAvatars.length,
                itemBuilder: (context, i) {
                  final av = _kAvatars[i];
                  final selected = av == _selectedAvatar;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedAvatar = av),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: selected
                            ? Border.all(
                                color: AppColors.primary,
                                width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(av,
                            style:
                                const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Name field
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: const TextStyle(
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nome do perfil',
                hintStyle: const TextStyle(
                    color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, {
              'name': name,
              'avatar': _selectedAvatar,
            });
          },
          child: const Text('Criar',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
