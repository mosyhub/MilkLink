import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class RecordInfoLine {
  final IconData icon;
  final String text;

  const RecordInfoLine({
    required this.icon,
    required this.text,
  });
}

class RecordDetailField {
  final String label;
  final String value;
  final Color? valueColor;

  const RecordDetailField({
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class RecordCard extends StatefulWidget {
  final String title;
  final String? statusChipText;
  final List<RecordInfoLine> infoLines;
  final List<Widget>? extraChips;
  final List<RecordDetailField>? detailFields;
  final bool isArchived;
  final VoidCallback? onKeyAction;
  final String? keyActionTooltip;
  final VoidCallback? onChecklistAction;
  final String? checklistActionTooltip;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  const RecordCard({
    super.key,
    required this.title,
    this.statusChipText,
    required this.infoLines,
    this.extraChips,
    this.detailFields,
    this.isArchived = false,
    this.onKeyAction,
    this.keyActionTooltip,
    this.onChecklistAction,
    this.checklistActionTooltip,
    this.onEdit,
    this.onArchive,
    this.onRestore,
    this.onDelete,
  });

  @override
  State<RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<RecordCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasActions = widget.onKeyAction != null ||
        widget.onChecklistAction != null ||
        widget.onEdit != null ||
        widget.onArchive != null ||
        widget.onRestore != null ||
        widget.onDelete != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name and ONE status chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
              ),
              if (widget.statusChipText != null && widget.statusChipText!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.statusChipText!,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Row 2+: Info lines with 16px outlined leading icons
          for (final line in widget.infoLines)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(line.icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Other chips (Claimed, Eligibility, etc.)
          if (widget.extraChips != null && widget.extraChips!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.extraChips!,
            ),
          ],

          // View More / View Less Expandable Section
          if (widget.detailFields != null && widget.detailFields!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'View less' : 'View more',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: widget.detailFields!.map((df) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 125,
                                child: Text(
                                  df.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  df.value.isNotEmpty ? df.value : '—',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: df.valueColor ?? AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],

          // Action Buttons: bottom-right icon row
          if (hasActions) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onKeyAction != null)
                  _buildActionButton(
                    icon: Icons.vpn_key_outlined,
                    tooltip: widget.keyActionTooltip ?? 'Claim Token',
                    color: AppColors.primaryNavy,
                    onPressed: widget.onKeyAction!,
                  ),
                if (widget.onChecklistAction != null)
                  _buildActionButton(
                    icon: Icons.assignment_turned_in_outlined,
                    tooltip: widget.checklistActionTooltip ?? 'Review Status',
                    color: AppColors.primaryNavy,
                    onPressed: widget.onChecklistAction!,
                  ),
                if (widget.onEdit != null)
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit',
                    color: AppColors.primaryNavy,
                    onPressed: widget.onEdit!,
                  ),
                if (widget.onArchive != null)
                  _buildActionButton(
                    icon: Icons.archive_outlined,
                    tooltip: 'Archive',
                    color: AppColors.primaryNavy,
                    onPressed: widget.onArchive!,
                  ),
                if (widget.onRestore != null)
                  _buildActionButton(
                    icon: Icons.unarchive_outlined,
                    tooltip: 'Restore',
                    color: AppColors.primaryNavy,
                    onPressed: widget.onRestore!,
                  ),
                if (widget.onDelete != null)
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    color: AppColors.error,
                    onPressed: widget.onDelete!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        onPressed: onPressed,
      ),
    );
  }
}
