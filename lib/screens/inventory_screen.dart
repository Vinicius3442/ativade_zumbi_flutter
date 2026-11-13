import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_mapper.dart';
import '../providers/game_providers.dart';
import '../widgets/item_tile.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _selectedCategory = 'todos';

  static const List<({String key, String label})> _categories = [
    (key: 'todos', label: 'Todos'),
    (key: 'agua', label: 'Água'),
    (key: 'comida', label: 'Comida'),
    (key: 'medicamentos', label: 'Medicamentos'),
    (key: 'ferramentas', label: 'Ferramentas'),
    (key: 'combustivel', label: 'Combustível'),
  ];

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameControllerProvider);
    final filtered = _selectedCategory == 'todos'
        ? gs.inventory
        : gs.inventory
              .where((e) => e.item.category == _selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('INVENTÁRIO TÁTICO'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar Inventário',
            onPressed: () =>
                ref.read(gameControllerProvider.notifier).refreshAllData(),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabeçalho com total e proteção RLS
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ProtocoloZColors.bgBunker,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProtocoloZColors.radarGreen),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  color: ProtocoloZColors.radarGreen,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL NA MOCHILA: ${gs.totalInventoryUnits} UNIDADES (${gs.inventory.length} TIPOS)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: ProtocoloZColors.radarGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Protegido por RLS no Supabase: alterado exclusivamente por Kit Inicial, Expedições e Trocas Atômicas.',
                        style: TextStyle(
                          fontSize: 11,
                          color: ProtocoloZColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Filtros por categoria
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat.key;
                final color = cat.key == 'todos'
                    ? ProtocoloZColors.radarGreen
                    : IconMapper.categoryColor(cat.key);
                return ChoiceChip(
                  label: Text(cat.label.toUpperCase()),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.25),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: selected ? color : ProtocoloZColors.textMuted,
                  ),
                  side: BorderSide(
                    color: selected ? color : ProtocoloZColors.borderGray,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat.key),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.backpack_outlined,
                            size: 64,
                            color: ProtocoloZColors.steelGray,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectedCategory == 'todos'
                                ? 'Sua mochila está vazia!'
                                : 'Nenhum item na categoria "${IconMapper.categoryLabel(_selectedCategory)}".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: ProtocoloZColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Participe de expedições de coleta ou realize trocas com outros sobreviventes para abastecer seu inventário.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: ProtocoloZColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, idx) {
                      final entry = filtered[idx];
                      return ItemTile(
                        item: entry.item,
                        quantity: entry.quantity,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
