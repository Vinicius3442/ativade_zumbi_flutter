-- ============================================================================
-- PROTOCOLO Z - SCRIPT COMPLETO DO BANCO DE DADOS (SUPABASE / POSTGRESQL)
-- Tabelas, Triggers, Views, Funções RPC Atômicas, RLS, Realtime, Storage e Seed
-- ============================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Facções
CREATE TABLE IF NOT EXISTS public.factions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    symbol TEXT NOT NULL,
    color_hex TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Perfis dos Jogadores (vinculado ao auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nickname TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    faction_id UUID REFERENCES public.factions(id) ON DELETE RESTRICT,
    reputation INTEGER NOT NULL DEFAULT 0 CHECK (reputation >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Catálogo de Itens
CREATE TABLE IF NOT EXISTS public.items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('agua', 'comida', 'medicamentos', 'ferramentas', 'combustivel')),
    icon_name TEXT NOT NULL,
    is_starter_item BOOLEAN NOT NULL DEFAULT false,
    starter_quantity INTEGER NOT NULL DEFAULT 0 CHECK (starter_quantity >= 0)
);

-- 4. Inventário dos Jogadores
CREATE TABLE IF NOT EXISTS public.inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0), -- Nunca permite 0 ou negativo
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, item_id)
);

-- 5. Abrigos
CREATE TABLE IF NOT EXISTS public.shelters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    faction_id UUID NOT NULL REFERENCES public.factions(id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    photo_url TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    visibility TEXT NOT NULL CHECK (visibility IN ('public', 'faction')),
    status TEXT NOT NULL DEFAULT 'seguro' CHECK (status IN ('seguro', 'comprometido')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Tipos de Expedição
CREATE TABLE IF NOT EXISTS public.expedition_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
    risk_level TEXT NOT NULL CHECK (risk_level IN ('baixo', 'medio', 'alto')),
    min_reward_types INTEGER NOT NULL DEFAULT 1 CHECK (min_reward_types >= 1),
    max_reward_types INTEGER NOT NULL DEFAULT 3 CHECK (max_reward_types >= min_reward_types)
);

-- 7. Tabela de Loot (Possíveis recompensas por tipo de expedição)
CREATE TABLE IF NOT EXISTS public.expedition_loot_table (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    expedition_type_id UUID NOT NULL REFERENCES public.expedition_types(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.items(id) ON DELETE CASCADE,
    min_quantity INTEGER NOT NULL CHECK (min_quantity >= 1),
    max_quantity INTEGER NOT NULL CHECK (max_quantity >= min_quantity),
    drop_weight INTEGER NOT NULL DEFAULT 10 CHECK (drop_weight > 0),
    UNIQUE (expedition_type_id, item_id)
);

-- 8. Expedições dos Jogadores
CREATE TABLE IF NOT EXISTS public.expeditions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    expedition_type_id UUID NOT NULL REFERENCES public.expedition_types(id) ON DELETE RESTRICT,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed')),
    rewards_json JSONB, -- Armazena o histórico do que foi sorteado
    completed_at TIMESTAMPTZ
);

-- Garante no banco que o jogador só tenha UMA expedição em andamento por vez
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_expedition_per_user 
ON public.expeditions (user_id) 
WHERE (status = 'in_progress');

-- 9. Propostas de Troca
CREATE TABLE IF NOT EXISTS public.trades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled', 'expired')),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '24 hours'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    CONSTRAINT chk_no_self_trade CHECK (sender_id <> receiver_id)
);

-- 10. Itens das Propostas de Troca
CREATE TABLE IF NOT EXISTS public.trade_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trade_id UUID NOT NULL REFERENCES public.trades(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES public.items(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    side TEXT NOT NULL CHECK (side IN ('offered', 'requested')), -- 'offered' = sender dá; 'requested' = receiver dá
    UNIQUE (trade_id, item_id, side)
);

-- 11. Alertas de Horda
CREATE TABLE IF NOT EXISTS public.horde_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    intensity TEXT NOT NULL CHECK (intensity IN ('baixa', 'media', 'alta')),
    description TEXT NOT NULL,
    confirmations_count INTEGER NOT NULL DEFAULT 0 CHECK (confirmations_count >= 0),
    reputation_awarded BOOLEAN NOT NULL DEFAULT false,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 minutes'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 12. Confirmações de Alertas de Horda
CREATE TABLE IF NOT EXISTS public.alert_confirmations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID NOT NULL REFERENCES public.horde_alerts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (alert_id, user_id) -- Impede confirmação duplicada
);

