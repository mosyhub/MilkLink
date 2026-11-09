import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_text_field.dart';
import 'returning_donor_search_screen.dart';

class DonorRegistrationScreen extends StatefulWidget {
  const DonorRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<DonorRegistrationScreen> createState() => _DonorRegistrationScreenState();
}

class _DonorRegistrationScreenState extends State<DonorRegistrationScreen> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Personal Info
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _occupationController = TextEditingController();
  final _streetController = TextEditingController();
  final _brgyController = TextEditingController();
  final _cityController = TextEditingController(text: 'Pasig City');
  DateTime? _birthday;
  String _donorType = 'Community';

  // Breastfeeding / Infant info
  final _childNameController = TextEditingController();
  final _birthWeightController = TextEditingController();
  final _breastfeedingInfoController = TextEditingController();
  DateTime? _childBirthday;

  // Screening questions (Initial)
  final Map<String, String> _questionnaire = {
    "Have you donated breast milk before? (Nakapagbigay ka na ba ng gatas dati?)": "No",
    "Did you have normal pregnancy and delivery? (Normal ba ang panganganak mo?)": "Yes",
    "Are you in good health and without infectious disorders? (Malusog at walang impeksyon?)": "Yes",
    "Are you exclusively breastfeeding your infant? (Purong gatas mo ba ang binibigay mo?)": "Yes",
    "Are you taking any prohibited medications, smoking, or drinking alcohol? (Umiinom o naninigarilyo?)": "No",
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _occupationController.dispose();
    _streetController.dispose();
    _brgyController.dispose();
    _cityController.dispose();
    _childNameController.dispose();
    _birthWeightController.dispose();
    _breastfeedingInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final result = await donorProvider.registerFirstTimeDonor(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthday: _birthday!,
      street: _streetController.text.trim(),
      brgy: _brgyController.text.trim(),
      city: _cityController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      occupation: _occupationController.text.trim(),
      donorType: _donorType,
      childName: _childNameController.text.trim(),
      childBirthday: _childBirthday,
      birthWeight: _birthWeightController.text.trim(),
      breastfeedingInfo: _breastfeedingInfoController.text.trim(),
      questionnaireAnswers: _questionnaire,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final donorId = result['donorId'] ?? 'Registered';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Registration Complete'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Pasig City Human Milk Bank (MilkLink)!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your Donor ID: $donorId',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Clear Next Steps:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text('1. Keep your Donor ID for all future donations.'),
              const Text('2. Returning donors never need to re-register.'),
              const Text('3. Submit lab requirements (CBC, HIV, HBsAg, Anti-HCV).'),
              const Text('4. Coordinate with milk bank staff or request home pickup.'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppTopBar(
        title: 'Donor Registration',
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReturningDonorSearchScreen()),
              );
            },
            icon: const Icon(Icons.repeat, size: 18, color: AppColors.primaryBlue),
            label: const Text(
              'Returning?',
              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_formKey1.currentState!.validate()) {
              if (_birthday == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select your birthday')),
                );
                return;
              }
              setState(() => _currentStep += 1);
            }
          } else if (_currentStep == 1) {
            if (_formKey2.currentState!.validate()) {
              setState(() => _currentStep += 1);
            }
          } else {
            _submitRegistration();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        steps: [
          Step(
            title: const Text('Donor Info'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 1: First-Time Donor Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No Google account or email required. A permanent Donor ID will be created.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'First Name *',
                    controller: _firstNameController,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Middle Name (Optional)',
                    controller: _middleNameController,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Last Name *',
                    controller: _lastNameController,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Contact Number * (e.g. 09171234567)',
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _birthday == null
                          ? 'Select Date of Birth *'
                          : 'DOB: ${DateFormat('MMMM dd, yyyy').format(_birthday!)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1960),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _birthday = picked);
                      }
                    },
                  ),
                  const Divider(),
                  CustomTextField(
                    label: 'Street / House No. *',
                    controller: _streetController,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Barangay (e.g. San Nicolas, Pinagbuhatan) *',
                    controller: _brgyController,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'City',
                    controller: _cityController,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Occupation (Optional)',
                    controller: _occupationController,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _donorType,
                    decoration: const InputDecoration(labelText: 'Donor Classification'),
                    items: const [
                      DropdownMenuItem(value: 'Community', child: Text('Community Donor')),
                      DropdownMenuItem(value: 'Private', child: Text('Private Donor')),
                      DropdownMenuItem(value: 'Employee', child: Text('City/Hospital Employee')),
                      DropdownMenuItem(value: 'Network Office/Agency', child: Text('Partner Agency')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _donorType = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Infant Info'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 2: Breastfeeding & Child Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Child / Infant Name (Optional)',
                    controller: _childNameController,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _childBirthday == null
                          ? 'Select Infant Date of Birth (Optional)'
                          : 'Child DOB: ${DateFormat('MMMM dd, yyyy').format(_childBirthday!)}',
                    ),
                    trailing: const Icon(Icons.cake, color: AppColors.primaryBlue),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 60)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _childBirthday = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Birth Weight (e.g. 3.2 kg)',
                    controller: _birthWeightController,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Breastfeeding Notes / History',
                    controller: _breastfeedingInfoController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 3: Initial Questionnaire & Confirmation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ..._questionnaire.keys.map((q) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Yes'),
                                selected: _questionnaire[q] == 'Yes',
                                onSelected: (sel) {
                                  if (sel) setState(() => _questionnaire[q] = 'Yes');
                                },
                              ),
                              const SizedBox(width: 10),
                              ChoiceChip(
                                label: const Text('No'),
                                selected: _questionnaire[q] == 'No',
                                onSelected: (sel) {
                                  if (sel) setState(() => _questionnaire[q] = 'No');
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
