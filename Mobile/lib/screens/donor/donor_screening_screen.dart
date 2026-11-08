import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class DonorScreeningScreen extends StatefulWidget {
  const DonorScreeningScreen({Key? key}) : super(key: key);

  @override
  State<DonorScreeningScreen> createState() => _DonorScreeningScreenState();
}

class _DonorScreeningScreenState extends State<DonorScreeningScreen> {
  int _currentStep = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1: Mother Personal info
  final _streetController = TextEditingController();
  final _brgyController = TextEditingController();
  final _cityController = TextEditingController(text: 'Pasig City');
  DateTime? _motherBirthday;
  String _donorType = 'Community';

  // Step 2: Child info
  final _childNameController = TextEditingController();
  final _birthWeightController = TextEditingController();
  DateTime? _childBirthday;

  // Step 3: Medical Questionnaire
  final Map<String, String> _questionnaire = {
    "Have you donated breast milk before? (Nakapagbigay ka na ba ng iyong gatas dati?)": "No",
    "Will you be allowed by your husband to donate your breast milk to the Pasig City Human Milk Bank? (Papayagan ka ba ng iyong asawa na magbigay ng iyong gatas sa Pasig City Human Milk Bank?)": "Yes",
    "Have you for any reason been deferred as a milk donor? (Ikaw ba ay natangihan na magbigay ng iyong gatas / breastmilk?)": "No",
    "Did you have a normal pregnancy and delivery for your most recent pregnancy? (Normal ba ang panganganak mo sa huli mong anak?)": "Yes",
    "Do you have any acute or chronic infection, systemic disorders, tuberculosis or history of hepatitis? (Mayroon ka bang kahit anong impeksyon o sakit? Nagkaroon ng sakit sa atay dati?)": "No",
    "Have you received any blood transfusion or other blood products within the last 12 months? (Ikaw ba ay nasalinan ng dugo o kahit anong produkto mula sa dugo nitong nakaraang 12 buwan?)": "No",
    "Within the last 24 hours, have you had intake of any hard liquor or alcohol? (Nakainom ka ba ng alak nitong nakaraang 24 oras?)": "No",
    "Do you regularly use over-the-counter medications or systemic preparations such as replacement hormones and some birth control hormones? (Regular ka bang gumagamit ng mga gamot gaya ng mga hormones o pills?)": "No",
    "Do you smoke? (Ikaw ba ay naninigarilyo?)": "No",
    "Is your child healthy? (Malusog ba ang iyong anak?)": "Yes",
    "Was your child delivered full term? (Ipinanganak ba ang anak mo na husto sa buwan?)": "Yes",
    "Are you exclusively breastfeeding your child? (Purong gatas mo ba ang binibigay mo sa anak mo at walang halong ibang formula / gatas?)": "Yes",
  };

  @override
  void dispose() {
    _streetController.dispose();
    _brgyController.dispose();
    _cityController.dispose();
    _childNameController.dispose();
    _birthWeightController.dispose();
    super.dispose();
  }

  Future<void> _submitScreening() async {
    if (_motherBirthday == null || _childBirthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both your birthday and child\'s birthday.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final donorProvider = Provider.of<DonorProvider>(context, listen: false);
    final success = await donorProvider.submitScreeningApplication(
      street: _streetController.text.trim(),
      brgy: _brgyController.text.trim(),
      city: _cityController.text.trim(),
      birthday: _motherBirthday!,
      donorType: _donorType,
      childName: _childNameController.text.trim(),
      childBirthday: _childBirthday!,
      birthWeight: _birthWeightController.text.trim(),
      questionnaireAnswers: _questionnaire,
    );

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Application Received'),
            ],
          ),
          content: const Text(
            'Your donor screening application has been submitted successfully! Pasig City Human Milk Bank staff will review your answers.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(donorProvider.errorMessage ?? 'Submission failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Donor Screening Questionnaire'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        elevation: 0,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('Mother'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildMotherInfoStep(),
          ),
          Step(
            title: const Text('Child'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildChildInfoStep(),
          ),
          Step(
            title: const Text('Health'),
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.indexed : StepState.complete,
            content: _buildMedicalQuestionsStep(donorProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildMotherInfoStep() {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Mother\'s Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Street Address *',
            hint: 'e.g. 123 Sampaguita St.',
            controller: _streetController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Barangay *',
            hint: 'e.g. Fort Bonifacio / Ususan',
            controller: _brgyController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'City *',
            controller: _cityController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          const Text(
            'Date of Birth *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000, 1, 1),
                firstDate: DateTime(1960),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _motherBirthday = picked);
            },
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
                  Text(
                    _motherBirthday != null
                        ? DateFormat('MMMM d, yyyy').format(_motherBirthday!)
                        : 'Select Birthday',
                    style: TextStyle(
                      color: _motherBirthday != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Donor Category *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _donorType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Community', child: Text('Community Donor')),
                  DropdownMenuItem(value: 'Private', child: Text('Private Donor')),
                  DropdownMenuItem(value: 'Employee', child: Text('Pasig City Employee')),
                  DropdownMenuItem(value: 'Network Office/Agency', child: Text('Network Office/Agency')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _donorType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Next: Child Information',
            onPressed: () {
              if (_formKey1.currentState!.validate()) {
                if (_motherBirthday == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your birthday'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                setState(() => _currentStep = 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChildInfoStep() {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Youngest Child Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Child\'s Name *',
            hint: 'e.g. Baby Gabriel',
            controller: _childNameController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Birth Weight (kg/lbs) *',
            hint: 'e.g. 3.2 kg',
            controller: _birthWeightController,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          const Text(
            'Child\'s Date of Birth *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _childBirthday = picked);
            },
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
                  Text(
                    _childBirthday != null
                        ? DateFormat('MMMM d, yyyy').format(_childBirthday!)
                        : 'Select Birthday',
                    style: TextStyle(
                      color: _childBirthday != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Back',
                  isOutlined: true,
                  onPressed: () => setState(() => _currentStep = 0),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CustomButton(
                  text: 'Next: Health',
                  onPressed: () {
                    if (_formKey2.currentState!.validate()) {
                      if (_childBirthday == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select child\'s birthday'), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      setState(() => _currentStep = 2);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalQuestionsStep(DonorProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Medical & Lifestyle Questionnaire',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please answer truthfully to ensure the safety of premature and vulnerable infants.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ..._questionnaire.keys.map((question) {
          final currentVal = _questionnaire[question];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Yes'),
                      selected: currentVal == 'Yes',
                      selectedColor: AppColors.accentPink.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _questionnaire[question] = 'Yes'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('No'),
                      selected: currentVal == 'No',
                      selectedColor: AppColors.primaryNavy.withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _questionnaire[question] = 'No'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Back',
                isOutlined: true,
                onPressed: () => setState(() => _currentStep = 1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomButton(
                text: 'Submit Application',
                isLoading: provider.status == DonorStatus.loading,
                backgroundColor: AppColors.accentPink,
                onPressed: _submitScreening,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

