import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rv_fitness/models/attendence.dart';
import 'package:rv_fitness/models/customer.dart';
import 'package:rv_fitness/providers/attendence_provider.dart';
import 'package:rv_fitness/providers/customer_provider.dart';
import 'package:rv_fitness/widgets/shimmer_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rv_fitness/screens/attendence_history_screen.dart';

class AttendanceDashboardScreen extends ConsumerStatefulWidget {
  @override
  _AttendanceDashboardScreenState createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState
    extends ConsumerState<AttendanceDashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceByDateProvider(_selectedDate));
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
              _buildCustomAppBar(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDateSelector(),
                      SizedBox(height: 20),
                      _buildStatsCard(attendanceAsync),
                      SizedBox(height: 20),
                      Expanded(
                        child: _buildAttendanceList(
                          attendanceAsync,
                          customersAsync,
                        ),
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
            Color(0xFFFFB81C), // Brand Gold
            Color(0xFFF29100), // Brand Gold Gradient
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
                'Attendance Dashboard',
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

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Color(0xFFFFB81C)),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(Duration(days: 1));
              });
            },
          ),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: Color(0xFFFFB81C),
                        onPrimary: Colors.black,
                        surface: Color(0xFF2C3E50),
                        onSurface: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  DateFormat.yMMMEd().format(_selectedDate),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color:
                  _isToday(_selectedDate)
                      ? Colors.white.withOpacity(0.3)
                      : Color(0xFFFFB81C),
            ),
            onPressed:
                _isToday(_selectedDate)
                    ? null
                    : () {
                      setState(() {
                        _selectedDate = _selectedDate.add(Duration(days: 1));
                      });
                    },
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildStatsCard(AsyncValue<List<Attendance>> attendanceAsync) {
    return attendanceAsync.when(
      data: (attendance) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFB81C).withOpacity(0.2),
                Color(0xFFF29100).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFFFFB81C).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Present', '${attendance.length}'),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              _buildStatItem('Date', DateFormat.MMMd().format(_selectedDate)),
            ],
          ),
        );
      },
      loading: () => SizedBox(height: 120, child: ShimmerLoading()),
      error: (_, __) => SizedBox.shrink(),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.anton(
            color: Color(0xFFFFB81C),
            fontSize: 32,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList(
    AsyncValue<List<Attendance>> attendanceAsync,
    AsyncValue<List<Customer>> customersAsync,
  ) {
    return attendanceAsync.when(
      data: (attendance) {
        if (attendance.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  color: Colors.white.withOpacity(0.3),
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'No attendance records found',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return customersAsync.when(
          data: (customers) {
            return ListView.builder(
              itemCount: attendance.length,
              itemBuilder: (context, index) {
                final record = attendance[index];
                // Find customer details
                // Find customer details
                final matchingCustomers = customers.where(
                  (c) => c.id == record.customerId,
                );

                if (matchingCustomers.isEmpty) return SizedBox.shrink();
                final customer = matchingCustomers.first;

                return _buildAttendanceCard(record, customer, index);
              },
            );
          },
          loading: () => ShimmerLoading(),
          error: (e, s) => Text('Error loading customers'),
        );
      },
      loading: () => ShimmerLoading(),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAttendanceCard(Attendance record, Customer customer, int index) {
    return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context, // Using closure context is fine here as it captures build context or use parent context
                MaterialPageRoute(
                  builder: (_) => AttendanceHistoryScreen(customer: customer),
                ),
              );
            },
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            subtitle: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                SizedBox(width: 4),
                Text(
                  DateFormat.jm().format(record.timestamp),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFFFB81C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFFFFB81C).withOpacity(0.3)),
              ),
              child: Text(
                'Present',
                style: GoogleFonts.poppins(
                  color: Color(0xFFFFB81C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 150))
        .slideX(begin: 0.2, end: 0, delay: Duration(milliseconds: index * 50));
  }
}
