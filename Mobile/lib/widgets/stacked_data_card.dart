import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DataFieldItem {
  final String label;
  final String value;
  final Widget? customValue;
  final Color? valueColor;

  DataFieldItem({
    required this.label,
    required this.value,
    this.customValue,
    this.valueColor,
  });
}

class StackedDataCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? statusBadge;
  final List<DataFieldItem> fields;
  final bool isArchived;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  final VoidCallback? onGenerateClaimToken;
  final VoidCallback? onUpdateStatus;
  final String? statusActionLabel;

  const StackedDataCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.statusBadge,
    required this.fields,
    this.isArchived = false,
    this.onEdit,
    this.onArchive,
    this.onRestore,
    this.onDelete,
    this.onGenerateClaimToken,
    this.onUpdateStatus,
    this.statusActionLabel,
  }) : super(key: key);

  @override
  State<StackedDataCard> createState() => _StackedDataCardState();
}

class _StackedDataCardState extends State<StackedDataCard> {
  bool _isExpanded = false;

  Widget _buildFieldRow(DataFieldItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              item.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: item.customValue ??
                Text(
                  item.value.isNotEmpty ? item.value : '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: item.valueColor ?? AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If more than 5 fields, display the 3 most critical summary points on main card
    final hasOverflow = widget.fields.length > 5;
    final primaryFields = hasOverflow ? widget.fields.take(3).toList() : widget.fields;
    final secondaryFields = hasOverflow ? widget.fields.skip(3).toList() : <DataFieldItem>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isArchived ? AppColors.warning.withOpacity(0.4) : AppColors.border,
          width: widget.isArchived ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Status Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.statusBadge != null) widget.statusBadge!,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Primary Fields (3 critical points if >5 fields)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: primaryFields.map(_buildFieldRow).toList(),
            ),
          ),

          // Accordion: Secondary Fields smoothly expanded
          if (hasOverflow)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.pinkTint, // Soft blue tint
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    ...secondaryFields.map(_buildFieldRow),
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),

          // Toggle & Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: const Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                // "View More" / "View Less" Accordion Button
                if (hasOverflow)
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'View Less' : 'View More',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.primaryNavy,
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Action Buttons (CRUD + Archive/Restore)
                if (!widget.isArchived) ...[
                  if (widget.onGenerateClaimToken != null)
                    IconButton(
                      icon: const Icon(Icons.vpn_key_outlined, size: 20, color: AppColors.primaryBlue),
                      tooltip: 'Generate Claim Token',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onGenerateClaimToken,
                    ),
                  if (widget.onUpdateStatus != null)
                    IconButton(
                      icon: const Icon(Icons.rule_outlined, size: 20, color: AppColors.primaryNavy),
                      tooltip: widget.statusActionLabel ?? 'Review Screening Status',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onUpdateStatus,
                    ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryNavy),
                      tooltip: 'Edit Record',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onEdit,
                    ),
                  if (widget.onArchive != null)
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, size: 20, color: AppColors.warning),
                      tooltip: 'Soft Delete / Archive',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onArchive,
                    ),
                ] else ...[
                  if (widget.onRestore != null)
                    IconButton(
                      icon: const Icon(Icons.unarchive_outlined, size: 20, color: AppColors.success),
                      tooltip: 'Restore Record',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onRestore,
                    ),
                ],
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    tooltip: 'Permanent Delete',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

