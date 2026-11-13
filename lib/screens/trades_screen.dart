import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/item_model.dart';
import '../models/trade_models.dart';
import '../providers/game_providers.dart';
import '../widgets/trade_card.dart';

class TradesScreen extends ConsumerStatefulWidget {
  const TradesScreen({super.key});

  @override
  ConsumerState<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends ConsumerState<TradesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _statusFilter = 'todos';

  static const List<({String key, String label})> _statuses = [
    (key: 'todos', label: 'Todas'),
    (key: 'pending', label: 'Pendentes'),
    (key: 'accepted', label: 'Aceitas'),
    (key: 'rejected', label: 'Recusadas'),
    (key: 'cancelled', label: 'Canceladas'),
    (key: 'expired', label: 'Expiradas'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndRespond(TradeModel trade, String action) async {
    if (action == 'accept') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ProtocoloZColors.cardGray,
          title: const Text('CONFIRMAR TROCA ATÔMICA?'),
          content: const Text(
            'Ao aceitar, o servidor executará a transferência atômica via RPC: '
            'todos os itens serão trocados de uma só vez e ambos os jogadores receberão +20 de reputação.\n\n'
            'Se qualquer jogador não possuir mais os itens, nada será alterado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('VOLTAR'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('CONFIRMAR E TRANSFERIR'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    try {
      await ref
          .read(gameControllerProvider.notifier)
          .respondTrade(tradeId: trade.id, action: action);
      if (!mounted) return;
      final msg = action == 'accept'
          ? 'Troca concluída com sucesso! Inventários atualizados e +20 reputação concedida.'
          : action == 'reject'
          ? 'Proposta recusada.'
          : 'Proposta cancelada.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ProtocoloZColors.crimsonRed,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openCreateTradeSheet() async {
    final gs = ref.read(gameControllerProvider);
    if (gs.inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você precisa possuir pelo menos 1 item no inventário para propor uma troca.',
          ),
        ),
      );
      return;
    }
    if (gs.otherSurvivors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhum outro sobrevivente encontrado no banco para negociar.',
          ),
        ),
      );
      return;
    }

    String selectedReceiverId = gs.otherSurvivors.first.id;
    final Map<String, int> offeredQuantities = {};
    final Map<String, int> requestedQuantities = {};
    final catalog = gs.catalogItems.isNotEmpty
        ? gs.catalogItems
        : ItemModel.defaultCatalog;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProtocoloZColors.bgBunker,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NOVA PROPOSTA DE TROCA ATÔMICA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: ProtocoloZColors.radarGreen,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedReceiverId,
                  decoration: const InputDecoration(
                    labelText: 'Escolher Sobrevivente Destinatário',
                    prefixIcon: Icon(
                      Icons.person_search_rounded,
                      color: ProtocoloZColors.radarGreen,
                    ),
                  ),
                  items: [
                    for (final p in gs.otherSurvivors)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.nickname} (${p.faction?.name ?? 'Sem facção'})',
                        ),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedReceiverId = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        '1. ITENS QUE VOCÊ OFERECE (DO SEU INVENTÁRIO):',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.radarGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final inv in gs.inventory)
                        Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              '${inv.item.name} (Disponível: ${inv.quantity})',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    final cur =
                                        offeredQuantities[inv.itemId] ?? 0;
                                    if (cur > 0) {
                                      setModalState(() {
                                        if (cur == 1) {
                                          offeredQuantities.remove(inv.itemId);
                                        } else {
                                          offeredQuantities[inv.itemId] =
                                              cur - 1;
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${offeredQuantities[inv.itemId] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: ProtocoloZColors.radarGreen,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    final cur =
                                        offeredQuantities[inv.itemId] ?? 0;
                                    if (cur < inv.quantity) {
                                      setModalState(() {
                                        offeredQuantities[inv.itemId] = cur + 1;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        '2. ITENS QUE VOCÊ PEDE EM TROCA:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: ProtocoloZColors.hordeRed,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final item in catalog)
                        Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    final cur =
                                        requestedQuantities[item.id] ?? 0;
                                    if (cur > 0) {
                                      setModalState(() {
                                        if (cur == 1) {
                                          requestedQuantities.remove(item.id);
                                        } else {
                                          requestedQuantities[item.id] =
                                              cur - 1;
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${requestedQuantities[item.id] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: ProtocoloZColors.hordeRed,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    final cur =
                                        requestedQuantities[item.id] ?? 0;
                                    setModalState(() {
                                      requestedQuantities[item.id] = cur + 1;
                                    });
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (offeredQuantities.isEmpty ||
                          requestedQuantities.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selecione ao menos 1 item oferecido e 1 item pedido.',
                            ),
                          ),
                        );
                        return;
                      }
                      final offeredList = offeredQuantities.entries
                          .map((e) => {'item_id': e.key, 'quantity': e.value})
                          .toList();
                      final requestedList = requestedQuantities.entries
                          .map((e) => {'item_id': e.key, 'quantity': e.value})
                          .toList();

                      Navigator.pop(ctx);
                      try {
                        await ref
                            .read(gameControllerProvider.notifier)
                            .createTrade(
                              receiverId: selectedReceiverId,
                              offeredItems: offeredList,
                              requestedItems: requestedList,
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Proposta enviada em tempo real! Válida por 24h no servidor.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: ProtocoloZColors.crimsonRed,
                              content: Text(
                                e.toString().replaceAll('Exception: ', ''),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('ENVIAR PROPOSTA DE TROCA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameControllerProvider);
    final uid = gs.profile?.id ?? '';

    final received = gs.trades.where((t) {
      if (t.receiverId != uid) return false;
      if (_statusFilter == 'todos') return true;
      return t.effectiveStatus == _statusFilter;
    }).toList();

    final sent = gs.trades.where((t) {
      if (t.senderId != uid) return false;
      if (_statusFilter == 'todos') return true;
      return t.effectiveStatus == _statusFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TROCAS DE SUPRIMENTOS'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: ProtocoloZColors.radarGreen,
          labelColor: ProtocoloZColors.radarGreen,
          unselectedLabelColor: ProtocoloZColors.textMuted,
          tabs: [
            Tab(text: 'RECEBIDAS (${received.length})'),
            Tab(text: 'ENVIADAS (${sent.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final st = _statuses[i];
                final sel = _statusFilter == st.key;
                return ChoiceChip(
                  label: Text(st.label.toUpperCase()),
                  selected: sel,
                  selectedColor: ProtocoloZColors.tacticalGreen.withValues(
                    alpha: 0.3,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: sel
                        ? ProtocoloZColors.radarGreen
                        : ProtocoloZColors.textMuted,
                  ),
                  onSelected: (_) => setState(() => _statusFilter = st.key),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildTradesList(received, uid),
                _buildTradesList(sent, uid),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ProtocoloZColors.tacticalGreen,
        foregroundColor: Colors.white,
        onPressed: _openCreateTradeSheet,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text(
          'PROPOR TROCA (+20 REP)',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildTradesList(List<TradeModel> list, String uid) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nenhuma proposta de troca encontrada neste filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ProtocoloZColors.textMuted),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, idx) {
        final t = list[idx];
        return TradeCard(
          trade: t,
          currentUserId: uid,
          onTap: () => context.push('/trocas/${t.id}'),
          onAccept: () => _confirmAndRespond(t, 'accept'),
          onReject: () => _confirmAndRespond(t, 'reject'),
          onCancel: () => _confirmAndRespond(t, 'cancel'),
        );
      },
    );
  }
}
