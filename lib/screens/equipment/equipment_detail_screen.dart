import 'package:flutter/material.dart';

import '../../models/equipment.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../requests/borrow_request_screen.dart';

/// Full information about one piece of equipment, with live availability.
class EquipmentDetailScreen extends StatefulWidget {
  const EquipmentDetailScreen({super.key, required this.equipment});

  final Equipment equipment;

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  late final Stream<Equipment?> _live =
      FirestoreService.instance.equipmentById(widget.equipment.id);

  void _borrow(Equipment item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BorrowRequestScreen(equipment: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Equipment?>(
      stream: _live,
      initialData: widget.equipment,
      builder: (context, snapshot) {
        final item = snapshot.data ?? widget.equipment;
        final style = CategoryStyle.of(item.category);
        final wide = MediaQuery.sizeOf(context).width >= 720;

        final infoTiles = [
          InfoTile(
            icon: Icons.place_outlined,
            label: 'Pick-up location',
            value: item.location.isEmpty ? '—' : item.location,
            color: const Color(0xFFE0703A),
          ),
          InfoTile(
            icon: Icons.verified_outlined,
            label: 'Condition',
            value: item.condition.isEmpty ? '—' : item.condition,
            color: const Color(0xFF2E9D57),
          ),
          InfoTile(
            icon: style.icon,
            label: 'Category',
            value: item.category,
            color: style.color,
          ),
          InfoTile(
            icon: Icons.event_repeat_outlined,
            label: 'Longest loan',
            value: '$maxBorrowDays days',
            color: brandIndigo,
          ),
        ];

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: wide ? 380 : 300,
                backgroundColor: theme.scaffoldBackgroundColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filledTonal(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: style.color.withValues(alpha: 0.10)),
                      Hero(
                        tag: 'equipment-${item.id}',
                        child: EquipmentImage(item.image),
                      ),
                      // Fade into the page at the bottom.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.6, 1],
                            colors: [
                              theme.scaffoldBackgroundColor.withValues(alpha: 0),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CategoryIcon(item.category, size: 48),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    AvailabilityBadge(item),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: AvailabilityBar(item),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const SectionLabel('About this item'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                item.description.isEmpty
                                    ? 'No description provided.'
                                    : item.description,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(height: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const SectionLabel('Details'),
                          if (wide)
                            for (var i = 0; i < infoTiles.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(child: infoTiles[i]),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: i + 1 < infoTiles.length
                                          ? infoTiles[i + 1]
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              )
                          else
                            for (final tile in infoTiles)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: tile,
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: FilledButton.icon(
                    onPressed: item.isAvailable ? () => _borrow(item) : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    icon: Icon(item.isAvailable ? Icons.add_task : Icons.block),
                    label: Text(
                      item.isAvailable
                          ? 'Request to borrow'
                          : 'Currently unavailable',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
