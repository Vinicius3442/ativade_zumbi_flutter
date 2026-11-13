# Protocolo Z — Rede Tática de Sobrevivência (Flutter + Supabase)

Aplicativo mobile multi-jogador em tempo real desenvolvido em **Flutter** e **Supabase** para a atividade **Protocolo Z: Sobreviver é um trabalho em equipe!**.

---

## 1. Identidade Visual e Tema 2D
- **Paleta Temática**:
  - **Verde Radar / Bio-Tático** (`#00E676`, `#2E7D32`, `#43A047`): Zonas seguras, radar tático, suprimentos e confirmações.
  - **Cinza Bunker / Aço** (`#0E1311`, `#151C19`, `#26312C`, `#78909C`): Estrutura blindada, HUD tático e ruínas urbanas.
  - **Vermelho Alerta de Horda** (`#FF1744`, `#D32F2F`, `#2D1215`): Alertas de horda em tempo real, risco elevado e bloqueios anti-cheat.
- **Desenhos e Cenas 2D (`CustomPainter`)**:
  - `ProtocoloZLogo2D`: Emblema vetorial 2D animado com feixe de varredura de radar e símbolo Z.
  - `ExpeditionScene2D`: Cena 2D animada com ruínas urbanas, sobrevivente com lanterna tática, partículas de cinzas e silhuetas de zumbis.
  - `TacticalRadar2D`: Radar 2D em tempo real no painel principal indicando abrigos próximos (blips verdes) e alertas de horda ativos (blips vermelhos).

---

## 2. Tabela de Reputação Adotada (Garantida pelo Servidor)

A reputação é a pontuação oficial do sobrevivente e **nunca pode ser alterada diretamente pelo cliente** (protegida por RLS `WITH CHECK` na tabela `profiles`):

| Ação no Jogo | Reputação Concedida | Mecanismo no Servidor (Supabase) |
| :--- | :---: | :--- |
| **Concluir uma expedição** | **+10** | Função RPC `public.claim_expedition(p_expedition_id)` |
| **Cadastrar um abrigo** | **+15** | Trigger `BEFORE INSERT` `public.handle_new_shelter()` |
| **Concluir uma troca (cada jogador)** | **+20** | Função RPC `public.respond_trade(p_trade_id, 'accept')` |
| **Ter um alerta confirmado por 2 jogadores** | **+25** | Função RPC `public.confirm_horde_alert(p_alert_id)` |

---

## 3. Instruções para Criar o Banco, Configurar as Chaves e Executar

