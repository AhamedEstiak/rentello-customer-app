import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/locations.dart';
import '../providers/locations_provider.dart';
import '../../../core/theme/app_theme.dart';

class LocationSelectorSheet extends ConsumerStatefulWidget {
  final LocationSelection? initialSelection;

  /// When true, loads pickup-eligible locations; when false, destination-eligible.
  final bool forPickup;

  const LocationSelectorSheet({
    super.key,
    this.initialSelection,
    required this.forPickup,
  });

  @override
  ConsumerState<LocationSelectorSheet> createState() =>
      _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends ConsumerState<LocationSelectorSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(flatLocationsProvider(widget.forPickup));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search location',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: locationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load locations',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  data: (locations) {
                    final query = _searchCtrl.text.trim().toLowerCase();
                    final filtered = query.isEmpty
                        ? locations
                        : locations
                            .where((loc) =>
                                loc.nameEn.toLowerCase().contains(query) ||
                                loc.name.toLowerCase().contains(query))
                            .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No locations found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final loc = filtered[index];
                        final isSelected =
                            loc.id == widget.initialSelection?.locationId;
                        final showSubtitle = loc.name != loc.nameEn &&
                            loc.name.isNotEmpty;

                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          title: Text(loc.nameEn),
                          subtitle: showSubtitle ? Text(loc.name) : null,
                          onTap: () {
                            Navigator.pop(
                              context,
                              LocationSelection(
                                locationId: loc.id,
                                label: loc.nameEn,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
