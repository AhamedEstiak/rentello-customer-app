import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/booking_form_provider.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String bookingType;

  const BookingFormScreen({
    super.key,
    required this.vehicleId,
    required this.bookingType,
  });

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  final _flightCtrl = TextEditingController();
  final _airportCtrl = TextEditingController();
  DateTime? _pickupDate;
  DateTime? _dropoffDate;
  double _hours = 2;
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingFormProvider.notifier).init(widget.vehicleId, widget.bookingType);
    });
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _flightCtrl.dispose();
    _airportCtrl.dispose();
    super.dispose();
  }

  String get _typeLabel {
    switch (widget.bookingType) {
      case 'HOURLY':
        return 'Hourly Booking';
      case 'MULTI_DAY':
        return 'Multi-day Booking';
      case 'AIRPORT_TRANSFER':
        return 'Airport Transfer';
      case 'INTERCITY':
        return 'Intercity Booking';
      default:
        return 'Booking Details';
    }
  }

  Future<void> _pickDate(bool isPickup) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isPickup) {
        _pickupDate = dt;
      } else {
        _dropoffDate = dt;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = widget.bookingType == 'INTERCITY'
        ? ref.watch(intercityRoutesProvider)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(_typeLabel)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionLabel('Pickup Location'),
            TextFormField(
              controller: _pickupCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter pickup address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (widget.bookingType != 'INTERCITY') ...[
              _SectionLabel('Drop-off Location (optional)'),
              TextFormField(
                controller: _dropoffCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter drop-off address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _SectionLabel('Pickup Date & Time'),
            _DatePickerTile(
              label: _pickupDate == null
                  ? 'Select date & time'
                  : DateFormat('dd MMM yyyy, hh:mm a').format(_pickupDate!),
              onTap: () => _pickDate(true),
              hasValue: _pickupDate != null,
            ),
            if (_pickupDate == null)
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 4),
                child: Text('Required', style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            if (widget.bookingType == 'HOURLY') ...[
              _SectionLabel('Duration'),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _hours,
                      min: 1,
                      max: 24,
                      divisions: 23,
                      label: '${_hours.toInt()} hours',
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _hours = v),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_hours.toInt()}h',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.bookingType == 'MULTI_DAY') ...[
              _SectionLabel('Drop-off Date & Time'),
              _DatePickerTile(
                label: _dropoffDate == null
                    ? 'Select date & time'
                    : DateFormat('dd MMM yyyy, hh:mm a').format(_dropoffDate!),
                onTap: () => _pickDate(false),
                hasValue: _dropoffDate != null,
              ),
            ],
            if (widget.bookingType == 'AIRPORT_TRANSFER') ...[
              const SizedBox(height: 16),
              _SectionLabel('Flight Details'),
              TextFormField(
                controller: _flightCtrl,
                decoration: const InputDecoration(
                  hintText: 'Flight number (e.g. BG-101)',
                  prefixIcon: Icon(Icons.flight_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _airportCtrl,
                decoration: const InputDecoration(
                  hintText: 'Airport code (e.g. DAC)',
                  prefixIcon: Icon(Icons.local_airport_outlined),
                ),
              ),
            ],
            if (widget.bookingType == 'INTERCITY') ...[
              const SizedBox(height: 16),
              _SectionLabel('Select Route'),
              routesAsync?.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text(
                      'Failed to load routes',
                      style: const TextStyle(color: AppColors.error),
                    ),
                    data: (routes) => routes.isEmpty
                        ? const Text('No routes available')
                        : DropdownButtonFormField<String>(
                            value: _selectedRouteId,
                            hint: const Text('Choose origin → destination'),
                            decoration: const InputDecoration(),
                            validator: (v) => v == null ? 'Please select a route' : null,
                                    items: routes
                                .map((r) => DropdownMenuItem(
                                      value: r.id,
                                      child: Text(r.displayName),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedRouteId = v),
                          ),
                  ) ??
                  const SizedBox.shrink(),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _onContinue,
              child: const Text('Review Fare'),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup date & time')),
      );
      return;
    }

    int days = 1;
    double hours = _hours;

    if (widget.bookingType == 'MULTI_DAY' && _dropoffDate != null) {
      final diff = _dropoffDate!.difference(_pickupDate!);
      days = diff.inDays.clamp(1, 365);
      hours = days * 8.0;
    }

    final form = BookingFormState(
      vehicleId: widget.vehicleId,
      bookingType: widget.bookingType,
      pickupAddress: _pickupCtrl.text.trim(),
      dropoffAddress: _dropoffCtrl.text.trim(),
      scheduledPickup: _pickupDate,
      scheduledDropoff: _dropoffDate,
      totalHours: hours,
      flightNumber: _flightCtrl.text.trim(),
      airportCode: _airportCtrl.text.trim(),
      routeId: _selectedRouteId,
      isNight: _pickupDate != null &&
          (_pickupDate!.hour >= 22 || _pickupDate!.hour < 6),
    );

    ref.read(bookingFormProvider.notifier).setState(form);

    context.push(
      '/booking/${widget.vehicleId}/form/${widget.bookingType}/review',
      extra: {'form': form},
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool hasValue;

  const _DatePickerTile({
    required this.label,
    required this.onTap,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              Icons.calendar_today_outlined,
              size: 18,
              color: hasValue ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
