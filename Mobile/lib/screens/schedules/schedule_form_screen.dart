import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/schedule_model.dart';

class ScheduleFormScreen extends StatefulWidget {
  final String initialKind; // 'Event' or 'Pickup'
  final ScheduleModel? schedule;
  final List<ScheduleModel> allActiveSchedules;

  const ScheduleFormScreen({
    super.key,
    required this.initialKind,
    this.schedule,
    this.allActiveSchedules = const [],
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _kind;
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _donorNameController;
  late final TextEditingController _pickupAddressController;
  late final TextEditingController _contactController;
  late final TextEditingController _volumeController;

  DateTime? _eventDate;
  DateTimeRange? _pickupDateRange;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  late String _eventStatus;
  late String _pickupStatus;

  bool _isSubmitting = false;
  String? _conflictBanner;
  String? _suggestedStart24;
  String? _suggestedEnd24;

  List<Map<String, dynamic>> _bookedSlots = [];
  bool _loadingBookedSlots = false;

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _donorFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _volumeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _kind = s?.kind ?? widget.initialKind;

    _titleController = TextEditingController(text: s?.title ?? '');
    _locationController = TextEditingController(text: s?.location ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _donorNameController = TextEditingController(text: s?.donorName ?? '');
    _pickupAddressController = TextEditingController(text: s?.pickupAddress ?? '');
    _contactController = TextEditingController(text: s?.contactNumber ?? '');
    _volumeController = TextEditingController(
      text: s != null && s.totalVolume > 0 ? s.totalVolume.toStringAsFixed(0) : '',
    );

    _eventStatus = s?.status ?? 'Pending';
    _pickupStatus = s?.pickupStatus ?? 'Pending';

    if (s != null) {
      if (s.isEvent) {
        _eventDate = s.date ?? s.startDate;
      } else {
        final start = s.startDate ?? s.date ?? DateTime.now();
        final end = s.endDate ?? s.startDate ?? s.date ?? DateTime.now();
        _pickupDateRange = DateTimeRange(start: start, end: end);
      }

      if (s.startTime.isNotEmpty) {
        final mins = ScheduleModel.parseTimeToMinutes(s.startTime);
        if (mins != null) {
          _startTime = TimeOfDay(hour: mins ~/ 60, minute: mins % 60);
        }
      }
      if (s.endTime.isNotEmpty) {
        final mins = ScheduleModel.parseTimeToMinutes(s.endTime);
        if (mins != null) {
          _endTime = TimeOfDay(hour: mins ~/ 60, minute: mins % 60);
        }
      }
    }

    _fetchBookedSlots();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _donorNameController.dispose();
    _pickupAddressController.dispose();
    _contactController.dispose();
    _volumeController.dispose();

    _titleFocus.dispose();
    _locationFocus.dispose();
    _donorFocus.dispose();
    _addressFocus.dispose();
    _contactFocus.dispose();
    _volumeFocus.dispose();

    super.dispose();
  }

  bool get _isEdit => widget.schedule != null;

  String _formatTimeOfDay(TimeOfDay? tod) {
    if (tod == null) return '';
    final h24 = tod.hour.toString().padLeft(2, '0');
    final m24 = tod.minute.toString().padLeft(2, '0');
    return '$h24:$m24';
  }

  String _formatTimeOfDay12(TimeOfDay? tod) {
    if (tod == null) return '';
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final ampm = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $ampm';
  }

  List<String> get _selectedDateStrings {
    final list = <String>[];
    if (_kind == 'Event') {
      if (_eventDate != null) {
        list.add(DateFormat('yyyy-MM-dd').format(_eventDate!));
      }
    } else {
      if (_pickupDateRange != null) {
        DateTime cur = DateTime(_pickupDateRange!.start.year, _pickupDateRange!.start.month, _pickupDateRange!.start.day);
        final end = DateTime(_pickupDateRange!.end.year, _pickupDateRange!.end.month, _pickupDateRange!.end.day);
        while (!cur.isAfter(end)) {
          list.add(DateFormat('yyyy-MM-dd').format(cur));
          cur = cur.add(const Duration(days: 1));
        }
      }
    }
    return list;
  }

  Future<void> _fetchBookedSlots() async {
    final dates = _selectedDateStrings;
    if (dates.isEmpty) return;

    setState(() => _loadingBookedSlots = true);
    final primaryDate = dates.first;
    try {
      final res = await ApiClient.get(
        ApiConstants.bookedSlots(primaryDate, excludeId: widget.schedule?.id),
      );
      if (res is Map && res['bookedSlots'] is List) {
        if (mounted) {
          setState(() {
            _bookedSlots = List<Map<String, dynamic>>.from(res['bookedSlots']);
            _loadingBookedSlots = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingBookedSlots = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBookedSlots = false);
    }
  }

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final initial = _eventDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryNavy,
              primary: AppColors.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _eventDate = picked;
        _conflictBanner = null;
      });
      _fetchBookedSlots();
    }
  }

  Future<void> _pickPickupDateRange() async {
    final now = DateTime.now();
    final initial = _pickupDateRange ?? DateTimeRange(start: now, end: now.add(const Duration(days: 1)));
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryNavy,
              primary: AppColors.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _pickupDateRange = picked;
        _conflictBanner = null;
      });
      _fetchBookedSlots();
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0)) : (_endTime ?? const TimeOfDay(hour: 10, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryNavy,
              primary: AppColors.primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _conflictBanner = null;
      });
    }
  }

  void _applySuggestedSlot() {
    if (_suggestedStart24 == null || _suggestedEnd24 == null) return;
    final sMins = ScheduleModel.parseTimeToMinutes(_suggestedStart24);
    final eMins = ScheduleModel.parseTimeToMinutes(_suggestedEnd24);
    if (sMins != null && eMins != null) {
      setState(() {
        _startTime = TimeOfDay(hour: sMins ~/ 60, minute: sMins % 60);
        _endTime = TimeOfDay(hour: eMins ~/ 60, minute: eMins % 60);
        _conflictBanner = null;
      });
    }
  }

  bool _isDateInPast(DateTime dt) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dtStart = DateTime(dt.year, dt.month, dt.day);
    return dtStart.isBefore(todayStart);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    final dates = _selectedDateStrings;
    if (dates.isEmpty) {
      _showSnackbar('Please select a date', isError: true);
      return;
    }

    // Past date check
    if (_kind == 'Event') {
      if (_isDateInPast(_eventDate!)) {
        _showSnackbar('Event date cannot be in the past.', isError: true);
        return;
      }
    } else {
      if (_pickupDateRange != null && _isDateInPast(_pickupDateRange!.start)) {
        _showSnackbar('Notice: Pickup date starts in the past.', isError: false);
      }
    }

    // Validate times
    if (_startTime == null || _endTime == null) {
      _showSnackbar('Both Start Time and End Time are required.', isError: true);
      return;
    }

    final sMin = _startTime!.hour * 60 + _startTime!.minute;
    final eMin = _endTime!.hour * 60 + _endTime!.minute;

    if (eMin <= sMin) {
      _showSnackbar('End Time must be later than Start Time.', isError: true);
      return;
    }

    final sTime24 = _formatTimeOfDay(_startTime);
    final eTime24 = _formatTimeOfDay(_endTime);

    // Instant in-app overlap check before submitting
    final clientConflict = OverlapChecker.check(
      activeSchedules: widget.allActiveSchedules,
      kind: _kind,
      titleOrDonor: _kind == 'Event' ? _titleController.text.trim() : _donorNameController.text.trim(),
      targetDates: dates,
      startTime24: sTime24,
      endTime24: eTime24,
      excludeId: widget.schedule?.id,
    );

    if (clientConflict.hasConflict) {
      setState(() {
        _conflictBanner = clientConflict.message;
        _suggestedStart24 = clientConflict.suggestedStart24;
        _suggestedEnd24 = clientConflict.suggestedEnd24;
      });
      _showConflictDialog(clientConflict.message);
      return;
    }

    // Prepare payload
    final data = <String, dynamic>{
      'kind': _kind,
      'startTime': sTime24,
      'endTime': eTime24,
      'time': '$sTime24 - $eTime24',
    };

    if (_kind == 'Event') {
      data['title'] = _titleController.text.trim();
      data['location'] = _locationController.text.trim();
      data['address'] = _locationController.text.trim();
      data['description'] = _descriptionController.text.trim();
      data['status'] = _isEdit ? _eventStatus : 'Pending';
      data['dates'] = DateFormat('yyyy-MM-dd').format(_eventDate!);
      data['date'] = DateFormat('yyyy-MM-dd').format(_eventDate!);
    } else {
      final vol = double.tryParse(_volumeController.text.trim()) ?? 0.0;
      data['donorName'] = _donorNameController.text.trim();
      data['pickupAddress'] = _pickupAddressController.text.trim();
      data['address'] = _pickupAddressController.text.trim();
      data['contactNumber'] = _contactController.text.trim();
      data['totalVolume'] = vol;
      data['pickupStatus'] = _pickupStatus;
      data['status'] = _pickupStatus == 'Picked Up' ? 'Completed' : 'Pending';

      final startStr = DateFormat('yyyy-MM-dd').format(_pickupDateRange!.start);
      final endStr = DateFormat('yyyy-MM-dd').format(_pickupDateRange!.end);
      data['startDate'] = startStr;
      data['endDate'] = endStr;
      data['dates'] = startStr;
      data['dateRange'] = '$startStr to $endStr';
    }

    setState(() => _isSubmitting = true);

    try {
      dynamic response;
      if (_isEdit) {
        response = await ApiClient.put(
          ApiConstants.scheduleById(widget.schedule!.id),
          data: data,
        );
      } else {
        response = await ApiClient.post(
          ApiConstants.schedules,
          data: data,
        );
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        // Show conflict or failure without losing form data
        if (error.statusCode == 409 || error.message.toLowerCase().contains('conflict')) {
          setState(() {
            _conflictBanner = error.message;
          });
          _showConflictDialog(error.message);
        } else {
          _showSnackbar(error.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackbar('Network error: Could not save schedule. Your changes are preserved.', isError: true);
      }
    }
  }

  void _showConflictDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 36),
        title: const Text('Schedule Conflict Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            if (_suggestedStart24 != null && _suggestedStart24!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_fix_high, color: AppColors.primaryNavy, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Apply suggested slot:\n${ScheduleModel.formatTime12(_suggestedStart24)} - ${ScheduleModel.formatTime12(_suggestedEnd24)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Current'),
          ),
          if (_suggestedStart24 != null && _suggestedStart24!.isNotEmpty)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
              onPressed: () {
                Navigator.pop(ctx);
                _applySuggestedSlot();
              },
              child: const Text('Use Suggested Slot'),
            ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit ${_kind} Schedule' : 'Create ${_kind} Schedule';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                minimumSize: const Size(80, 40),
              ),
              onPressed: _isSubmitting ? null : _save,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSubmitting ? 'Saving' : 'Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_conflictBanner != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Time Conflict Detected',
                                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_conflictBanner!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        if (_suggestedStart24 != null && _suggestedStart24!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(48, 38),
                            ),
                            onPressed: _applySuggestedSlot,
                            icon: const Icon(Icons.auto_fix_high, size: 16),
                            label: Text('Apply: ${ScheduleModel.formatTime12(_suggestedStart24)} - ${ScheduleModel.formatTime12(_suggestedEnd24)}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Schedule Type Selector (only on create)
                if (!_isEdit) ...[
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Event', label: Text('Event Schedule'), icon: Icon(Icons.event)),
                      ButtonSegment(value: 'Pickup', label: Text('Pickup Schedule'), icon: Icon(Icons.local_shipping)),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (val) {
                      setState(() {
                        _kind = val.first;
                        _conflictBanner = null;
                      });
                      _fetchBookedSlots();
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primaryNavy,
                      selectedForegroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Date Picker Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _kind == 'Event' ? 'Event Date' : 'Pickup Date Range',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _kind == 'Event' ? _pickEventDate : _pickPickupDateRange,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppColors.primaryNavy),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _kind == 'Event'
                                        ? (_eventDate != null ? DateFormat('MMMM dd, yyyy').format(_eventDate!) : 'Select Event Date')
                                        : (_pickupDateRange != null
                                            ? '${DateFormat('MMM dd, yyyy').format(_pickupDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_pickupDateRange!.end)}'
                                            : 'Select Date Range'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: (_kind == 'Event' ? _eventDate == null : _pickupDateRange == null)
                                          ? AppColors.textMuted
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        if (_kind == 'Event' && _eventDate != null && _isDateInPast(_eventDate!)) ...[
                          const SizedBox(height: 6),
                          const Text('Past dates are not allowed for events.', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Pickers Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Time Window',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Times apply to every day in the selected date range. Cannot cross midnight.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isStart: true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 18, color: AppColors.primaryNavy),
                                          const SizedBox(width: 6),
                                          Text(
                                            _startTime != null ? _formatTimeOfDay12(_startTime) : 'Select Start',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: _startTime != null ? AppColors.textPrimary : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(isStart: false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 48),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('End Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_filled, size: 18, color: AppColors.primaryNavy),
                                          const SizedBox(width: 6),
                                          Text(
                                            _endTime != null ? _formatTimeOfDay12(_endTime) : 'Select End',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: _endTime != null ? AppColors.textPrimary : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Booked slots on this date
                        if (_bookedSlots.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.primaryNavy),
                              const SizedBox(width: 6),
                              Text(
                                'Booked slots on this date (${_bookedSlots.length}):',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _bookedSlots.map((b) {
                              final name = b['name']?.toString() ?? 'Booked';
                              final time = '${b['start12'] ?? b['startTime']} - ${b['end12'] ?? b['endTime']}';
                              return Chip(
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: AppColors.border,
                                label: Text(
                                  '$time ($name)',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                                ),
                              );
                            }).toList(),
                          ),
                        ] else if (_loadingBookedSlots) ...[
                          const SizedBox(height: 8),
                          const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Details Card based on Kind
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _kind == 'Event' ? 'Event Details' : 'Donor & Pickup Details',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),

                        if (_kind == 'Event') ...[
                          TextFormField(
                            controller: _titleController,
                            focusNode: _titleFocus,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Event Title *',
                              prefixIcon: Icon(Icons.title),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Event title is required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _locationController,
                            focusNode: _locationFocus,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Location *',
                              prefixIcon: Icon(Icons.place),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _eventStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                                DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                                DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                              ],
                              onChanged: (val) => setState(() => _eventStatus = val ?? 'Pending'),
                            ),
                          ],
                        ] else ...[
                          TextFormField(
                            controller: _donorNameController,
                            focusNode: _donorFocus,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Name of Donor *',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Donor name is required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pickupAddressController,
                            focusNode: _addressFocus,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Address *',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Pickup address is required' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _contactController,
                            focusNode: _contactFocus,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number *',
                              prefixIcon: Icon(Icons.phone),
                              hintText: 'e.g. 09171234567',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Contact number is required';
                              final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                              if (!RegExp(r'^\d{7,15}$').hasMatch(cleaned)) {
                                return 'Enter a valid phone number (at least 7 digits)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _volumeController,
                            focusNode: _volumeFocus,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Total Volume (ml) *',
                              prefixIcon: Icon(Icons.water_drop),
                              hintText: 'e.g. 500',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Total volume is required';
                              final num = double.tryParse(v.trim());
                              if (num == null || num <= 0) return 'Volume must be a positive number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _pickupStatus,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Status',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_shipping_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                              DropdownMenuItem(value: 'Picked Up', child: Text('Picked Up')),
                              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                            ],
                            onChanged: (val) => setState(() => _pickupStatus = val ?? 'Pending'),
                          ),
                          if (_pickupStatus == 'Picked Up') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.inventory_2, size: 18, color: AppColors.primaryNavy),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Setting status to "Picked Up" will record this collection and move the volume into the Unpasteurized refrigerator.',
                                      style: TextStyle(fontSize: 12, color: AppColors.primaryNavy),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmitting ? null : _save,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Saving Schedule...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Text(
                          _isEdit ? 'Update Schedule' : 'Create Schedule',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

