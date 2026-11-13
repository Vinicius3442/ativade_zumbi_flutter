# Protocolo Z — Sobreviver é um trabalho em equipe!

Aplicativo mobile multi-jogador em tempo real desenvolvido em **Flutter** e **Supabase** para a atividade **Protocolo Z: Atividade de Fixação e Aprofundamento (Flutter)**.

---

## 1. Identidade Visual, Paleta e Desenhos 2D

- **Paleta Temática (Verde, Cinza e Vermelho)**:
  - **Verde Radar / Bio-Tático** (`#00E676`, `#2E7D32`, `#43A047`): Zonas seguras, radar tático, suprimentos e confirmações.
  - **Cinza Bunker / Aço** (`#0E1311`, `#151C19`, `#26312C`, `#78909C`): Estrutura blindada, HUD tático e ruínas urbanas.
  - **Vermelho Alerta de Horda** (`#FF1744`, `#D32F2F`, `#2D1215`): Alertas de horda em tempo real, risco elevado e bloqueios anti-cheat.
- **Desenhos e Animações 2D (`lib/widgets/survival_2d_art.dart`)**:
  - `ProtocoloZLogo2D`: Emblema vetorial 2D animado com escudo hexagonal cinza, feixe de varredura de radar verde e insígnia Z pulsante em verde e vermelho.
  - `ExpeditionScene2D`: Cena 2D animada com ruínas urbanas, sobrevivente caminhando com lanterna tática, partículas de cinzas e silhuetas de zumbis.
  - `TacticalRadar2D`: Radar 2D em tempo real no painel principal indicando abrigos próximos (blips verdes) e alertas de horda ativos (blips vermelhos).

---

## 2. Tabela de Reputação Adotada (Garantida pelo Servidor)

A reputação é a pontuação oficial do jogo e **só pode ser concedida pelo servidor** (qualquer tentativa de `UPDATE` direto em `profiles.reputation` pelo aplicativo cliente é bloqueada pela policy RLS `WITH CHECK`):

| Ação no Jogo | Reputação Concedida | Regra no Servidor (Supabase / PostgreSQL) |
| :--- | :---: | :--- |
| **Concluir uma expedição** | **+10** | Função RPC `public.claim_expedition(p_expedition_id)` |
| **Cadastrar um abrigo** | **+15** | Trigger `BEFORE INSERT` `public.handle_new_shelter()` |
| **Concluir uma troca (cada jogador)** | **+20** | Função RPC `public.respond_trade(p_trade_id, 'accept')` |
| **Ter um alerta confirmado por dois jogadores** | **+25** | Função RPC `public.confirm_horde_alert(p_alert_id)` |

---

## 3. Instruções para Criar o Banco, Configurar as Chaves e Executar

### 3.1. Criando o Banco de Dados do Zero no Supabase
1. Acesse o painel do projeto no [Supabase Dashboard](https://supabase.com/dashboard).
2. No menu lateral, clique em **SQL Editor** > **New Query**.
3. Copie todo o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) (também salvo em [`Banco/supabase.sql`](Banco/supabase.sql)) e clique em **Run**.
   - O script cria automaticamente todas as tabelas (`factions`, `profiles`, `items`, `inventory`, `shelters`, `expedition_types`, `expedition_loot_table`, `expeditions`, `trades`, `trade_items`, `horde_alerts`, `alert_confirmations`), as views (`survivors_ranking`, `factions_ranking`), as triggers, as **6 funções RPC**, todas as policies de **RLS**, as publicações **Realtime**, os buckets do **Storage** (`avatars` e `shelters`) e os dados iniciais (**seed**).

### 3.2. Configuração das Chaves
As chaves públicas já estão configuradas em [`lib/core/config/supabase_config.dart`](lib/core/config/supabase_config.dart):
- **URL do Projeto**: `https://lhbjpxdebwgninedzker.supabase.co`
- **Publishable Key**: `sb_publishable_LekZzQ8VfBygE58dm1wCSw_GOkbNz1W`
- **Anon Key**: configurada em `SupabaseConfig.anonKey`
- **Segurança**: A chave `service_role` **nunca** aparece no código-fonte nem no repositório.

### 3.3. Executando o Projeto Flutter
```bash
flutter pub get
flutter run
```

---

## 4. Arquitetura, Estado, Rotas e Segurança (Explicação para Apresentação)

### 4.1. Organização em Camadas (`lib/`)
- `lib/models/`: Classes de dados com conversão `fromJson` e `toJson` (`FactionModel`, `ProfileModel`, `ItemModel`, `InventoryEntryModel`, `ShelterModel`, `ExpeditionModel`, `TradeModel`, `HordeAlertModel`, `SurvivorRankModel`, `FactionRankModel`).
- `lib/repositories/` e `lib/services/`: Todo o acesso ao Supabase (`ProtocoloZRepository`) e cache local (`LocalCacheService`). **As telas não chamam o Supabase diretamente.**
- `lib/providers/`: Gerenciamento de estado com **Riverpod** (`GameController` / `StateNotifier<GameState>`).
- `lib/router/`: Gerenciamento de rotas com **GoRouter** (`app_router.dart`).
- `lib/widgets/`: **6 widgets personalizados reutilizados** (`FactionBadge`, `ItemTile`, `ShelterCard`, `TradeCard`, `HordeAlertBanner`, `CountdownTimer`) + artes 2D (`survival_2d_art.dart`).
- `lib/screens/`: Apenas interface do usuário (`SplashScreen`, `AuthScreen`, `FactionSelectionScreen`, `HomeScreen`, `MapSheltersScreen`, `ShelterDetailScreen`, `ExpeditionsScreen`, `InventoryScreen`, `TradesScreen`, `TradeDetailScreen`, `RankingScreen`, `ProfileScreen`).

