import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/locations.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/providers/booking_form_provider.dart';
import '../../booking/widgets/district_upazila_selector_sheet.dart';
import '../providers/vehicle_provider.dart';

class InstantBookingScreen extends ConsumerStatefulWidget {
  const InstantBookingScreen({super.key});

  @override
  ConsumerState<InstantBookingScreen> createState() => _InstantBookingScreenState();
}

class _InstantBookingType {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const _InstantBookingType({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const _bookingTypes = [
  _InstantBookingType(
    value: 'HOURLY',
    label: 'Hourly',
    description: 'Book by the hour, ideal for short trips',
    icon: Icons.access_time,
  ),
  _InstantBookingType(
    value: 'MULTI_DAY',
    label: 'Multi-day',
    description: 'Daily hire at a planned schedule',
    icon: Icons.calendar_month,
  ),
  _InstantBookingType(
    value: 'AIRPORT_TRANSFER',
    label: 'Airport Transfer',
    description: 'Pickup or drop-off at the airport',
    icon: Icons.flight,
  ),
  _InstantBookingType(
    value: 'INTERCITY',
    label: 'Intercity',
    description: 'Travel between cities at fixed rates',
    icon: Icons.route,
  ),
];

const _vehicleCategories = ['SEDAN', 'SUV', 'MICROBUS', 'PREMIUM'];

class _InstantBookingScreenState extends ConsumerState<InstantBookingScreen> {
  static const int _maxPassengers = 8;

  final _promoCtrl = TextEditingController();
  final _flightCtrl = TextEditingController();
  final _airportCtrl = TextEditingController();

  String _bookingType = 'HOURLY';

  String _pickupAddress = '';
  String _dropoffAddress = '';
  String? _pickupLocationId;
  String? _dropoffLocationId;

  DateTime? _pickupDate;
  DateTime? _dropoffDate;
  double _hours = 2;
  String? _selectedRouteId;

  int _passengerCount = 2;
  String? _selectedVehicleId;

  bool _isFareExpanded = false;
  Timer? _fareDebounce;
  String? _lastFareFingerprint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBookingFormProvider());
  }

  @override
  void dispose() {
    _fareDebounce?.cancel();
    _promoCtrl.dispose();
    _flightCtrl.dispose();
    _airportCtrl.dispose();
    super.dispose();
  }

  bool get _canEstimateFare {
    if (_selectedVehicleId == null || _selectedVehicleId!.isEmpty) return false;
    if (_pickupLocationId == null || _pickupLocationId!.isEmpty) return false;
    if (_pickupDate == null) return false;
    if (_bookingType == 'INTERCITY') {
      return _selectedRouteId != null && _selectedRouteId!.isNotEmpty;
    }
    return true;
  }

  BookingFormState _buildBookingFormState() {
    // Mirrors `BookingFormScreen` totalHours logic.
    int days = 1;
    double hours = _hours;
    if (_bookingType == 'MULTI_DAY' && _pickupDate != null && _dropoffDate != null) {
      final diff = _dropoffDate!.difference(_pickupDate!);
      days = diff.inDays.clamp(1, 365);
      hours = days * 8.0;
    }

    final pickupDate = _pickupDate;

    return BookingFormState(
      vehicleId: _selectedVehicleId ?? '',
      bookingType: _bookingType,
      pickupAddress: _pickupAddress.trim(),
      dropoffAddress: _dropoffAddress.trim(),
      pickupLocationId: _pickupLocationId,
      dropoffLocationId: _dropoffLocationId,
      scheduledPickup: _pickupDate,
      scheduledDropoff: _bookingType == 'MULTI_DAY' ? _dropoffDate : null,
      totalHours: hours,
      flightNumber: _flightCtrl.text.trim(),
      airportCode: _airportCtrl.text.trim(),
      routeId: _bookingType == 'INTERCITY' ? _selectedRouteId : null,
      isNight: pickupDate != null && (pickupDate.hour >= 22 || pickupDate.hour < 6),
    );
  }

  String _fareFingerprint(BookingFormState form) {
    final pickupIso = form.scheduledPickup?.toIso8601String() ?? '';
    final dropIso = form.scheduledDropoff?.toIso8601String() ?? '';
    return [
      form.vehicleId,
      form.bookingType,
      form.pickupLocationId ?? '',
      form.dropoffLocationId ?? '',
      form.totalHours.toStringAsFixed(2),
      form.isNight.toString(),
      form.routeId ?? '',
      pickupIso,
      dropIso,
    ].join('|');
  }

  void _syncBookingFormProvider() {
    ref.read(bookingFormProvider.notifier).setState(_buildBookingFormState());
  }

  void _maybeUpdateFareEstimate() {
    if (!_isFareExpanded) return;
    if (!_canEstimateFare) return;

    final form = _buildBookingFormState();
    final fp = _fareFingerprint(form);
    if (_lastFareFingerprint == fp) return;
    _lastFareFingerprint = fp;

    _fareDebounce?.cancel();
    _fareDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _promoCtrl.clear();
      ref.invalidate(fareEstimateProvider);
      // Estimate uses the provided booking form state.
      unawaited(ref.read(fareEstimateProvider.notifier).estimate(form));
    });
  }

  Future<void> _selectPickupLocation() async {
    final selection = await showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DistrictUpazilaSelectorSheet(),
    );

    if (!mounted || selection == null) return;

    setState(() {
      _pickupLocationId = selection.upazilaId;
      _pickupAddress = selection.label;
    });
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  Future<void> _selectDropoffLocation() async {
    final selection = await showModalBottomSheet<LocationSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DistrictUpazilaSelectorSheet(),
    );

    if (!mounted || selection == null) return;

    setState(() {
      _dropoffLocationId = selection.upazilaId;
      _dropoffAddress = selection.label;
    });
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  Future<void> _pickDate(bool isPickup) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: AppTheme.pickerDialogTheme,
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: AppTheme.pickerDialogTheme,
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isPickup) {
        _pickupDate = dt;
      } else {
        _dropoffDate = dt;
      }
    });
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  void _setBookingType(String bookingType) {
    setState(() {
      _bookingType = bookingType;
      _selectedRouteId = bookingType == 'INTERCITY' ? _selectedRouteId : null;
      if (bookingType == 'INTERCITY') {
        _dropoffAddress = '';
        _dropoffLocationId = null;
        _dropoffDate = null;
      } else {
        // Drop-off date-time is only relevant for MULTI_DAY.
        if (bookingType != 'MULTI_DAY') {
          _dropoffDate = null;
        }
      }
    });
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  void _setPassengerCount(int count) {
    setState(() {
      _passengerCount = count;
      _selectedVehicleId = null; // Force re-selection after filter changes.
    });
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  void _setSelectedVehicle(String vehicleId) {
    setState(() => _selectedVehicleId = vehicleId);
    _syncBookingFormProvider();
    _maybeUpdateFareEstimate();
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(authProvider).customer;
    final routesAsync = ref.watch(intercityRoutesProvider);
    final vehiclesAsync = ref.watch(vehicleListProvider('ALL'));
    final fareState = ref.watch(fareEstimateProvider);
    final form = ref.watch(bookingFormProvider);

    final greeting = _greetingForNow();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              customer?.name ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'INSTANT BOOKING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),

            _AccordionSection(
              title: 'Trip Type',
              icon: Icons.category_outlined,
              initiallyExpanded: false,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _buildBookingTypeCards(),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _AccordionSection(
              title: 'Locations',
              icon: Icons.location_on_outlined,
              initiallyExpanded: false,
              children: [
                _LocationTile(
                  label: 'Pickup Location',
                  icon: Icons.location_on_outlined,
                  value: _pickupAddress,
                  hint: 'Select pickup location',
                  hasValue: _pickupLocationId != null && _pickupLocationId!.isNotEmpty,
                  required: true,
                  onTap: _selectPickupLocation,
                ),
                if (_bookingType != 'INTERCITY') ...[
                  const SizedBox(height: 10),
                  _LocationTile(
                    label: 'Drop-off Location (optional)',
                    icon: Icons.location_on,
                    value: _dropoffAddress,
                    hint: 'Select drop-off location',
                    hasValue: _dropoffLocationId != null && _dropoffLocationId!.isNotEmpty,
                    required: false,
                    onTap: _selectDropoffLocation,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),
            _AccordionSection(
              title: 'Schedule & Details',
              icon: Icons.access_time,
              initiallyExpanded: false,
              children: [
                _DateTile(
                  label: 'Pickup Date & Time',
                  value: _pickupDate == null ? null : DateFormat('dd MMM yyyy, hh:mm a').format(_pickupDate!),
                  required: true,
                  onTap: () => _pickDate(true),
                  icon: Icons.calendar_today_outlined,
                ),

                if (_bookingType == 'HOURLY') ...[
                  const SizedBox(height: 12),
                  _DurationSlider(hours: _hours, onChanged: (v) {
                    setState(() => _hours = v);
                    _syncBookingFormProvider();
                    _maybeUpdateFareEstimate();
                  }),
                ],

                if (_bookingType == 'MULTI_DAY') ...[
                  const SizedBox(height: 12),
                  _DateTile(
                    label: 'Drop-off Date & Time',
                    value: _dropoffDate == null ? null : DateFormat('dd MMM yyyy, hh:mm a').format(_dropoffDate!),
                    required: false,
                    onTap: () => _pickDate(false),
                    icon: Icons.calendar_today_outlined,
                  ),
                ],

                if (_bookingType == 'INTERCITY') ...[
                  const SizedBox(height: 12),
                  _IntercityRoutePicker(
                    routesAsync: routesAsync,
                    selectedRouteId: _selectedRouteId,
                    onSelected: (v) {
                      setState(() => _selectedRouteId = v);
                      _syncBookingFormProvider();
                      _maybeUpdateFareEstimate();
                    },
                  ),
                ],

                if (_bookingType == 'AIRPORT_TRANSFER') ...[
                  const SizedBox(height: 12),
                  _FlightDetails(
                    flightCtrl: _flightCtrl,
                    airportCtrl: _airportCtrl,
                    onChanged: () {
                      _syncBookingFormProvider();
                      _maybeUpdateFareEstimate();
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),
            _AccordionSection(
              title: 'Passengers',
              icon: Icons.people_alt_outlined,
              initiallyExpanded: false,
              children: [
                const Text(
                  'Pick number of passengers (used to filter vehicles by seats).',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                    _maxPassengers,
                    (i) {
                      final count = i + 1;
                      final selected = _passengerCount == count;
                      return ChoiceChip(
                        label: Text('$count'),
                        selected: selected,
                        onSelected: (_) => _setPassengerCount(count),
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.primary : AppColors.border,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _AccordionSection(
              title: 'Vehicle Selection',
              icon: Icons.directions_car_outlined,
              initiallyExpanded: false,
              children: [
                vehiclesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Failed to load vehicles: $err',
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  data: (vehicles) {
                    final Map<String, List<Vehicle>> byCategory = {};
                    for (final v in vehicles) {
                      byCategory.putIfAbsent(v.category, () => <Vehicle>[]).add(v);
                    }

                    // Keep a stable category order for the UI.
                    final orderedCategories = [
                      ..._vehicleCategories,
                      ...byCategory.keys.where((c) => !_vehicleCategories.contains(c)),
                    ];

                    final panels = <Widget>[];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (() {
                        for (final cat in orderedCategories) {
                          final categoryVehicles = byCategory[cat];
                          if (categoryVehicles == null) continue;

                          final filtered = categoryVehicles
                              .where((v) => v.seats >= _passengerCount)
                              .toList();

                          if (filtered.isEmpty) continue;

                          panels.add(
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filtered.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.78,
                                    ),
                                    itemBuilder: (context, index) {
                                      final vehicle = filtered[index];
                                      final selected =
                                          vehicle.id == _selectedVehicleId;
                                      return _VehicleCard(
                                        vehicle: vehicle,
                                        selected: selected,
                                        onTap: () =>
                                            _setSelectedVehicle(vehicle.id),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (panels.isEmpty) {
                          return [
                            const Text(
                              'No vehicles available for this passenger count.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ];
                        }

                        return panels;
                      })(),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),
            _AccordionSection(
              title: 'Review Fare',
              icon: Icons.receipt_long_outlined,
              initiallyExpanded: false,
              trailing: _canEstimateFare
                  ? null
                  : const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                    ),
              onExpansionChanged: (expanded) {
                setState(() => _isFareExpanded = expanded);
                if (expanded) _maybeUpdateFareEstimate();
              },
              children: [
                _FareReviewPanel(
                  fareState: fareState,
                  form: form,
                  promoCtrl: _promoCtrl,
                  onApplyPromo: () {
                    final breakdown = fareState.breakdown;
                    if (breakdown == null) return;
                    ref.read(fareEstimateProvider.notifier).applyPromo(
                          _promoCtrl.text.trim(),
                          breakdown.subtotal,
                        );
                  },
                  onRetry: () {
                    final form = _buildBookingFormState();
                    _promoCtrl.clear();
                    ref.invalidate(fareEstimateProvider);
                    ref.read(fareEstimateProvider.notifier).estimate(form);
                  },
                  onConfirm: () {
                    final breakdown = fareState.breakdown;
                    if (breakdown == null) return;
                    final totalAmount = (breakdown.totalAmount - fareState.promoDiscount)
                        .clamp(0, double.infinity)
                        .toInt();

                    // Confirmation screen reads booking state from `bookingFormProvider`.
                    context.push(
                      '/booking/${form.vehicleId}/form/${form.bookingType}/review/confirm',
                      extra: {
                        'form': form,
                        'breakdown': breakdown,
                        'promoCodeId': fareState.promoCodeId,
                        'totalAmount': totalAmount,
                      },
                    );
                  },
                  canEstimateFare: _canEstimateFare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  List<Widget> _buildBookingTypeCards() {
    return _bookingTypes.map((type) {
      final isSelected = type.value == _bookingType;
      return GestureDetector(
        onTap: () => _setBookingType(type.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: SizedBox(
            width: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    type.icon,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _AccordionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final Widget? trailing;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;

  const _AccordionSection({
    required this.title,
    required this.icon,
    this.initiallyExpanded = false,
    this.trailing,
    required this.children,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        // Prevent Ink effects inside ExpansionTile title area.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: AppColors.primary),
          trailing: trailing,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: onExpansionChanged,
          childrenPadding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          children: [
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String hint;
  final bool hasValue;
  final bool required;
  final VoidCallback onTap;

  const _LocationTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.hasValue,
    required this.required,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: hasValue ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? value : hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (required && !hasValue) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Required',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String? value;
  final bool required;
  final VoidCallback onTap;
  final IconData icon;

  const _DateTile({
    required this.label,
    required this.value,
    required this.required,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: hasValue ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? value! : 'Select date & time',
                    style: TextStyle(
                      color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        if (required && !hasValue) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Required',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final double hours;
  final ValueChanged<double> onChanged;

  const _DurationSlider({
    required this.hours,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: hours,
                min: 1,
                max: 24,
                divisions: 23,
                label: '${hours.toInt()} hours',
                activeColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${hours.toInt()}h',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntercityRoutePicker extends StatelessWidget {
  final AsyncValue<List<IntercityRoute>> routesAsync;
  final String? selectedRouteId;
  final ValueChanged<String> onSelected;

  const _IntercityRoutePicker({
    required this.routesAsync,
    required this.selectedRouteId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return routesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Failed to load routes',
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
      data: (routes) {
        if (routes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No routes available',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Route',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedRouteId,
              hint: const Text('Choose origin → destination'),
              decoration: const InputDecoration(),
              items: routes
                  .map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(r.displayName),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onSelected(v);
              },
            ),
          ],
        );
      },
    );
  }
}

class _FlightDetails extends StatelessWidget {
  final TextEditingController flightCtrl;
  final TextEditingController airportCtrl;
  final VoidCallback onChanged;

  const _FlightDetails({
    required this.flightCtrl,
    required this.airportCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flight Details',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: flightCtrl,
          decoration: const InputDecoration(
            hintText: 'Flight number (e.g. BG-101)',
            prefixIcon: Icon(Icons.flight_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: airportCtrl,
          decoration: const InputDecoration(
            hintText: 'Airport code (e.g. DAC)',
            prefixIcon: Icon(Icons.local_airport_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        elevation: 0,
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
                          placeholder: (_, __) =>
                              Container(color: AppColors.border),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.border),
                        )
                      : Container(color: AppColors.border),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CategoryBadge(category: vehicle.category),
                  ),
                  if (selected)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: Icon(Icons.check_circle, color: AppColors.primary),
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
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.model,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${vehicle.seats}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '৳${vehicle.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FareReviewPanel extends StatelessWidget {
  final FareEstimateState fareState;
  final BookingFormState form;
  final TextEditingController promoCtrl;

  final VoidCallback onApplyPromo;
  final VoidCallback onRetry;
  final VoidCallback onConfirm;
  final bool canEstimateFare;

  const _FareReviewPanel({
    required this.fareState,
    required this.form,
    required this.promoCtrl,
    required this.onApplyPromo,
    required this.onRetry,
    required this.onConfirm,
    required this.canEstimateFare,
  });

  @override
  Widget build(BuildContext context) {
    final hasFareError = fareState.fareError != null && fareState.fareError!.isNotEmpty;
    final canConfirm = fareState.breakdown != null && !hasFareError;

    if (!canEstimateFare) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete your trip details to review fare.',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select pickup location, pickup date & time, and a vehicle. Route selection is required for Intercity.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: fareState.isLoading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BookingSummaryCard(form: form),
                  const SizedBox(height: 12),
                  if (hasFareError) ...[
                    _ErrorBanner(
                      message: fareState.fareError!,
                      onRetry: onRetry,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fareState.breakdown != null && !hasFareError) ...[
                    _FareCard(breakdown: fareState.breakdown!),
                    const SizedBox(height: 12),
                    _PromoSection(
                      controller: promoCtrl,
                      promoDiscount: fareState.promoDiscount,
                      error: fareState.promoError,
                      onApply: onApplyPromo,
                    ),
                    const SizedBox(height: 12),
                    _TotalCard(
                      subtotal: fareState.breakdown!.subtotal,
                      promoDiscount: fareState.promoDiscount,
                      baseDiscount: fareState.breakdown!.discount,
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: canConfirm ? onConfirm : null,
                        child: const Text('Confirm Booking'),
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Fare not available. Please retry or adjust trip details.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withOpacity(0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Try again',
                      style: TextStyle(fontSize: 12),
                    ),
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

class _BookingSummaryCard extends StatelessWidget {
  final BookingFormState form;

  const _BookingSummaryCard({required this.form});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Pickup',
              value: form.pickupAddress.isEmpty ? 'Not specified' : form.pickupAddress,
            ),
            if (form.dropoffAddress.isNotEmpty) ...[
              _DetailRow(
                icon: Icons.location_on,
                label: 'Drop-off',
                value: form.dropoffAddress,
              ),
            ],
            _DetailRow(
              icon: Icons.schedule,
              label: 'Type',
              value: form.bookingType.replaceAll('_', ' '),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  final FareBreakdown breakdown;

  const _FareCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fare Breakdown',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (breakdown.baseFare > 0) _FareRow('Base Fare', breakdown.baseFare),
            if (breakdown.hourlyCharge > 0) _FareRow('Hourly Charge', breakdown.hourlyCharge),
            if (breakdown.distanceCharge > 0) _FareRow('Distance Charge', breakdown.distanceCharge),
            if (breakdown.nightSurcharge > 0) _FareRow('Night Surcharge', breakdown.nightSurcharge),
            if (breakdown.airportSurcharge > 0) _FareRow('Airport Surcharge', breakdown.airportSurcharge),
            if (breakdown.intercitySurcharge > 0) _FareRow('Intercity Surcharge', breakdown.intercitySurcharge),
            if (breakdown.discount > 0) _FareRow('Discount', -breakdown.discount, isDiscount: true),
            const Divider(height: 20),
            _FareRow('Subtotal', breakdown.subtotal, isBold: true),
          ],
        ),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isBold;
  final bool isDiscount;

  const _FareRow(
    this.label,
    this.amount, {
    this.isBold = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          Text(
            '${isDiscount && amount < 0 ? "-" : ""}৳${amount.abs()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: isDiscount ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoSection extends StatelessWidget {
  final TextEditingController controller;
  final int promoDiscount;
  final String? error;
  final VoidCallback onApply;

  const _PromoSection({
    required this.controller,
    required this.promoDiscount,
    required this.error,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promo Code',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter promo code',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(90, 52)),
                  child: const Text('Apply'),
                ),
              ],
            ),
            if (error != null && error!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (promoDiscount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Promo applied! Saving ৳$promoDiscount',
                    style: const TextStyle(color: AppColors.success, fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int subtotal;
  final int promoDiscount;
  final int baseDiscount;

  const _TotalCard({
    required this.subtotal,
    required this.promoDiscount,
    required this.baseDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final total = (subtotal - promoDiscount).clamp(0, double.infinity).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '৳$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

