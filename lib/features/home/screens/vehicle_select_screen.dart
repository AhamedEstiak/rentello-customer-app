import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/vehicle_provider.dart';

class VehicleSelectScreen extends ConsumerWidget {
  final String bookingType;

  const VehicleSelectScreen({super.key, required this.bookingType});

  String get _title {
    switch (bookingType) {
      case 'AIRPORT_TRANSFER':
        return 'Airport Transfer';
      case 'HOURLY':
        return 'Private Rental';
      case 'INTERCITY':
        return 'Intercity';
      case 'MULTI_DAY':
        return 'Multi-day Rental';
      default:
        return 'Select Vehicle';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final vehiclesAsync = ref.watch(vehicleListProvider(selectedCategory));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(selectedCategoryProvider.notifier).select(cat),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    checkmarkColor: Colors.white,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: vehiclesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(err.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(vehicleListProvider(selectedCategory)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (vehicles) => vehicles.isEmpty
                  ? const Center(
                      child: Text(
                        'No vehicles available',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) => _VehicleCard(
                        vehicle: vehicles[index],
                        bookingType: bookingType,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

const _categories = ['ALL', 'SEDAN', 'SUV', 'MICROBUS', 'PREMIUM'];

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final String bookingType;

  const _VehicleCard({required this.vehicle, required this.bookingType});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/booking/${vehicle.id}/form/$bookingType',
      ),
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  vehicle.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: vehicle.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: AppColors.border),
                          errorWidget: (_, _, _) =>
                              const _VehiclePlaceholder(),
                        )
                      : const _VehiclePlaceholder(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CategoryBadge(category: vehicle.category),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.brand,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vehicle.model,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${vehicle.seats}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          '৳${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehiclePlaceholder extends StatelessWidget {
  const _VehiclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.border,
      child: const Center(
        child:
            Icon(Icons.directions_car, size: 48, color: AppColors.textSecondary),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  Color get _color {
    switch (category) {
      case 'PREMIUM':
        return const Color(0xFF7C3AED);
      case 'SUV':
        return const Color(0xFF059669);
      case 'MICROBUS':
        return const Color(0xFFD97706);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
