import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/game_providers.dart';
import '../widgets/survival_2d_art.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(gameControllerProvider.notifier);
    try {
      if (_isLogin) {
        await notifier.signIn(_emailCtrl.text, _passwordCtrl.text);
      } else {
        await notifier.signUp(
          _nicknameCtrl.text,
          _emailCtrl.text,
          _passwordCtrl.text,
        );
      }
      if (!mounted) return;
      final stage = ref.read(gameControllerProvider).authStage;
      if (stage == PlayerAuthState.authenticatedNoFaction) {
        context.go('/escolher-faccao');
      } else if (stage == PlayerAuthState.complete) {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _copyFixedSqlToClipboard() async {
    try {
      final sql = await rootBundle.loadString('supabase/schema.sql');
      await Clipboard.setData(ClipboardData(text: sql));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Script SQL corrigido (supabase/schema.sql) copiado! Cole no SQL Editor do Supabase e clique em Run.',
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _startTacticalSimulation() async {
    final nick = _nicknameCtrl.text.trim().isNotEmpty
        ? _nicknameCtrl.text.trim()
        : 'Sobrevivente_Z';
    await ref.read(gameControllerProvider.notifier).enterSimulationMode(nick);
    if (!mounted) return;
    context.go('/escolher-faccao');
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ProtocoloZLogo2D(size: 115),
                  const SizedBox(height: 16),
                  const Text(
                    'TERMINAL PROTOCOLO Z',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                      color: ProtocoloZColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Identifique-se para acessar a rede tática de sobreviventes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: ProtocoloZColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Abas Login / Cadastro
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModeTab(
                                    label: 'ENTRAR',
                                    selected: _isLogin,
                                    onTap: () => setState(() {
                                      _isLogin = true;
                                      _localError = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildModeTab(
                                    label: 'ALISTAR-SE',
                                    selected: !_isLogin,
                                    onTap: () => setState(() {
                                      _isLogin = false;
                                      _localError = null;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nicknameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Codinome (Apelido)',
                                  hintText: 'Ex: Fantasma_07',
                                  prefixIcon: Icon(
                                    Icons.badge_rounded,
                                    color: ProtocoloZColors.radarGreen,
                                  ),
                                ),
                                validator: (v) {
                                  if (_isLogin) return null;
                                  final val = v?.trim() ?? '';
                                  if (val.length < 3) {
                                    return 'Informe um apelido com ao menos 3 caracteres.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'E-mail de Frequência',
                                hintText: 'sobrevivente@resistencia.org',
                                prefixIcon: Icon(
                                  Icons.alternate_email_rounded,
                                  color: ProtocoloZColors.radarGreen,
                                ),
                              ),
                              validator: (v) {
                                final val = v?.trim() ?? '';
                                if (val.isEmpty || !val.contains('@')) {
                                  return 'Informe um e-mail válido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Senha de Acesso',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: ProtocoloZColors.radarGreen,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: ProtocoloZColors.steelGray,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if ((v ?? '').length < 6) {
                                  return 'A senha deve ter pelo menos 6 caracteres.';
                                }
                                return null;
                              },
                            ),
                            if (_localError != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ProtocoloZColors.darkRedSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: ProtocoloZColors.hordeRed,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: ProtocoloZColors.hordeRed,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _localError!,
                                            style: const TextStyle(
                                              color: ProtocoloZColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_localError!.contains('PGRST205') ||
                                        _localError!.contains('schema.sql') ||
                                        _localError!.contains('Confirm email')) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: _copyFixedSqlToClipboard,
                                            icon: const Icon(
                                              Icons.copy_rounded,
                                              size: 15,
                                            ),
                                            label: const Text(
                                              'COPIAR SQL CORRIGIDO',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: _startTacticalSimulation,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  ProtocoloZColors.crimsonRed,
                                            ),
                                            icon: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'MODO SIMULAÇÃO TÁTICA',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: gs.isLoading ? null : _submit,
                                icon: gs.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _isLogin
                                            ? Icons.login_rounded
                                            : Icons.person_add_alt_1_rounded,
                                      ),
                                label: Text(
                                  gs.isLoading
                                      ? 'CONECTANDO AO SERVIDOR...'
                                      : _isLogin
                                      ? 'ACESSAR CENTRAL'
                                      : 'CRIAR CONTA E RECEBER CREDENCIAL',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ProtocoloZColors.radarGreen,
                        side: const BorderSide(
                          color: ProtocoloZColors.radarGreen,
                          width: 1.6,
                        ),
                        backgroundColor: ProtocoloZColors.darkGreen.withValues(
                          alpha: 0.35,
                        ),
                      ),
                      onPressed: _startTacticalSimulation,
                      icon: const Icon(
                        Icons.bolt_rounded,
                        size: 20,
                        color: ProtocoloZColors.radarGreen,
                      ),
                      label: const Text(
                        'ENTRAR DIRETO (MODO DEMO SEM SUPABASE)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? ProtocoloZColors.tacticalGreen.withValues(alpha: 0.28)
              : ProtocoloZColors.bgDarkest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? ProtocoloZColors.radarGreen
                : ProtocoloZColors.borderGray,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.0,
            color: selected
                ? ProtocoloZColors.radarGreen
                : ProtocoloZColors.textMuted,
          ),
        ),
      ),
    );
  }
}
