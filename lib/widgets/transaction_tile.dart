import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:expensetracker_reloaded/utils/money.dart';
import 'package:expensetracker_reloaded/widgets/transaction_actions.dart';

/// List tile for one transaction, used on Home, Activity and Insights.
/// Tap = edit, long-press = Edit/Delete menu (when the row has an 'id').
class TransactionTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> transaction;
  final int index;
  final bool compact;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.index,
    this.compact = false,
  });

  @override
  ConsumerState<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends ConsumerState<TransactionTile> {
  bool _isPressed = false;

  // Colour encodes direction only (bug #17): every expense uses the same red,
  // every income the same teal. Both come from the original tile palette.
  static const debitColor = Color(0xFFFF6B6B);
  static const creditColor = Color(0xFF4ECDC4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCredit = widget.transaction['type'] == 'credit';
    final tileColor = isCredit ? creditColor : debitColor;
    final hasId = widget.transaction['id'] != null;
    final amountMinor =
        widget.transaction['amountMinor'] as int? ??
        Money.toMinor(widget.transaction['amount'] as num);
    final rawTitle = (widget.transaction['message'] ?? '').toString().trim();
    final title = rawTitle.isNotEmpty
        ? rawTitle
        : (isCredit ? 'Income' : 'Expense');

    return GestureDetector(
      onTap: hasId
          ? () => editTransaction(context, ref, widget.transaction)
          : null,
      onLongPress: hasId
          ? () => showTransactionActions(context, ref, widget.transaction)
          : null,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: EdgeInsets.only(bottom: widget.compact ? 8 : 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? tileColor.withValues(alpha: 0.15)
                : tileColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
            border: Border.all(
              color: tileColor.withValues(alpha: isDark ? 0.3 : 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(widget.compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: tileColor.withValues(alpha: isDark ? 0.3 : 0.15),
                  shape: widget.compact ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: widget.compact
                      ? BorderRadius.circular(10)
                      : null,
                ),
                child: Icon(
                  isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: tileColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: widget.compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(
                        DateTime.parse(widget.transaction['time'].toString()),
                      ),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Money.minor(
                  isCredit ? amountMinor : -amountMinor,
                  signed: true,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: tileColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
