import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donor_model.dart';
import '../../widgets/app_widgets.dart';

class MilkStatusTrackingScreen extends StatelessWidget {
  final DonationRecord? donation;

  const MilkStatusTrackingScreen({Key? key, this.donation}) : super(key: key);

  static const List<String> stages = [
    'Collected',
    'For Inspection',
    'For Processing',
    'Pasteurized',
    'Quality-Control Review',
    'Available for Dispensing',
    'Dispensed',
  ];

  int _getCurrentStageIndex() {
    if (donation == null) return 0;
    final status = donation!.donationType; // or status
    // Map status string to stage
    final idx = stages.indexWhere((s) => s.toLowerCase() == status.toLowerCase());
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _getCurrentStageIndex();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppTopBar(title: 'Milk Processing Progress'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        donation?.eventTitle ?? 'Donated Milk Batch',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          donation != null ? '${donation!.totalVolume.toStringAsFixed(0)} mL' : 'Sample / Active Batch',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tracking ID: ${donation?.id ?? "BATCH-ACTIVE"}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Traceability Milestone Timeline',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Follow your breast milk donation from collection to dispensing.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...List.generate(stages.length, (i) {
              final stageName = stages[i];
              final isPassed = i <= currentIdx;
              final isCurrent = i == currentIdx;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPassed ? AppColors.primaryBlue : Colors.grey.shade200,
                          border: isCurrent
                              ? Border.all(color: AppColors.primaryNavy, width: 2)
                              : null,
                        ),
                        child: Icon(
                          isPassed ? Icons.check : Icons.circle,
                          color: isPassed ? Colors.white : Colors.grey,
                          size: 16,
                        ),
                      ),
                      if (i < stages.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: i < currentIdx ? AppColors.primaryBlue : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stageName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isPassed ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          if (stageName == 'Pasteurized')
                            const Text(
                              'Holder pasteurization completed at 62.5°C for 30 minutes.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          if (stageName == 'Quality-Control Review')
                            const Text(
                              'Microbiological culture testing before release.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
