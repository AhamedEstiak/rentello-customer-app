import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/locations.dart';
import '../../booking/providers/locations_provider.dart';
import '../../../core/theme/app_theme.dart';

class DistrictUpazilaSelectorSheet extends ConsumerStatefulWidget {
  final LocationSelection? initialSelection;

  const DistrictUpazilaSelectorSheet({super.key, this.initialSelection});

  @override
  ConsumerState<DistrictUpazilaSelectorSheet> createState() =>
      _DistrictUpazilaSelectorSheetState();
}

class _DistrictUpazilaSelectorSheetState
    extends ConsumerState<DistrictUpazilaSelectorSheet> {
  final _districtQueryCtrl = TextEditingController();
  final _upazilaQueryCtrl = TextEditingController();

  String? _selectedDistrictId;

  @override
  void initState() {
    super.initState();
    _selectedDistrictId = widget.initialSelection?.districtId;
    if (widget.initialSelection != null) {
      _districtQueryCtrl.text = '';
      _upazilaQueryCtrl.text = '';
    }
  }

  @override
  void dispose() {
    _districtQueryCtrl.dispose();
    _upazilaQueryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: locationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
                const SizedBox(height: 16),
                Text(err.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
          data: (districts) {
            final districtQuery = _districtQueryCtrl.text.trim().toLowerCase();
            final filteredDistricts = districtQuery.isEmpty
                ? districts
                : districts
                    .where((d) => d.name.toLowerCase().contains(districtQuery))
                    .toList();

            DistrictLocation? selectedDistrict;
            if (_selectedDistrictId != null) {
              for (final d in districts) {
                if (d.id == _selectedDistrictId) {
                  selectedDistrict = d;
                  break;
                }
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _districtQueryCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search district',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: filteredDistricts.isEmpty
                        ? Center(
                            child: Text(
                              'No districts found',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredDistricts.length,
                            itemBuilder: (context, index) {
                              final d = filteredDistricts[index];
                              final isSelected = d.id == _selectedDistrictId;
                              return ListTile(
                                dense: true,
                                title: Text(d.name),
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedDistrictId = d.id;
                                    _upazilaQueryCtrl.clear();
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  if (selectedDistrict != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Upazila',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _upazilaQueryCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search upazila',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final sd = selectedDistrict;
                          if (sd == null) {
                            return const SizedBox.shrink();
                          }
                          final upazilaQuery =
                              _upazilaQueryCtrl.text.trim().toLowerCase();
                          final filteredUpazilas = upazilaQuery.isEmpty
                              ? sd.upazilas
                              : sd.upazilas
                                  .where((u) => u.name
                                      .toLowerCase()
                                      .contains(upazilaQuery))
                                  .toList();

                          if (filteredUpazilas.isEmpty) {
                            return Center(
                              child: Text(
                                'No upazilas found',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: filteredUpazilas.length,
                            itemBuilder: (context, index) {
                              final u = filteredUpazilas[index];
                              return ListTile(
                                dense: true,
                                title: Text(u.name),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                    LocationSelection(
                                      districtId: sd.id,
                                      upazilaId: u.id,
                                      label:
                                          '${sd.name}, ${u.name}',
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: Text(
                          'Select a district to continue',
                          style: TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

