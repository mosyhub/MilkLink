import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_widgets.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../models/milk_request_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class DonorMilkRequestScreen extends StatefulWidget {
  const DonorMilkRequestScreen({Key? key}) : super(key: key);

  @override
  State<DonorMilkRequestScreen> createState() => _DonorMilkRequestScreenState();
}

class _DonorMilkRequestScreenState extends State<DonorMilkRequestScreen> {
  final _recipientNameController = TextEditingController();
  final _volumeController = TextEditingController(text: '500');
  final _durationController = TextEditingController(text: '7');
  final _reasonController = TextEditingController();
  final _hospitalController = TextEditingController(text: 'Pasig City General Hospital (PCGH)');
  final _remarksController = TextEditingController();

  String _relation = 'Mother / Guardian';
  bool _isSubmitting = false;
  bool _isLoadingRequests = true;
  List<MilkRequestModel> _myRequests = [];

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    try {
      final response = await ApiClient.get(ApiConstants.myMilkRequests);
      if (!mounted) return;
      final requests = response is Map && response['requests'] is List
          ? (response['requests'] as List)
              .whereType<Map>()
              .map((item) => MilkRequestModel.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <MilkRequestModel>[];
      setState(() {
        _myRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _volumeController.dispose();
    _durationController.dispose();
    _reasonController.dispose();
    _hospitalController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_recipientNameController.text.trim().isEmpty ||
        _volumeController.text.trim().isEmpty ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields (recipient name, volume, reason).')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiClient.post(
        '${ApiConstants.baseUrl}/donor/request-milk',
        data: {
          'recipientName': _recipientNameController.text.trim(),
          'relationToRecipient': _relation,
          'volumeRequested': double.tryParse(_volumeController.text.trim()) ?? 500,
          'feedingDurationDays': int.tryParse(_durationController.text.trim()) ?? 7,
          'reasonForRequest': _reasonController.text.trim(),
          'hospitalOrHomeAddress': _hospitalController.text.trim(),
          'additionalRemarks': _remarksController.text.trim(),
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.assignment_turned_in, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text('Request Submitted'),
              ],
            ),
            content: const Text(
              'Your request for pasteurized human milk has been routed to authorized Pasig City Human Milk Bank clinical personnel for review and dispensing evaluation.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppTopBar(title: 'Request Human Milk'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All milk requests require medical assessment by authorized staff. Registered donors are not automatically approved without clinical justification.',
                      style: TextStyle(fontSize: 12, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingRequests)
              const Center(child: CircularProgressIndicator())
            else if (_myRequests.isNotEmpty) ...[
              const Text(
                'My Milk Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ..._myRequests.map(_buildRequestSummary),
              const SizedBox(height: 8),
            ],
            CustomTextField(
              label: 'Infant / Recipient Full Name *',
              controller: _recipientNameController,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _relation,
              decoration: const InputDecoration(labelText: 'Relationship to Infant'),
              items: const [
                DropdownMenuItem(value: 'Mother / Guardian', child: Text('Mother / Guardian')),
                DropdownMenuItem(value: 'Father', child: Text('Father')),
                DropdownMenuItem(value: 'Healthcare Provider', child: Text('Healthcare Provider')),
                DropdownMenuItem(value: 'Relative / Foster', child: Text('Relative / Foster')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _relation = v);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Volume Needed (mL) *',
                    controller: _volumeController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Duration (Days)',
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Medical Indication / Reason for Request *',
              controller: _reasonController,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Hospital / Admitting Unit / Home Address *',
              controller: _hospitalController,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Physician / Additional Remarks',
              controller: _remarksController,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit Milk Request',
              isLoading: _isSubmitting,
              onPressed: _submitRequest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSummary(MilkRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.requestNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(request.recipientName, style: const TextStyle(color: AppColors.textSecondary)),
                Text(request.formattedDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Chip(
            label: Text(request.status),
            labelStyle: const TextStyle(fontSize: 11),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
