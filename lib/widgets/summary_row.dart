import 'package:flutter/material.dart';
import 'package:expensetracker_reloaded/utils/money.dart';

/// Label/amount row used in summary cards.
class SummaryRow extends StatelessWidget {
  final String label;

  /// Amount in minor units (paise). Formatted with [Money.minor].
  final int amountMinor;

  /// Show "+"/"-" (used for net values, bug #3).
  final bool signed;
  final IconData icon;
  final Color color;

  const SummaryRow({
    required this.label,
    required this.amountMinor,
    this.signed = false,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style:
                Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500) ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          Money.minor(amountMinor, signed: signed),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
