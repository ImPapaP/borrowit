import 'package:flutter/material.dart';

import '../../models/equipment.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import 'equipment_detail_screen.dart';

/// Equipment tab: search box, category filter and the equipment grid.
class EquipmentListView extends StatefulWidget {
  const EquipmentListView({super.key});

  @override
  State<EquipmentListView> createState() => _EquipmentListViewState();
}

class _EquipmentListViewState extends State<EquipmentListView> {
  late final Stream<List<Equipment>> _equipment =
      FirestoreService.instance.equipmentStream();
  final _search = TextEditingController();
  String _query = '';
  String? _category; // null means "All"
  bool _seeding = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Equipment> _filter(List<Equipment> all) {
    final query = _query.trim().toLowerCase();
    return all.where((item) {
      if (_category != null && item.category != _category) return false;
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  void _open(Equipment item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EquipmentDetailScreen(equipment: item),
      ),
    );
  }

  Future<void> _seed() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _seeding = true);
    try {
      await FirestoreService.instance.seedSampleEquipment();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not load sample equipment. While seeding, Firestore must '
            'be in test mode (see README).\n$error',
          ),
        ),
      );
    }
    if (mounted) setState(() => _seeding = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Equipment>>(
      stream: _equipment,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MessageView(
            icon: Icons.error_outline,
            title: 'Could not load equipment',
            message: '${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = snapshot.data!;
        if (all.isEmpty) {
          return MessageView(
            icon: Icons.inventory_2_outlined,
            title: 'No equipment yet',
            message: 'Equipment added by the school will appear here.',
            // Only works while Firestore is in test mode; the final rules
            // block students from writing equipment.
            action: FilledButton.icon(
              onPressed: _seeding ? null : _seed,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(_seeding ? 'Loading…' : 'Load sample equipment'),
            ),
          );
        }

        final categories = {for (final item in all) item.category}.toList()
          ..sort();
        final results = _filter(all);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search equipment',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _categoryChip('All', null),
                  for (final category in categories)
                    _categoryChip(category, category),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const MessageView(
                      icon: Icons.search_off,
                      title: 'No matches',
                      message: 'Try a different word or category.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.6,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return _EquipmentCard(
                          equipment: item,
                          onTap: () => _open(item),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryChip(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _category == value,
        onSelected: (_) => setState(() => _category = value),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.equipment, required this.onTap});

  final Equipment equipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'equipment-${equipment.id}',
                child: EquipmentImage(equipment.image),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    equipment.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    equipment.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AvailabilityBadge(equipment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
