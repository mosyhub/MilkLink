import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/screening_appointment_model.dart';
import '../../widgets/custom_button.dart';

class BookScreeningAppointmentScreen extends StatefulWidget {
  final VoidCallback? onAppointmentBooked;

  const BookScreeningAppointmentScreen({Key? key, this.onAppointmentBooked}) : super(key: key);

  @override
  State<BookScreeningAppointmentScreen> createState() => _BookScreeningAppointmentScreenState();
}

class _BookScreeningAppointmentScreenState extends State<BookScreeningAppointmentScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  List<ScreeningTimeSlot> _slots = [];
  String? _selectedSlot;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _slotErrorMessage;
  final TextEditingController _notesController = TextEditingController();
  String _purpose = 'First-Time Donor Screening';

  @override
  void initState() {
    super.initState();
    // Default to next weekday if tomorrow is Sunday
    if (_selectedDate.weekday == DateTime.sunday) {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    }
    _fetchSlotsForDate(_selectedDate);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _slotErrorMessage = null;
      _selectedSlot = null;
    });

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await ApiClient.get('${ApiConstants.screeningSlots}?date=$dateStr');

      if (response['success'] == true) {
        final List slotList = response['slots'] ?? [];
        final parsed = slotList.map((s) => ScreeningTimeSlot.fromJson(s)).toList();
        setState(() {
          _slots = parsed;
          if (response['isOpen'] == false) {
            _slotErrorMessage = response['message'] ?? 'Clinic is closed on this day.';
          }
        });
      } else {
        setState(() {
          _slotErrorMessage = response['message'] ?? 'Failed to load time slots';
        });
      }
    } catch (e) {
      setState(() {
        _slotErrorMessage = 'Could not load appointment slots. Please try another date.';
      });
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.accentPink,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSlotsForDate(picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available appointment time slot.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final response = await ApiClient.post(
        ApiConstants.bookScreeningAppointment,
        data: {
          'appointmentDate': dateStr,
          'timeSlot': _selectedSlot,
          'purpose': _purpose,
          'donorNotes': _notesController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final apt = response['appointment'];
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                SizedBox(width: 8),
                Text('Booking Requested', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your donor screening appointment has been scheduled!\n\nReference: ${apt['appointmentId'] ?? 'APT-PENDING'}\nDate: $dateStr\nTime: $_selectedSlot\nLocation: Room 204, Pasig Human Milk Bank Clinic',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please arrive 15 minutes before your time slot. Milk bank personnel will confirm your appointment shortly.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onAppointmentBooked?.call();
                  Navigator.pop(context, true);
                },
                child: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book appointment. Please try again.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Screening Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informational Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, color: AppColors.primaryNavy, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hospital Screening Visit',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryNavy, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select your preferred date & time for in-person evaluation by Pasig Human Milk Bank healthcare personnel.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Purpose Selection
            const Text(
              'Appointment Purpose',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _purpose,
                  isExpanded: true,
                  onChanged: (val) {
                    if (val != null) setState(() => _purpose = val);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'First-Time Donor Screening',
                      child: Text('First-Time Donor Screening'),
                    ),
                    DropdownMenuItem(
                      value: 'Donor Re-assessment',
                      child: Text('Donor Re-assessment (Returning Donor)'),
                    ),
                    DropdownMenuItem(
                      value: 'Laboratory Verification Follow-up',
                      child: Text('Laboratory Verification Follow-up'),
                    ),
                    DropdownMenuItem(
                      value: 'Medical Evaluation',
                      child: Text('Medical Evaluation'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date Selection
            const Text(
              'Select Hospital Date',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.accentPink, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          dateDisplay,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const Text('Change Date', style: TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Available Time Slots
            const Text(
              'Available Clinic Time Slots',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            if (_isLoadingSlots)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_slotErrorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _slotErrorMessage!,
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                ),
              )
            else if (_slots.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No slots available for this date. Please pick another date.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _slots.length,
                itemBuilder: (ctx, idx) {
                  final s = _slots[idx];
                  final isSelected = _selectedSlot == s.slotTime;

                  return InkWell(
                    onTap: s.isAvailable ? () => setState(() => _selectedSlot = s.slotTime) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: !s.isAvailable
                            ? Colors.grey.shade100
                            : isSelected
                                ? AppColors.accentPink.withOpacity(0.12)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentPink
                              : !s.isAvailable
                                  ? Colors.grey.shade300
                                  : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.slotTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !s.isAvailable ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.isAvailable ? '${s.remaining} slots left' : 'Fully booked',
                            style: TextStyle(
                              fontSize: 11,
                              color: !s.isAvailable ? Colors.red.shade400 : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // Additional Notes
            const Text(
              'Notes or Medical Considerations (Optional)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Bringing latest lab results, breastfeeding inquiry...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 28),

            CustomButton(
              text: 'Confirm & Book Appointment',
              isLoading: _isSubmitting,
              onPressed: _submitBooking,
            ),
          ],
        ),
      ),
    );
  }
}
