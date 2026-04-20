import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/iptv_provider.dart';
import '../../../../core/providers/iptv_provider.dart' as prov;
import '../../../../core/router/app_router.dart';
import '../../../../core/services/xtream_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/zyrion_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _codeCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _error;
  String _status = '';

  @override
  void dispose() {
    _codeCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _setStatus(String s) {
    if (mounted) setState(() => _status = s);
  }

  Future<void> _login() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (code.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Preencha todos os campos.');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
      _status = 'Buscando provedor...';
    });

    try {
      // 1. Fetch hosts from Firebase
      final db = FirebaseDatabase.instance;
      final snap = await db.ref('provedores/$code').get();

      if (!snap.exists || snap.value == null) {
        setState(() {
          _error = 'Código de provedor não encontrado.';
          _isLoading = false;
          _status = '';
        });
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);

      // Check if provider is active
      if (data['deleted'] == true) {
        setState(() {
          _error = 'Este provedor está desativado.';
          _isLoading = false;
          _status = '';
        });
        return;
      }

      // Parse hosts list
      final rawHosts = data['hosts'];
      final List<String> hosts = [];
      if (rawHosts is List) {
        hosts.addAll(rawHosts.map((e) => e.toString()));
      }

      if (hosts.isEmpty) {
        setState(() {
          _error = 'Provedor sem servidores configurados.';
          _isLoading = false;
          _status = '';
        });
        return;
      }

      // 2. Try each host with the provided credentials
      _setStatus('Conectando ao servidor (0/${hosts.length})...');

      String? workingHost;
      IptvUserInfo? userInfo;
      String? authError;

      for (int i = 0; i < hosts.length; i++) {
        _setStatus('Testando servidor ${i + 1}/${hosts.length}...');

        final tempProvider = IptvProvider(
          workingHost: hosts[i],
          username: username,
          password: password,
          providerCode: code,
        );

        final svc = XtreamService(tempProvider);
        final result =
            await svc.authenticateWithHostsFull([hosts[i]]);

        if (result.success) {
          workingHost = hosts[i];
          userInfo = result.userInfo;
          break;
        } else if (result.error == 'Usuário ou senha inválidos.') {
          authError = result.error;
          break;
        }
        authError = result.error;
      }

      if (workingHost == null) {
        setState(() {
          _error = authError ?? 'Nenhum servidor disponível no momento.';
          _isLoading = false;
          _status = '';
        });
        return;
      }

      // 3. Save and navigate
      _setStatus('Entrando...');
      final provider = IptvProvider(
        workingHost: workingHost,
        username: username,
        password: password,
        providerCode: code,
        userInfo: userInfo,
      );

      await provider.save();

      if (mounted) {
        ref.read(prov.iptvProviderDataProvider.notifier).state = provider;
        await authNotifier.refresh();
      }
    } catch (e) {
      setState(() {
        _error = 'Erro inesperado: $e';
        _isLoading = false;
        _status = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const ZyrionLogo(size: 90),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) => AppColors.neonGradient.createShader(b),
                child: const Text(
                  'ZYRION PLAY',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'O universo do entretenimento',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Entrar',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                        'Digite o código do provedor e suas credenciais.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 24),

                    _Field(
                      controller: _codeCtrl,
                      label: 'Código do Provedor',
                      hint: 'ex: RYZEEN',
                      icon: Icons.vpn_key_rounded,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        LengthLimitingTextInputFormatter(30),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _Field(
                      controller: _userCtrl,
                      label: 'Usuário',
                      hint: 'seu usuário',
                      icon: Icons.person_outline_rounded,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _Field(
                      controller: _passCtrl,
                      label: 'Senha',
                      hint: 'sua senha',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePass,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),

                    // Status message while loading
                    if (_isLoading && _status.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(_status,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13)),
                        ],
                      ),
                    ],

                    // Error message
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? null
                              : AppColors.primaryGradient,
                          color: _isLoading
                              ? AppColors.surfaceVariant
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextButton(
                          onPressed: _isLoading ? null : _login,
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.rocket_launch_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('ENTRAR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        )),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Não possui acesso?\nContate seu provedor de conteúdo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.inputFormatters,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.textMuted, fontSize: 14),
            prefixIcon:
                Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: suffixIcon,
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
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
