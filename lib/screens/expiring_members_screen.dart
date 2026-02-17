import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rv_fitness/models/customer.dart';
import 'package:rv_fitness/providers/customer_provider.dart';
import 'customer_detail_screen.dart';

import 'package:flutter_animate/flutter_animate.dart';

class ExpiringMembersScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E1E), // Brand dark
              Color(0xFF2D2D2D), // Brand dark gradient
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: _buildExpiringList(customersAsync),
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
            Color(0xFFD32F2F), // Red for urgency
            Color(0xFFC62828),
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
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Expiring Memberships',
                style: GoogleFonts.anton(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 40), // Balance
        ],
      ),
    );
  }

  Widget _buildExpiringList(AsyncValue<List<Customer>> customersAsync) {
    return customersAsync.when(
      data: (customers) {
        final today = DateTime.now();
        final expiringCustomers =
            customers.where((customer) {
              final isFuture = customer.endDate.isAfter(today);
              final daysLeft = customer.endDate.difference(today).inDays;
              return isFuture && daysLeft <= 7;
            }).toList();

        // Sort by closest expiry first
        expiringCustomers.sort((a, b) => a.endDate.compareTo(b.endDate));

        if (expiringCustomers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white.withOpacity(0.3),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No memberships expiring soon!',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: expiringCustomers.length,
          itemBuilder: (context, index) {
            final customer = expiringCustomers[index];
            final daysLeft = customer.endDate.difference(today).inDays;

            return _buildCustomerCard(context, customer, daysLeft, index);
          },
        );
      },
      loading:
          () => Center(
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
            ),
          ),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    Customer customer,
    int daysLeft,
    int index,
  ) {
    bool isExpired = daysLeft < 0;
    Color statusColor = isExpired ? Colors.red : Colors.orange;

    return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CustomerDetailScreen(customer: customer),
                  ),
                );
              },
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(
                backgroundColor: Color(0xFF6B46C1),
                child: Text(
                  customer.name[0],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                customer.name,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    'Expires: ${DateFormat.yMMMd().format(customer.endDate)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isExpired
                          ? 'Expired ${daysLeft.abs()} days ago'
                          : 'Expires in $daysLeft days',
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 300))
        .slideX(begin: 0.2, end: 0, delay: Duration(milliseconds: index * 50));
  }
}