### 4.2. Gerenciamento de Estado (Riverpod)
Utilizamos **Riverpod** (`StateNotifierProvider<GameController, GameState>`) por garantir estado previsível, reativo e desacoplado da árvore de widgets. Após qualquer expedição, troca, cadastro de abrigo ou alerta via **Supabase Realtime**, todas as telas afetadas refletem a mudança imediatamente sem reiniciar o aplicativo.

### 4.3. Funcionamento do `redirect` do GoRouter com 3 Estados
O `GoRouter` protege todas as rotas internas avaliando `PlayerAuthState`:
1. **Não autenticado (`unauthenticated`)**: Qualquer tentativa de acesso a rotas internas redireciona para `/login`.
2. **Autenticado sem facção (`authenticatedNoFaction`)**: Obriga o jogador recém-cadastrado a escolher sua facção em `/escolher-faccao` antes de liberar qualquer tela interna.
3. **Cadastro completo (`complete`)**: Redireciona `/splash`, `/login` e `/escolher-faccao` diretamente para `/home` e mantém a barra de navegação inferior persistente com `ShellRoute`, incluindo rotas com parâmetros `/abrigos/:id` e `/trocas/:id`.

### 4.4. Policies de RLS, Funções RPC e Troca Atômica
- **Proteção do Inventário (`inventory`)**: RLS habilitada apenas com policy de `SELECT` (`auth.uid() = user_id`). Não há policy de `INSERT`, `UPDATE` ou `DELETE` para clientes; alterações ocorrem somente via `_modify_inventory` dentro das funções RPC (`choose_faction`, `claim_expedition`, `respond_trade`), além de restrição `CHECK (quantity > 0)`.
- **Proteção da Reputação e Facção (`profiles`)**: A policy de `UPDATE` exige no `WITH CHECK` que `reputation` e `faction_id` sejam idênticos aos valores atuais no banco, bloqueando adulteração direta pelo cliente.
- **Proteção dos Abrigos (`shelters`)**: A policy de `SELECT` valida `visibility = 'public' OR faction_id = (SELECT faction_id FROM public.profiles WHERE id = auth.uid())`, ocultando abrigos restritos para outras facções direto no servidor.
- **Atomicidade na Aceitação de Troca (`respond_trade`)**: Executada dentro de uma função PL/pgSQL com bloqueio de linhas (`SELECT ... FOR UPDATE`). Todos os itens oferecidos e solicitados são transferidos dentro da mesma transação; se qualquer jogador não tiver mais a quantidade necessária, `RAISE EXCEPTION` desfaz toda a operação automaticamente (*rollback* atômico).

---

## 5. Roteiro Prático do Desafio Final (Seção 5)
1. **Cadastro e Facção (Jogador A)**: Cadastre-se na tela de acesso, escolha uma facção em `/escolher-faccao` e receba o kit inicial automático.
2. **Abrigo da Facção (Jogador A)**: Na aba **Mapa**, toque no mapa ou use o GPS, clique em **Novo Abrigo (+15 REP)**, marque **Só Facção**, anexe uma foto e salve.
3. **Expedição (Jogador A)**: Na aba **Missões**, inicie uma expedição (ex.: *Mercado Abandonado* — 60s), feche e reabra o app para ver a contagem regressiva persistida pelo servidor e colete as recompensas sorteadas.
4. **Visibilidade RLS (Jogador B)**: Entre com outra conta e outra facção em outro dispositivo/emulador e verifique no **Mapa** que o abrigo exclusivo da facção do Jogador A não aparece.
5. **Alerta de Horda em Tempo Real (Jogador B)**: Clique no ícone vermelho de alerta (na Central ou no Mapa) e transmita um alerta — ele aparece instantaneamente no topo da tela do Jogador A via Supabase Realtime.
6. **Troca Atômica em Tempo Real (Jogador A -> B)**: Na aba **Trocas**, clique em **Propor Troca**, escolha o Jogador B, selecione itens oferecidos e pedidos e envie. O Jogador B vê a proposta em tempo real, aceita, e ambos os inventários e reputações (+20) são atualizados.
7. **Teste de Trapaça (Anti-Cheat RLS)**: Na aba **Perfil**, role até o painel **Laboratório Anti-Cheat (Desafio Final Item 7)** e clique nos botões **Forçar Insert Inventory** e **Forçar 99999 Reputação** para exibir ao vivo o erro `42501` de recusa do PostgreSQL/RLS.
8. **Rankings e Perfil**: Confira as posições atualizadas na aba **Ranking** (Sobreviventes e Facções) e os contadores na aba **Perfil**.
9. **Persistência de Sessão**: Clique em **Encerrar Sessão (Logout)** e faça login novamente para comprovar que todos os dados foram mantidos no Supabase.
