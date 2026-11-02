import 'package:flutter/material.dart';

import '../../models/equipment.dart';
import '../../services/firestore_service.dart';
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
        return Scaffold(
          appBar: AppBar(title: Text(item.name)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Hero(
                tag: 'equipment-${item.id}',
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: EquipmentImage(item.image),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.category_outlined, size: 18),
                          label: Text(item.category),
                        ),
                        AvailabilityBadge(item),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Description'),
                    Text(
                      item.description.isEmpty
                          ? 'No description provided.'
                          : item.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Details'),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'Quantity',
                            value:
                                '${item.quantityAvailable} of ${item.quantityTotal} available',
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.place_outlined,
                            label: 'Pick-up location',
                            value: item.location.isEmpty ? '—' : item.location,
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.verified_outlined,
                            label: 'Condition',
                            value: item.condition.isEmpty ? '—' : item.condition,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: item.isAvailable ? () => _borrow(item) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: Icon(item.isAvailable ? Icons.add_task : Icons.block),
                label: Text(
                  item.isAvailable ? 'Request to borrow' : 'Currently unavailable',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
