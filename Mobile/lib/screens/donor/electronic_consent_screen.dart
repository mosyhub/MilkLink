import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ElectronicConsentScreen extends StatefulWidget {
  const ElectronicConsentScreen({Key? key}) : super(key: key);

  @override
  State<ElectronicConsentScreen> createState() => _ElectronicConsentScreenState();
}

class _ElectronicConsentScreenState extends State<ElectronicConsentScreen> {
  bool _acknowledged = false;
  final _signerNameController = TextEditingController();
  final List<Offset?> _points = [];
  bool _isSubmitting = false;

  final String _consentText = '''
PASIG CITY HUMAN MILK BANK - ELECTRONIC DONOR CONSENT (DEDE1)

1. I voluntarily agree to donate my excess breast milk to the Pasig City Human Milk Bank (MilkLink).
2. I certify that all personal, health, and medical information provided in my screening questionnaire is true and accurate.
3. I authorize the milk bank staff and designated healthcare personnel to review my laboratory test records (CBC, HIV, HBsAg, Anti-HCV) and use them solely for donation eligibility evaluation.
4. I understand that my donated breast milk will undergo inspection, pasteurization, microbiological testing, and quality control review before being dispensed to vulnerable infants.
5. I understand that this donation is altruistic and free of charge, with no financial compensation.
6. In compliance with the Data Privacy Act of 2012 (R.A. 10173), I understand that my personal information will remain confidential and protected.
''';

  @override
  void dispose() {
    _signerNameController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    setState(() => _points.clear());
  }

  Future<void> _submitConsent() async {
    if (!_acknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check the acknowledgment box before submitting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_signerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full legal name as signer.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_points.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign on the electronic signature pad.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final donorProvider = Provider.of<DonorProvider>(context, listen: false);
      final donorId = donorProvider.donor?.id;

      // Simulated signature data URL
      final signatureDataUrl = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="300" height="150"><text x="10" y="80" font-family="cursive" font-size="28">${Uri.encodeComponent(_signerNameController.text.trim())}</text></svg>';

      final response = await ApiClient.post(
        '${ApiConstants.baseUrl}/consent/sign',
        data: {
          if (donorId != null) 'donorId': donorId,
          'acknowledged': true,
          'signerName': _signerNameController.text.trim(),
          'signatureDataUrl': signatureDataUrl,
          'consentVersion': '1.0',
        },
        requiresAuth: true,
      );

      if (response['success'] == true) {
        await donorProvider.fetchMyDonorProfile();
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.success),
                SizedBox(width: 8),
                Text('Consent Recorded'),
              ],
            ),
            content: const Text(
              'Your electronic consent has been signed, timestamped, and linked to your Pasig City Human Milk Bank donor record.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Electronic Consent Form'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Official DEDE1 Electronic Donor Consent',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _consentText,
                  style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Checkbox(
                  value: _acknowledged,
                  activeColor: AppColors.accentPink,
                  onChanged: (val) => setState(() => _acknowledged = val ?? false),
                ),
                const Expanded(
                  child: Text(
                    'I have read, understood, and voluntarily agree to the complete DEDE1 electronic consent terms.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Full Legal Signer Name *',
              controller: _signerNameController,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Electronic Signature Pad (Draw with Touch / Mouse):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: _clearSignature,
                  child: const Text('Clear Pad', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: GestureDetector(
                onPanUpdate: (DragUpdateDetails details) {
                  setState(() {
                    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      _points.add(details.localPosition);
                    }
                  });
                },
                onPanEnd: (DragEndDetails details) => _points.add(null),
                child: CustomPaint(
                  painter: _SignaturePainter(points: _points),
                  size: Size.infinite,
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Sign and Submit Consent',
              isLoading: _isSubmitting,
              onPressed: _submitConsent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppColors.primaryNavy
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => oldDelegate.points != points;
}
