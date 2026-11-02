import 'package:flutter/material.dart';

import '../../models/borrow_request.dart';
import '../../models/equipment.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'equipment_detail_screen.dart';

/// Equipment tab: welcome banner, search, category cards and the grid.
class EquipmentListView extends StatefulWidget {
  const EquipmentListView({super.key, required this.uid, this.userName});

  final String uid;
  final String? userName;

  @override
  State<EquipmentListView> createState() => _EquipmentListViewState();
}

class _EquipmentListViewState extends State<EquipmentListView> {
  late final Stream<List<Equipment>> _equipment =
      FirestoreService.instance.equipmentStream();
  late final Stream<List<BorrowRequest>> _requests =
      FirestoreService.instance.myRequestsStream(widget.uid);
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
            'Could not load sample equipment. If some sample items already '
            'exist, add or edit equipment in the Firebase console.\n$error',
          ),
        ),
      );
    }
    if (mounted) setState(() => _seeding = false);
  }

  String get _firstName {
    final name = (widget.userName ?? '').trim();
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
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
            // firestore.rules lets students add the sample items once,
            // while they don't exist yet.
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
        final availableItems = all.where((item) => item.isAvailable).length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _WelcomeBanner(
                  firstName: _firstName,
                  availableItems: availableItems,
                  categoryCount: categories.length,
                  requests: _requests,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search laptops, cables, cameras…',
                    prefixIcon: const Icon(Icons.search_rounded),
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
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 104,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  children: [
                    _CategoryCard(
                      label: 'All',
                      icon: Icons.apps_rounded,
                      color: brandBlue,
                      count: all.length,
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final category in categories)
                      _CategoryCard(
                        label: category,
                        icon: CategoryStyle.of(category).icon,
                        color: CategoryStyle.of(category).color,
                        count: all.where((e) => e.category == category).length,
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  children: [
                    Text(
                      _category ?? 'All equipment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      results.length == 1 ? '1 item' : '${results.length} items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: MessageView(
                  icon: Icons.search_off,
                  title: 'No matches',
                  message: 'Try a different word or category.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 270,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = results[index];
                      return _EquipmentCard(
                        equipment: item,
                        onTap: () => _open(item),
                      );
                    },
                    childCount: results.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.firstName,
    required this.availableItems,
    required this.categoryCount,
    required this.requests,
  });

  final String firstName;
  final int availableItems;
  final int categoryCount;
  final Stream<List<BorrowRequest>> requests;

  @override
  Widget build(BuildContext context) {
    return GradientBanner(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $firstName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What do you need to borrow today?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.backpack_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<BorrowRequest>>(
            stream: requests,
            builder: (context, snapshot) {
              final mine = snapshot.data ?? const <BorrowRequest>[];
              final active = mine
                  .where((r) =>
                      r.status == RequestStatus.pending ||
                      r.status == RequestStatus.approved ||
                      r.status == RequestStatus.borrowed)
                  .length;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  BannerStat(
                    icon: Icons.inventory_2_outlined,
                    value: '$availableItems',
                    label: 'Items free now',
                  ),
                  BannerStat(
                    icon: Icons.category_outlined,
                    value: '$categoryCount',
                    label: 'Categories',
                  ),
                  BannerStat(
                    icon: Icons.assignment_outlined,
                    value: '$active',
                    label: 'Active requests',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? color : cardColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 128,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? color : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  count == 1 ? '1 item' : '$count items',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final style = CategoryStyle.of(equipment.category);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: style.color.withValues(alpha: 0.08)),
                  Hero(
                    tag: 'equipment-${equipment.id}',
                    child: EquipmentImage(equipment.image),
                  ),
                  if (!equipment.isAvailable)
                    ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: AvailabilityBadge(equipment, overlay: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryLabel(equipment.category),
                  const SizedBox(height: 8),
                  Text(
                    equipment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    equipment.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          equipment.location.isEmpty ? '—' : equipment.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
