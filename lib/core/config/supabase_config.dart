class SupabaseConfig {
  static const String url = 'https://lhbjpxdebwgninedzker.supabase.co';

  static const String publishableKey =
      'sb_publishable_LekZzQ8VfBygE58dm1wCSw_GOkbNz1W';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxoYmpweGRlYndnbmluZWR6a2VyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1MTE1OTEsImV4cCI6MjExMDA4NzU5MX0.LLVRK2jl6XV9ljagfh4tOwEoIMAh09lqncUUVAur31E';

  /// Traduz erros técnicos do Supabase/PostgreSQL para mensagens táticas claras ao sobrevivente.
  static String translateError(Object error) {
    final msg = error.toString();
    final lower = msg.toLowerCase();

    if (lower.contains('pgrst205') ||
        lower.contains('could not find the table')) {
      return 'As tabelas do banco ainda não foram criadas no Supabase (erro PGRST205). '
          'Execute o script supabase/schema.sql no SQL Editor do Supabase ou ative o Modo Simulação Tática.';
    }
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Credenciais inválidas: e-mail ou senha incorretos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Este e-mail já está registrado na rede de sobreviventes.';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return 'E-mail aguarda confirmação no Supabase Auth (desative "Confirm email" em Authentication > Providers > Email no painel do Supabase).';
    }
    if (lower.contains('profiles_nickname_key') ||
        (lower.contains('duplicate key') && lower.contains('nickname'))) {
      return 'Este codinome (apelido) já está em uso por outro sobrevivente.';
    }
    if (lower.contains('alert_confirmations_alert_id_user_id_key') ||
        (lower.contains('duplicate key') &&
            lower.contains('alert_confirmations'))) {
      return 'Você já confirmou este avistamento de horda.';
    }
    if (lower.contains('idx_one_active_expedition_per_user')) {
      return 'Você já possui uma expedição em andamento!';
    }
    if (lower.contains('row-level security') ||
        lower.contains('42501') ||
        lower.contains('new row violates row-level security')) {
      return 'BLOQUEIO ANTI-CHEAT (RLS): O servidor recusou a alteração direta! Operação permitida apenas via RPC oficial.';
    }
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception')) {
      return 'Sem conexão com a torre de rádio (verifique sua internet).';
    }

    // Extrai mensagem limpa de RAISE EXCEPTION do PL/pgSQL se disponível
    final reg = RegExp(r'message:\s*([^,}\]]+)', caseSensitive: false);
    final match = reg.firstMatch(msg);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }

    return msg
        .replaceAll('Exception:', '')
        .replaceAll('PostgrestException(', '')
        .replaceAll('AuthException(', '')
        .trim();
  }
}
