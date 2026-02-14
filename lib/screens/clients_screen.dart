import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_provider.dart';
import '../models/customer.dart';
import '../widgets/shimmer_loading.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_detail_screen.dart';
import 'edit_customer_screen.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  @override
  _ClientsScreenState createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _filter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
              _buildCustomAppBar(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      SizedBox(height: 16),
                      _buildFilterRow(),
                      SizedBox(height: 16),
                      Expanded(
                        child: _buildMembersList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFA500), // Brand Orange
            Color(0xFFFFD700), // Brand Yellow
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              SizedBox(width: 8),
              Text(
                'All Members',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFD700).withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFFFFA500).withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _filter,
        dropdownColor: Color(0xFF2C3E50),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        underline: SizedBox(),
        isExpanded: true,
        items: ['All', 'Active', 'Expired']
            .map((filter) => DropdownMenuItem(
                  value: filter,
                  child: Text(
                    filter,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (value) => setState(() => _filter = value!),
      ),
    );
  }

  Widget _buildMembersList() {
    final customersAsync = ref.watch(customersProvider);

    return customersAsync.when(
      data: (customers) => _buildClientsList(context, customers),
      loading: () => ShimmerLoading(),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildClientsList(BuildContext context, List<Customer> customers) {
    final filteredCustomers = customers.where((customer) {
      final matchesSearch =
          customer.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Active' && customer.endDate.isAfter(DateTime.now())) ||
          (_filter == 'Expired' && customer.endDate.isBefore(DateTime.now()));
      return matchesSearch && matchesFilter;
    }).toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = filteredCustomers[index];
        final isExpired = customer.endDate.isBefore(DateTime.now());

        return Hero(
          tag: 'customer-${customer.id}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFA500).withOpacity(0.15),
                    Color(0xFFFFD700).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isExpired
                      ? Color(0xFFFFA500).withOpacity(0.3)
                      : Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  customer.name,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: customer.trainingType == 'Personal'
                                ? Color(0xFFFFA500).withOpacity(0.2)
                                : Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            customer.trainingType,
                            style: GoogleFonts.poppins(
                              color: customer.trainingType == 'Personal'
                                  ? Color(0xFFFFA500)
                                  : Color(0xFFFFD700),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? Color(0xFFFFA500).withOpacity(0.2)
                                : Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isExpired ? 'Expired' : 'Active',
                            style: GoogleFonts.poppins(
                              color: isExpired
                                  ? Color(0xFFFFA500)
                                  : Color(0xFFFFD700),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ends: ${DateFormat.yMMMd().format(customer.endDate)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IconButton(
                    //   icon: Icon(Icons.history, color: Colors.green),
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) =>
                    //             AttendanceHistoryScreen(customer: customer),
                    //       ),
                    //     );
                    //   },
                    // ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditCustomerScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, customer.id),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerDetailScreen(customer: customer),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String customerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Color(0xFF2C3E50),
        title: Text(
          'Delete Member',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this member? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(firebaseServiceProvider)
                  .deleteCustomer(customerId);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
