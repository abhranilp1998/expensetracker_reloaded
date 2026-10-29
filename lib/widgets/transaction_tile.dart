import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final int index;

  const TransactionTile({
    required this.transaction,
    required this.index,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool _isPressed = false;

  // Alternating color palette for transactions
  static const List<Color> _transactionColors = [
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color.fromARGB(255, 214, 190, 67), // Yellow
    Color(0xFF95E1D3), // Mint
    Color(0xFFF38181), // Pink
    Color(0xFFAA96DA), // Purple
    Color(0xFFFCBD49), // Gold
    Color(0xFF5DADE2), // Blue
  ];

  Color _getBackgroundColor(int index) {
    return _transactionColors[index % _transactionColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = _getBackgroundColor(widget.index);
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? tileColor.withValues(alpha: 0.15)
                : tileColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tileColor.withValues(alpha: isDark ? 0.3 : 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tileColor.withValues(alpha: isDark ? 0.3 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_downward,
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
                        color: isDark 
                          ? Colors.white
                          : Colors.grey.shade900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('hh:mm a').format(
                        DateTime.parse(widget.transaction['time'].toString()),
                      ),
                      style: TextStyle(
                        color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.transaction['type'] == 'credit' ? '+' : '-'}₹${widget.transaction['amount'].toStringAsFixed(2)}',
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
