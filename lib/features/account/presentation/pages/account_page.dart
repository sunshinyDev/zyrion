import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/iptv_provider.dart';
import '../../../../core/providers/iptv_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/update_dialog.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(iptvProviderDataProvider);
    final info = provider?.userInfo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Minha Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(provider),
            const SizedBox(height: 16),

            // ── Expiration banner ──────────────────────────────
            if (info != null) ...[
              _ExpirationCard(info: info),
              const SizedBox(height: 16),
            ],

            _buildSection(
              title: 'Servidor',
              items: [
                _MenuItem(
                  icon: Icons.vpn_key_rounded,
                  label: 'Provedor',
                  subtitle: provider?.providerCode ?? '-',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.dns_rounded,
                  label: 'Servidor ativo',
                  subtitle: provider?.workingHost ?? '-',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Usuário',
                  subtitle: provider?.username ?? '-',
                  onTap: () {},
                ),
                if (info != null)
                  _MenuItem(
                    icon: Icons.wifi_rounded,
                    label: 'Conexões simultâneas',
                    subtitle: '${info.maxConnections}',
                    onTap: () {},
                  ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Cache',
              items: [
                _MenuItem(
                  icon: Icons.cleaning_services_rounded,
                  label: 'Limpar cache de listas',
                  subtitle: 'Força recarregamento do servidor',
                  onTap: () async {
                    await XtreamService.clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cache limpo com sucesso.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: 'Suporte',
              items: [
                _MenuItem(
                  icon: Icons.system_update_rounded,
                  label: 'Verificar atualizações',
                  subtitle: 'v1.0.0',
                  onTap: () async {
                    final config = ref.read(remoteConfigServiceProvider);
                    try { await config.initialize(); } catch (_) {}
                    if (context.mounted) {
                      await checkAndShowUpdate(context, ref);
                    }
                  },
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'Sobre o app',
                  subtitle: 'v1.0.0',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Switch profile
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  profileNotifier.setProfile(null);
                  ref.read(activeProfileProvider.notifier).state = null;
                  clearActiveProfileId();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.switch_account_rounded,
                    color: AppColors.primary),
                label: const Text(
                  'Trocar perfil',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.error),
                label: const Text(
                  'Sair da conta',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(IptvProvider? provider) {
    final initial =
        (provider?.username.isNotEmpty == true
                ? provider!.username[0]
                : 'U')
            .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider?.username ?? 'Usuário',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider?.providerCode ?? '',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _MenuTile(item: item),
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: AppColors.surfaceVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Sair da conta',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Tem certeza que deseja sair?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await IptvProvider.clear();
              await XtreamService.clearCache();
              await clearActiveProfileId();
              profileNotifier.setProfile(null);
              ref.read(iptvProviderDataProvider.notifier).state = null;
              ref.read(activeProfileProvider.notifier).state = null;
              await authNotifier.refresh();
            },
            child: const Text('Sair',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Expiration card ───────────────────────────────────────────────────────────
class _ExpirationCard extends StatelessWidget {
  final IptvUserInfo info;
  const _ExpirationCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (info.isExpired) {
      color = AppColors.error;
      label = 'Plano expirado';
      icon = Icons.cancel_rounded;
    } else if (info.expiresWithin2Days) {
      color = AppColors.error;
      final h = info.hoursRemaining;
      label = h <= 0 ? 'Expira em menos de 1h' : 'Expira em ${h}h';
      icon = Icons.warning_rounded;
    } else if (info.expiresWithin7Days) {
      color = AppColors.warning;
      label = 'Expira em ${info.daysRemaining} dias';
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppColors.success;
      final d = info.daysRemaining;
      label = d >= 9999
          ? 'Sem data de expiração'
          : 'Expira em $d dias';
      icon = Icons.check_circle_rounded;
    }

    final expStr = info.expDate != null
        ? '${info.expDate!.day.toString().padLeft(2, '0')}/'
            '${info.expDate!.month.toString().padLeft(2, '0')}/'
            '${info.expDate!.year}'
        : 'Sem data';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vencimento: $expStr'
                  '${info.isTrial ? ' · Trial' : ''}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: item.onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon,
            color: AppColors.textSecondary, size: 18),
      ),
      title: Text(item.label,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12))
          : null,
      trailing: item.trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