-- ============================================================================
-- TRIGGERS E VIEWS
-- ============================================================================

-- 1. Trigger para criar perfil automaticamente ao registrar no Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_nickname TEXT;
BEGIN
    -- Pega o nickname enviado no signUp (raw_user_meta_data) ou gera fallback
    v_nickname := COALESCE(
        NULLIF(TRIM(NEW.raw_user_meta_data->>'nickname'), ''),
        'Sobrevivente_' || substr(NEW.id::text, 1, 6)
    );

    INSERT INTO public.profiles (id, nickname)
    VALUES (NEW.id, v_nickname)
    ON CONFLICT (id) DO NOTHING;

    -- Auto-confirma o e-mail para facilitar testes práticos sem bloqueio de SMTP
    UPDATE auth.users
    SET email_confirmed_at = COALESCE(email_confirmed_at, now())
    WHERE id = NEW.id AND email_confirmed_at IS NULL;

    RETURN NEW;
EXCEPTION WHEN unique_violation THEN
    INSERT INTO public.profiles (id, nickname)
    VALUES (NEW.id, v_nickname || '_' || substr(NEW.id::text, 1, 4))
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Trigger ao cadastrar abrigo preenche faction_id do autor e concede +15 de reputação
CREATE OR REPLACE FUNCTION public.handle_new_shelter()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_faction_id UUID;
BEGIN
    SELECT faction_id INTO v_faction_id FROM public.profiles WHERE id = NEW.author_id;
    
    IF v_faction_id IS NULL THEN
        RAISE EXCEPTION 'Jogador precisa pertencer a uma facção para cadastrar abrigos.';
    END IF;

    NEW.faction_id := v_faction_id;

    -- Concede +15 de reputação ao autor
    UPDATE public.profiles
    SET reputation = reputation + 15, updated_at = now()
    WHERE id = NEW.author_id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_shelter_created ON public.shelters;
CREATE TRIGGER on_shelter_created
    BEFORE INSERT ON public.shelters
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_shelter();

-- 3. Views para Ranking (Calculadas direto no banco)
CREATE OR REPLACE VIEW public.survivors_ranking WITH (security_invoker = true) AS
SELECT 
    p.id,
    p.nickname,
    p.avatar_url,
    p.reputation,
    f.id AS faction_id,
    f.name AS faction_name,
    f.symbol AS faction_symbol,
    f.color_hex AS faction_color,
    RANK() OVER (ORDER BY p.reputation DESC, p.created_at ASC) AS rank_position
FROM public.profiles p
LEFT JOIN public.factions f ON p.faction_id = f.id
WHERE p.faction_id IS NOT NULL;

CREATE OR REPLACE VIEW public.factions_ranking WITH (security_invoker = true) AS
SELECT 
    f.id,
    f.name,
    f.symbol,
    f.color_hex,
    COUNT(p.id) AS members_count,
    COALESCE(SUM(p.reputation), 0) AS total_reputation,
    RANK() OVER (ORDER BY COALESCE(SUM(p.reputation), 0) DESC) AS rank_position
FROM public.factions f
LEFT JOIN public.profiles p ON p.faction_id = f.id
GROUP BY f.id, f.name, f.symbol, f.color_hex;

-- ============================================================================
-- FUNÇÕES RPC (PL/pgSQL) - REGRAS DE SERVIDOR E ANTI-CHEAT
-- ============================================================================