### 3.1. Recriando o Banco de Dados no Supabase
1. Acesse o painel do seu projeto no [Supabase](https://supabase.com/dashboard).
2. Abra o **SQL Editor** e clique em **New Query**.
3. Copie todo o conteúdo do arquivo [`supabase/schema.sql`](supabase/schema.sql) (também espelhado em `Banco/supabase.sql`) e clique em **Run**.
   - O script cria automaticamente todas as **12 tabelas**, **views de ranking** (`survivors_ranking` e `factions_ranking`), **triggers**, **6 funções RPC (`SECURITY DEFINER`)**, **policies de RLS**, **canais Realtime**, **buckets de Storage** (`avatars` e `shelters`) e **dados iniciais (seed)**.
4. Em **Authentication > Providers > Email**, recomenda-se desativar a opção **"Confirm email"** para agilizar o cadastro de múltiplos jogadores durante a apresentação em sala.

### 3.2. Configuração das Chaves
As chaves públicas já estão configuradas em [`lib/core/config/supabase_config.dart`](lib/core/config/supabase_config.dart):
- **Supabase URL**: `https://lhbjpxdebwgninedzker.supabase.co`
- **Publishable Key**: `sb_publishable_LekZzQ8VfBygE58dm1wCSw_GOkbNz1W`
- **Anon Key**: configurada em `SupabaseConfig.anonKey`
- *Segurança*: A chave `service_role` **jamais** está presente no código-fonte ou no repositório.

### 3.3. Executando o Projeto
```bash
flutter pub get
flutter run
```

---

## 4. Arquitetura em Camadas e Explicações Técnicas (Roteiro de Apresentação)

### 4.1. Organização em Camadas (`lib/`)
- `lib/models/`: Classes de dados imutáveis com serialização `fromJson` / `toJson` (`FactionModel`, `ProfileModel`, `ItemModel`, `InventoryEntryModel`, `ShelterModel`, `ExpeditionModel`, `TradeModel`, `HordeAlertModel`, `SurvivorRankModel`, `FactionRankModel`).
- `lib/repositories/` e `lib/services/`: Todo o acesso ao Supabase (`ProtocoloZRepository`) e cache offline local (`LocalCacheService`). **Nenhuma tela chama o Supabase diretamente.**
- `lib/providers/`: Gerenciamento de estado reativo com **Riverpod** (`GameController` / `StateNotifier<GameState>`).
- `lib/router/`: Navegação declarativa com **GoRouter** (`app_router.dart`).
- `lib/widgets/`: **6 widgets personalizados reutilizados** (`FactionBadge`, `ItemTile`, `ShelterCard`, `TradeCard`, `HordeAlertBanner`, `CountdownTimer`) + biblioteca de desenhos 2D (`survival_2d_art.dart`).
- `lib/screens/`: Telas de interface desacopladas da camada de dados.

### 4.2. Gerenciamento de Estado (Riverpod)
Utilizamos `flutter_riverpod` com `StateNotifierProvider<GameController, GameState>`. Sempre que uma expedição termina, uma troca é aceita, um abrigo é criado ou um evento chega via **Supabase Realtime** (`horde_alerts` e `trades`), o `GameController` sincroniza o estado e notifica todas as telas automaticamente sem precisar reiniciar o app.

### 4.3. Funcionamento do `redirect` do GoRouter (3 Estados)
O `GoRouter` observa o estado de autenticação por meio do `RouterRefreshListenable` e aplica o `redirect` em três estágios (`PlayerAuthState`):
1. **Não autenticado (`unauthenticated`)**: Redireciona qualquer rota interna protegida para `/login`.
2. **Autenticado sem facção (`authenticatedNoFaction`)**: Obriga o jogador recém-cadastrado a passar por `/escolher-faccao` antes de acessar qualquer tela interna.
3. **Cadastro completo (`complete`)**: Redireciona `/splash`, `/login` e `/escolher-faccao` diretamente para `/home` e libera as rotas internas (`/mapa`, `/abrigos/:id`, `/expedicoes`, `/inventario`, `/trocas`, `/trocas/:id`, `/ranking`, `/perfil`).

### 4.4. Segurança RLS, Funções RPC e Atomicidade nas Trocas
- **Proteção de Inventário e Reputação**: A tabela `inventory` possui policy apenas para `SELECT` (`auth.uid() = user_id`), bloqueando `INSERT`, `UPDATE` e `DELETE` diretos pelo aplicativo cliente. Na tabela `profiles`, a policy de `UPDATE` possui cláusula `WITH CHECK` que exige que `reputation` e `faction_id` permaneçam inalterados.
- **Proteção de Abrigos da Facção**: A policy de `SELECT` em `shelters` verifica `visibility = 'public' OR faction_id = (SELECT faction_id FROM public.profiles WHERE id = auth.uid())`, impedindo que jogadores de outras facções leiam abrigos restritos.
- **Troca 100% Atômica (`respond_trade`)**: Executada dentro de uma função PL/pgSQL (`SECURITY DEFINER`), que roda em uma única transação do PostgreSQL com `FOR UPDATE` (bloqueio pessimista das linhas de inventário). Se qualquer item faltar para o remetente ou destinatário, `RAISE EXCEPTION` aborta a transação inteira e faz *rollback* automático de todas as alterações.
