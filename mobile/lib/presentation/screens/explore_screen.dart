import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/destination_model.dart';
import '../providers/destinations_providers.dart';
import '../widgets/async_body.dart';
import '../widgets/destination_tile.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _cityController = TextEditingController();
  final _categoryController = TextEditingController();
  ({String? city, String? category})? _searchParams;

  @override
  void dispose() {
    _cityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browse = ref.watch(destinationsListProvider);
    final searchAsync = _searchParams != null
        ? ref.watch(destinationSearchProvider(_searchParams!))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore destinations'),
        leading: Navigator.of(context).canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Refresh list',
            onPressed: () {
              ref.invalidate(destinationsListProvider);
              if (_searchParams != null) {
                ref.invalidate(destinationSearchProvider(_searchParams!));
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City filter',
                    hintText: 'e.g. riyadh',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category filter',
                    hintText: 'optional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    final city = _cityController.text.trim();
                    final cat = _categoryController.text.trim();
                    setState(() {
                      _searchParams = (
                        city: city.isEmpty ? null : city,
                        category: cat.isEmpty ? null : cat,
                      );
                    });
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search API'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    setState(() => _searchParams = null);
                    _cityController.clear();
                    _categoryController.clear();
                  },
                  child: const Text('Clear search (show all)'),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: _searchParams == null
                ? AsyncBody<List<DestinationModel>>(
                    asyncValue: browse,
                    emptyMessage: 'No destinations returned from the server.',
                    onRetry: () => ref.invalidate(destinationsListProvider),
                    data: (context, list) => _DestinationList(list: list),
                  )
                : AsyncBody<List<DestinationModel>>(
                    asyncValue: searchAsync!,
                    emptyMessage: 'No matches for this search.',
                    onRetry: () => ref.invalidate(
                      destinationSearchProvider(_searchParams!),
                    ),
                    data: (context, list) => _DestinationList(list: list),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DestinationList extends StatelessWidget {
  const _DestinationList({required this.list});

  final List<DestinationModel> list;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = list[i];
        return DestinationTile(
          destination: d,
          onTap: () => Navigator.pushNamed(
            context,
            '/destination',
            arguments: d,
          ),
        );
      },
    );
  }
}