-- Função auxiliar interna para adicionar/remover itens com segurança
CREATE OR REPLACE FUNCTION public._modify_inventory(
    p_user_id UUID,
    p_item_id UUID,
    p_delta INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_current_qty INTEGER;
    v_new_qty INTEGER;
BEGIN
    SELECT quantity INTO v_current_qty
    FROM public.inventory
    WHERE user_id = p_user_id AND item_id = p_item_id
    FOR UPDATE;

    v_current_qty := COALESCE(v_current_qty, 0);
    v_new_qty := v_current_qty + p_delta;

    IF v_new_qty < 0 THEN
        RAISE EXCEPTION 'Quantidade insuficiente do item no inventário.';
    ELSIF v_new_qty = 0 THEN
        DELETE FROM public.inventory WHERE user_id = p_user_id AND item_id = p_item_id;
    ELSE
        INSERT INTO public.inventory (user_id, item_id, quantity, updated_at)
        VALUES (p_user_id, p_item_id, v_new_qty, now())
        ON CONFLICT (user_id, item_id)
        DO UPDATE SET quantity = v_new_qty, updated_at = now();
    END IF;
END;
$$;

-- RPC 1: Escolher Facção (Definitiva) + Receber Kit Inicial
CREATE OR REPLACE FUNCTION public.choose_faction(p_faction_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_faction UUID;
    v_starter RECORD;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    SELECT faction_id INTO v_current_faction FROM public.profiles WHERE id = v_user_id FOR UPDATE;

    IF v_current_faction IS NOT NULL THEN
        RAISE EXCEPTION 'Facção já escolhida e não pode ser alterada.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.factions WHERE id = p_faction_id) THEN
        RAISE EXCEPTION 'Facção inválida.';
    END IF;

    UPDATE public.profiles
    SET faction_id = p_faction_id, updated_at = now()
    WHERE id = v_user_id;

    -- Entrega o kit inicial configurado na tabela items
    FOR v_starter IN 
        SELECT id, starter_quantity FROM public.items WHERE is_starter_item = true AND starter_quantity > 0
    LOOP
        PERFORM public._modify_inventory(v_user_id, v_starter.id, v_starter.starter_quantity);
    END LOOP;
END;
$$;

-- RPC 2: Iniciar Expedição (Tempo controlado 100% pelo servidor)
CREATE OR REPLACE FUNCTION public.start_expedition(p_expedition_type_id UUID)
RETURNS public.expeditions
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_duration INTEGER;
    v_expedition public.expeditions;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    IF EXISTS (SELECT 1 FROM public.expeditions WHERE user_id = v_user_id AND status = 'in_progress') THEN
        RAISE EXCEPTION 'Você já possui uma expedição em andamento.';
    END IF;

    SELECT duration_seconds INTO v_duration
    FROM public.expedition_types
    WHERE id = p_expedition_type_id;

    IF v_duration IS NULL THEN
        RAISE EXCEPTION 'Tipo de expedição inválido.';
    END IF;

    INSERT INTO public.expeditions (user_id, expedition_type_id, started_at, ends_at, status)
    VALUES (v_user_id, p_expedition_type_id, now(), now() + (v_duration || ' seconds')::INTERVAL, 'in_progress')
    RETURNING * INTO v_expedition;

    RETURN v_expedition;
END;
$$;

-- RPC 3: Coletar Recompensas da Expedição (Sorteio no servidor +10 reputação)
CREATE OR REPLACE FUNCTION public.claim_expedition(p_expedition_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_exp public.expeditions;
    v_exp_type public.expedition_types;
    v_num_items INTEGER;
    v_loot RECORD;
    v_qty INTEGER;
    v_rewards JSONB := '[]'::JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    SELECT * INTO v_exp
    FROM public.expeditions
    WHERE id = p_expedition_id AND user_id = v_user_id
    FOR UPDATE;

    IF v_exp IS NULL THEN
        RAISE EXCEPTION 'Expedição não encontrada.';
    END IF;

    IF v_exp.status <> 'in_progress' THEN
        RAISE EXCEPTION 'Esta expedição já foi concluída.';
    END IF;

    IF (now() + INTERVAL '3 seconds') < v_exp.ends_at THEN
        RAISE EXCEPTION 'A expedição ainda não terminou. Aguarde o tempo restante.';
    END IF;

    SELECT * INTO v_exp_type FROM public.expedition_types WHERE id = v_exp.expedition_type_id;

    -- Sorteia quantos tipos de itens serão obtidos
    v_num_items := floor(random() * (v_exp_type.max_reward_types - v_exp_type.min_reward_types + 1) + v_exp_type.min_reward_types)::INTEGER;

    -- Sorteia os itens ponderados pelo drop_weight
    FOR v_loot IN
        SELECT lt.item_id, lt.min_quantity, lt.max_quantity, i.name, i.icon_name
        FROM public.expedition_loot_table lt
        JOIN public.items i ON i.id = lt.item_id
        WHERE lt.expedition_type_id = v_exp.expedition_type_id
        ORDER BY -ln(random()) / lt.drop_weight
        LIMIT v_num_items
    LOOP
        v_qty := floor(random() * (v_loot.max_quantity - v_loot.min_quantity + 1) + v_loot.min_quantity)::INTEGER;
        
        PERFORM public._modify_inventory(v_user_id, v_loot.item_id, v_qty);

        v_rewards := v_rewards || jsonb_build_object(
            'item_id', v_loot.item_id,
            'name', v_loot.name,
            'icon_name', v_loot.icon_name,
            'quantity', v_qty
        );
    END LOOP;

    -- Atualiza expedição e adiciona +10 de reputação
    UPDATE public.expeditions
    SET status = 'completed', completed_at = now(), rewards_json = v_rewards
    WHERE id = p_expedition_id;

    UPDATE public.profiles
    SET reputation = reputation + 10, updated_at = now()
    WHERE id = v_user_id;

    RETURN v_rewards;
END;
$$;

-- RPC 4: Criar Proposta de Troca (Valida posse inicial e insere proposta + itens)
CREATE OR REPLACE FUNCTION public.create_trade(
    p_receiver_id UUID,
    p_offered_items JSONB,   -- Ex: [{"item_id": "uuid", "quantity": 2}]
    p_requested_items JSONB  -- Ex: [{"item_id": "uuid", "quantity": 1}]
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_sender_id UUID := auth.uid();
    v_trade_id UUID;
    v_item JSONB;
    v_item_id UUID;
    v_qty INTEGER;
    v_owned INTEGER;
BEGIN
    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    IF v_sender_id = p_receiver_id THEN
        RAISE EXCEPTION 'Você não pode propor uma troca para si mesmo.';
    END IF;

    IF jsonb_array_length(p_offered_items) = 0 OR jsonb_array_length(p_requested_items) = 0 THEN
        RAISE EXCEPTION 'A troca deve conter ao menos um item oferecido e um item pedido.';
    END IF;

    INSERT INTO public.trades (sender_id, receiver_id)
    VALUES (v_sender_id, p_receiver_id)
    RETURNING id INTO v_trade_id;

    -- Processa itens oferecidos pelo remetente
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_offered_items)
    LOOP
        v_item_id := (v_item->>'item_id')::UUID;
        v_qty := (v_item->>'quantity')::INTEGER;

        IF v_qty <= 0 THEN RAISE EXCEPTION 'Quantidade inválida.'; END IF;

        SELECT quantity INTO v_owned FROM public.inventory WHERE user_id = v_sender_id AND item_id = v_item_id;
        IF COALESCE(v_owned, 0) < v_qty THEN
            RAISE EXCEPTION 'Você não possui quantidade suficiente de um dos itens oferecidos.';
        END IF;

        INSERT INTO public.trade_items (trade_id, item_id, quantity, side)
        VALUES (v_trade_id, v_item_id, v_qty, 'offered');
    END LOOP;

    -- Processa itens pedidos ao destinatário
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_requested_items)
    LOOP
        v_item_id := (v_item->>'item_id')::UUID;
        v_qty := (v_item->>'quantity')::INTEGER;

        IF v_qty <= 0 THEN RAISE EXCEPTION 'Quantidade inválida.'; END IF;

        INSERT INTO public.trade_items (trade_id, item_id, quantity, side)
        VALUES (v_trade_id, v_item_id, v_qty, 'requested');
    END LOOP;

    RETURN v_trade_id;
END;
$$;

-- RPC 5: Responder Proposta de Troca (Aceitar é 100% atômico +20 reputação p/ ambos)
CREATE OR REPLACE FUNCTION public.respond_trade(
    p_trade_id UUID,
    p_action TEXT -- 'accept', 'reject', 'cancel'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_trade public.trades;
    v_ti RECORD;
    v_qty_check INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    SELECT * INTO v_trade FROM public.trades WHERE id = p_trade_id FOR UPDATE;

    IF v_trade IS NULL THEN
        RAISE EXCEPTION 'Proposta de troca não encontrada.';
    END IF;

    IF v_trade.status <> 'pending' THEN
        RAISE EXCEPTION 'Esta troca não está mais pendente.';
    END IF;

    -- Verifica expiração de 24h
    IF now() > v_trade.expires_at THEN
        UPDATE public.trades SET status = 'expired', resolved_at = now() WHERE id = p_trade_id;
        RAISE EXCEPTION 'Esta proposta de troca expirou.';
    END IF;

    IF p_action = 'cancel' THEN
        IF v_user_id <> v_trade.sender_id THEN
            RAISE EXCEPTION 'Apenas o autor pode cancelar a proposta.';
        END IF;
        UPDATE public.trades SET status = 'cancelled', resolved_at = now() WHERE id = p_trade_id;
        RETURN;
    END IF;

    IF p_action = 'reject' THEN
        IF v_user_id <> v_trade.receiver_id THEN
            RAISE EXCEPTION 'Apenas o destinatário pode recusar a proposta.';
        END IF;
        UPDATE public.trades SET status = 'rejected', resolved_at = now() WHERE id = p_trade_id;
        RETURN;
    END IF;

    IF p_action = 'accept' THEN
        IF v_user_id <> v_trade.receiver_id THEN
            RAISE EXCEPTION 'Apenas o destinatário pode aceitar a proposta.';
        END IF;

        -- Transferência Atômica (se qualquer item faltar, RAISE EXCEPTION faz rollback automático de tudo)
        FOR v_ti IN SELECT * FROM public.trade_items WHERE trade_id = p_trade_id
        LOOP
            IF v_ti.side = 'offered' THEN
                -- Sender entrega ao Receiver
                SELECT quantity INTO v_qty_check FROM public.inventory WHERE user_id = v_trade.sender_id AND item_id = v_ti.item_id FOR UPDATE;
                IF COALESCE(v_qty_check, 0) < v_ti.quantity THEN
                    RAISE EXCEPTION 'O remetente não possui mais os itens oferecidos.';
                END IF;
                PERFORM public._modify_inventory(v_trade.sender_id, v_ti.item_id, -v_ti.quantity);
                PERFORM public._modify_inventory(v_trade.receiver_id, v_ti.item_id, v_ti.quantity);
            ELSE
                -- Receiver entrega ao Sender
                SELECT quantity INTO v_qty_check FROM public.inventory WHERE user_id = v_trade.receiver_id AND item_id = v_ti.item_id FOR UPDATE;
                IF COALESCE(v_qty_check, 0) < v_ti.quantity THEN
                    RAISE EXCEPTION 'Você não possui mais os itens solicitados.';
                END IF;
                PERFORM public._modify_inventory(v_trade.receiver_id, v_ti.item_id, -v_ti.quantity);
                PERFORM public._modify_inventory(v_trade.sender_id, v_ti.item_id, v_ti.quantity);
            END IF;
        END LOOP;

        -- Marca troca como aceita e concede +20 de reputação para CADA jogador
        UPDATE public.trades SET status = 'accepted', resolved_at = now() WHERE id = p_trade_id;

        UPDATE public.profiles
        SET reputation = reputation + 20, updated_at = now()
        WHERE id IN (v_trade.sender_id, v_trade.receiver_id);

        RETURN;
    END IF;

    RAISE EXCEPTION 'Ação inválida.';
END;
$$;

-- RPC 6: Confirmar Alerta de Horda (Concede +25 reputação ao autor na 2ª confirmação)
CREATE OR REPLACE FUNCTION public.confirm_horde_alert(p_alert_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_alert public.horde_alerts;
    v_new_count INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado.';
    END IF;

    SELECT * INTO v_alert FROM public.horde_alerts WHERE id = p_alert_id FOR UPDATE;

    IF v_alert IS NULL THEN
        RAISE EXCEPTION 'Alerta não encontrado.';
    END IF;

    IF now() > v_alert.expires_at THEN
        RAISE EXCEPTION 'Este alerta de horda já expirou.';
    END IF;

    IF v_alert.author_id = v_user_id THEN
        RAISE EXCEPTION 'Você não pode confirmar seu próprio alerta.';
    END IF;

    -- Insere confirmação (Unique constraint impede duplicidade)
    INSERT INTO public.alert_confirmations (alert_id, user_id)
    VALUES (p_alert_id, v_user_id);

    v_new_count := v_alert.confirmations_count + 1;

    -- Se atingiu 2 confirmações e ainda não premiou, dá +25 de reputação ao autor
    IF v_new_count >= 2 AND v_alert.reputation_awarded = false THEN
        UPDATE public.horde_alerts
        SET confirmations_count = v_new_count, reputation_awarded = true
        WHERE id = p_alert_id;

        UPDATE public.profiles
        SET reputation = reputation + 25, updated_at = now()
        WHERE id = v_alert.author_id;
    ELSE
        UPDATE public.horde_alerts
        SET confirmations_count = v_new_count
        WHERE id = p_alert_id;
    END IF;
END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) EM TODAS AS TABELAS
-- ============================================================================

ALTER TABLE public.factions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shelters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expedition_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expedition_loot_table ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expeditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trade_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.horde_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_confirmations ENABLE ROW LEVEL SECURITY;

-- 1. FACTIONS (Leitura pública para autenticados e anon)
DROP POLICY IF EXISTS "Factions visíveis para autenticados" ON public.factions;
CREATE POLICY "Factions visíveis para autenticados" ON public.factions
    FOR SELECT TO anon, authenticated USING (true);

-- 2. PROFILES (Leitura para autenticados; update APENAS do avatar_url e nickname, bloqueando faction_id e reputation)
DROP POLICY IF EXISTS "Perfis visíveis para autenticados" ON public.profiles;
CREATE POLICY "Perfis visíveis para autenticados" ON public.profiles
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Usuário atualiza apenas dados cosméticos do próprio perfil" ON public.profiles;
CREATE POLICY "Usuário atualiza apenas dados cosméticos do próprio perfil" ON public.profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id
        AND reputation = (SELECT reputation FROM public.profiles WHERE id = auth.uid())
        AND faction_id IS NOT DISTINCT FROM (SELECT faction_id FROM public.profiles WHERE id = auth.uid())
    );
-- Nota: Nenhum INSERT ou DELETE permitido para o cliente em profiles (feito via trigger).

-- 3. ITEMS (Leitura pública para autenticados)
DROP POLICY IF EXISTS "Catálogo de itens visível para autenticados" ON public.items;
CREATE POLICY "Catálogo de itens visível para autenticados" ON public.items
    FOR SELECT TO anon, authenticated USING (true);

-- 4. INVENTORY (Usuário lê apenas o próprio inventário; ZERO escrita direta permitida)
DROP POLICY IF EXISTS "Usuário vê apenas próprio inventário" ON public.inventory;
CREATE POLICY "Usuário vê apenas próprio inventário" ON public.inventory
    FOR SELECT TO authenticated USING (auth.uid() = user_id);
-- Nenhum INSERT, UPDATE ou DELETE permitido para o cliente em inventory!

-- 5. SHELTERS (Públicos para todos; 'faction' apenas para membros da mesma facção)
DROP POLICY IF EXISTS "Leitura de abrigos públicos ou da mesma facção" ON public.shelters;
CREATE POLICY "Leitura de abrigos públicos ou da mesma facção" ON public.shelters
    FOR SELECT TO authenticated
    USING (
        visibility = 'public'
        OR faction_id = (SELECT faction_id FROM public.profiles WHERE id = auth.uid())
    );

DROP POLICY IF EXISTS "Usuário autenticado cria abrigo em seu nome" ON public.shelters;
CREATE POLICY "Usuário autenticado cria abrigo em seu nome" ON public.shelters
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Apenas autor edita próprio abrigo" ON public.shelters;
CREATE POLICY "Apenas autor edita próprio abrigo" ON public.shelters
    FOR UPDATE TO authenticated
    USING (auth.uid() = author_id)
    WITH CHECK (auth.uid() = author_id);

DROP POLICY IF EXISTS "Apenas autor exclui próprio abrigo" ON public.shelters;
CREATE POLICY "Apenas autor exclui próprio abrigo" ON public.shelters
    FOR DELETE TO authenticated
    USING (auth.uid() = author_id);

-- 6. EXPEDITION_TYPES & LOOT_TABLE (Leitura para autenticados)
DROP POLICY IF EXISTS "Tipos de expedição visíveis" ON public.expedition_types;
CREATE POLICY "Tipos de expedição visíveis" ON public.expedition_types
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Tabela de loot visível" ON public.expedition_loot_table;
CREATE POLICY "Tabela de loot visível" ON public.expedition_loot_table
    FOR SELECT TO anon, authenticated USING (true);

-- 7. EXPEDITIONS (Leitura apenas das próprias; escrita apenas via RPC)
DROP POLICY IF EXISTS "Usuário vê próprias expedições" ON public.expeditions;
CREATE POLICY "Usuário vê próprias expedições" ON public.expeditions
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- 8. TRADES & TRADE_ITEMS (Apenas remetente e destinatário visualizam; escrita apenas via RPC)
DROP POLICY IF EXISTS "Participantes veem suas trocas" ON public.trades;
CREATE POLICY "Participantes veem suas trocas" ON public.trades
    FOR SELECT TO authenticated
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Participantes veem itens de suas trocas" ON public.trade_items;
CREATE POLICY "Participantes veem itens de suas trocas" ON public.trade_items
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.trades t
            WHERE t.id = trade_id AND (t.sender_id = auth.uid() OR t.receiver_id = auth.uid())
        )
    );

