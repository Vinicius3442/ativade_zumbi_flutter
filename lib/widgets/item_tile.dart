import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/icon_mapper.dart';
import '../models/item_model.dart';

class ItemTile extends StatelessWidget {
  final ItemModel item;
  final int quantity;
  final bool compact;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ItemTile({
    super.key,
    required this.item,
    required this.quantity,
    this.compact = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = IconMapper.categoryColor(item.category);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ProtocoloZColors.bgBunker,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ProtocoloZColors.borderGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconMapper.itemIcon(item.iconName),
              color: catColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ProtocoloZColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: catColor),
              ),
              child: Text(
                'x$quantity',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: catColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: catColor, width: 1.2),
                ),
                child: Icon(
                  IconMapper.itemIcon(item.iconName),
                  color: catColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ProtocoloZColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ProtocoloZColors.bgDarkest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: ProtocoloZColors.borderGray),
                          ),
                          child: Text(
                            IconMapper.categoryLabel(item.category).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: catColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ProtocoloZColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ??
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ProtocoloZColors.bgDarkest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ProtocoloZColors.radarGreen),
                    ),
                    child: Text(
                      'x$quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ProtocoloZColors.radarGreen,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
