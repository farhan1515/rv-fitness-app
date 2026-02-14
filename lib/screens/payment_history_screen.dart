import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/revenue_history.dart';
import '../services/firebase_service.dart';
import '../providers/firebase_provider.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const PaymentHistoryScreen({
    required this.customerId,
    required this.customerName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E1E),
              Color(0xFF2D2D2D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: FutureBuilder<List<RevenueHistory>>(
                  future: ref
                      .read(firebaseServiceProvider)
                      .getCustomerRevenueHistory(customerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFFFB81C)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text('No transactions found.',
                            style: TextStyle(color: Colors.white70)),
                      );
                    }
                    return ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        SizedBox(height: 8),
                        ...snapshot.data!.map((tx) => Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (tx.paymentType == 'renewal'
                                            ? Color(0xFFFFB81C)
                                            : Color(0xFF4CAF50))
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    tx.paymentType == 'renewal'
                                        ? Icons.refresh
                                        : Icons.person_add,
                                    color: tx.paymentType == 'renewal'
                                        ? Color(0xFFFFB81C)
                                        : Color(0xFF4CAF50),
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  tx.paymentType == 'renewal'
                                      ? 'Renewal'
                                      : 'New Membership',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  '₹${tx.amount.toStringAsFixed(0)} • ${DateFormat('MMM d, yyyy').format(tx.paymentDate)}',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFA500),
            Color(0xFFFFD700),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: 8),
              Text(
                'Payment History',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payment,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