-- 9. HORDE_ALERTS (Todos autenticados leem alertas ativos; qualquer autenticado cria em seu nome)
DROP POLICY IF EXISTS "Alertas ativos visíveis para todos" ON public.horde_alerts;
CREATE POLICY "Alertas ativos visíveis para todos" ON public.horde_alerts
    FOR SELECT TO authenticated
    USING (expires_at > now());

DROP POLICY IF EXISTS "Usuário cria alerta em seu nome" ON public.horde_alerts;
CREATE POLICY "Usuário cria alerta em seu nome" ON public.horde_alerts
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = author_id);

-- 10. ALERT_CONFIRMATIONS (Leitura para autenticados; escrita apenas via RPC)
DROP POLICY IF EXISTS "Confirmações visíveis para autenticados" ON public.alert_confirmations;
CREATE POLICY "Confirmações visíveis para autenticados" ON public.alert_confirmations
    FOR SELECT TO authenticated USING (true);

-- ============================================================================
-- REALTIME E STORAGE
-- ============================================================================

-- Habilitar Realtime para Alertas de Horda e Trocas (ignora erro caso já adicionado)
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.horde_alerts;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.trades;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- Criar buckets públicos para leitura (com escrita restrita à pasta do usuário)
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('avatars', 'avatars', true),
    ('shelters', 'shelters', true)
