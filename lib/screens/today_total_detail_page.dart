import 'package:flutter/material.dart';

class TodayTotalDetailPage extends StatelessWidget {
  final double total;

  const TodayTotalDetailPage({super.key, required this.total});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: null,
        // AppBar(
        //   automaticallyImplyLeading: false,
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   iconTheme: IconThemeData(
        //     color: Theme.of(context).brightness == Brightness.dark
        //       ? const Color(0xFF121212)
        //       : Colors.white,
        //   ),
        // ),
        body: Center(
          child: Hero(
            tag: 'today-total-card',
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's Total",
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).secondaryHeaderColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).secondaryHeaderColor,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tap anywhere\nto go back',
                      style: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor,
                        fontSize: 14,
                      ),textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
