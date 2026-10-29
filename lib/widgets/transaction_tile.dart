import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatefulWidget {
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
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _isPressed = false;

  static const List<Color> _palette = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFD6BE43),
    Color(0xFF95E1D3),
    Color(0xFFF38181),
    Color(0xFFAA96DA),
    Color(0xFFFCBD49),
    Color(0xFF5DADE2),
  ];

  Color _color() {
    if (widget.compact) {
      final hash = widget.transaction['time'].hashCode;
      return _palette[hash.abs() % _palette.length];
    }
    return _palette[widget.index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileColor = _color();
    final isCredit = widget.transaction['type'] == 'credit';

    return GestureDetector(
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
                  borderRadius:
                      widget.compact ? BorderRadius.circular(10) : null,
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
                      widget.transaction['message'] ?? 'Expense',
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
                '${isCredit ? '+' : '-'}₹${(widget.transaction['amount'] as num).toStringAsFixed(2)}',
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