ON CONFLICT (id) DO NOTHING;

-- Policies para AVATARS (caminho obrigatório: avatars/<user_id>/arquivo.ext)
DROP POLICY IF EXISTS "Avatares são públicos para visualização" ON storage.objects;
CREATE POLICY "Avatares são públicos para visualização"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Usuário envia avatar apenas para própria pasta" ON storage.objects;
CREATE POLICY "Usuário envia avatar apenas para própria pasta"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Usuário atualiza avatar apenas na própria pasta" ON storage.objects;
CREATE POLICY "Usuário atualiza avatar apenas na própria pasta"
ON storage.objects FOR UPDATE TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Usuário deleta avatar apenas na própria pasta" ON storage.objects;
CREATE POLICY "Usuário deleta avatar apenas na própria pasta"
ON storage.objects FOR DELETE TO authenticated
USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policies para SHELTERS (caminho obrigatório: shelters/<user_id>/arquivo.ext)
DROP POLICY IF EXISTS "Fotos de abrigos são públicas para visualização" ON storage.objects;
CREATE POLICY "Fotos de abrigos são públicas para visualização"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'shelters');

DROP POLICY IF EXISTS "Usuário envia foto de abrigo apenas na própria pasta" ON storage.objects;
CREATE POLICY "Usuário envia foto de abrigo apenas na própria pasta"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'shelters'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Usuário deleta foto de abrigo apenas na própria pasta" ON storage.objects;
CREATE POLICY "Usuário deleta foto de abrigo apenas na própria pasta"
ON storage.objects FOR DELETE TO authenticated
USING (
    bucket_id = 'shelters'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================================
-- SEED DATA (DADOS INICIAIS)
-- ============================================================================

-- 1. Facções (Mínimo 3 - Paleta Verde, Cinza e Vermelho)
INSERT INTO public.factions (id, name, description, symbol, color_hex) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Vanguarda Escarlate', 'Engenheiros e combatentes focados em fortificação de abrigos, contenção de hordas e defesa pesada.', 'shield', '#D32F2F'),
    ('22222222-2222-2222-2222-222222222222', 'Patrulha Bio-Verde', 'Batedores táticos especializados em exploração de zonas infectadas, rastreamento e coleta.', 'compass', '#388E3C'),
    ('33333333-3333-3333-3333-333333333333', 'Divisão Cinza de Aço', 'Especialistas técnicos e médicos dedicados à preservação biológica, logística e suporte estratégico.', 'medical_services', '#78909C')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    symbol = EXCLUDED.symbol,
    color_hex = EXCLUDED.color_hex;

-- 2. Catálogo de Itens e Kit Inicial
INSERT INTO public.items (id, name, description, category, icon_name, is_starter_item, starter_quantity) VALUES
    ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Água Purificada', 'Garrafa de 1L livre de contaminação biológica.', 'agua', 'water_drop', true, 3),
    ('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Ração Enlatada', 'Alimento militar não perecível rico em calorias.', 'comida', 'restaurant', true, 2),
    ('aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Bandagem Estéril', 'Estanca sangramentos leves rapidamente em campo.', 'medicamentos', 'healing', true, 2),
    ('aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Antibiótico Z-Blocker', 'Combate infecções severas e retarda contaminação.', 'medicamentos', 'medication', false, 0),
    ('aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Pé de Cabra Tático', 'Ferramenta essencial para arrombar portas e caixas.', 'ferramentas', 'build', true, 1),
    ('aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Sucata Blindada', 'Material metálico base para reforçar abrigos.', 'ferramentas', 'hardware', false, 0),
    ('aaaaaaa7-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Galão de Gasolina', 'Combustível refinado para geradores e veículos.', 'combustivel', 'local_gas_station', false, 0),
    ('aaaaaaa8-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Bateria de Lítio', 'Fonte de energia portátil para rádios e radares.', 'combustivel', 'battery_charging_full', false, 0)
ON CONFLICT (name) DO NOTHING;

-- 3. Tipos de Expedição (Tempos curtos de 1 a 3 minutos para apresentação)
INSERT INTO public.expedition_types (id, name, description, duration_seconds, risk_level, min_reward_types, max_reward_types) VALUES
    ('bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Mercado Abandonado', 'Corredores saqueados na zona cinza, mas ainda restam mantimentos básicos.', 60, 'baixo', 1, 2),
    ('bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Hospital de Quarentena', 'Área escura e perigosa sob alerta biológico, rica em suprimentos médicos.', 120, 'medio', 2, 3),
    ('bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Posto de Gasolina', 'Tanques subterrâneos e oficina mecânica expostos à horda vermelha.', 180, 'alto', 2, 4)
ON CONFLICT (name) DO NOTHING;

-- 4. Tabela de Loot das Expedições
INSERT INTO public.expedition_loot_table (expedition_type_id, item_id, min_quantity, max_quantity, drop_weight) VALUES
    -- Mercado Abandonado
    ('bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 3, 50), -- Água
    ('bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 3, 50), -- Ração
    ('bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 2, 20), -- Sucata
    -- Hospital de Quarentena
    ('bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, 4, 60), -- Bandagem
    ('bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 2, 35), -- Antibiótico
    ('bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 2, 25), -- Água
    -- Posto de Gasolina
    ('bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa7-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 3, 55), -- Gasolina
    ('bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa8-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 2, 35), -- Bateria
    ('bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 1, 1, 20), -- Pé de cabra
    ('bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaa6-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2, 5, 45)  -- Sucata
ON CONFLICT (expedition_type_id, item_id) DO NOTHING;

NOTIFY pgrst, 'reload schema';
