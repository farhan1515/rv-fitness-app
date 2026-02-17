import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rv_fitness/models/attendence.dart';
import 'package:rv_fitness/providers/attendence_provider.dart';

import 'package:table_calendar/table_calendar.dart';
import '../models/customer.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const AttendanceHistoryScreen({required this.customer});

  @override
  _AttendanceHistoryScreenState createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceProvider(widget.customer.id));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: attendanceAsync.when(
                  data: (attendance) => _buildBody(attendance),
                  loading:
                      () => Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFB81C),
                        ),
                      ),
                  error:
                      (error, _) => Center(
                        child: Text(
                          'Error: $error',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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
          colors: [Color(0xFFFFB81C), Color(0xFFF29100)],
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
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.customer.name}\'s History',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Attendance> attendance) {
    // Group attendance by date for calendar
    Map<DateTime, List<Attendance>> events = {};
    for (var record in attendance) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      if (events[date] == null) events[date] = [];
      events[date]!.add(record);
    }

    // Calculate stats
    final totalCheckins = attendance.length;
    final thisMonthCheckins =
        attendance
            .where(
              (a) =>
                  a.timestamp.month == DateTime.now().month &&
                  a.timestamp.year == DateTime.now().year,
            )
            .length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsRow(totalCheckins, thisMonthCheckins),
          SizedBox(height: 20),
          _buildCalendar(events),
          SizedBox(height: 20),
          _buildRecentLog(attendance),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int total, int thisMonth) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Days', '$total', Icons.history)),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'This Month',
            '$thisMonth',
            Icons.calendar_today,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFFFFB81C).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFFFFB81C), size: 28),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.anton(color: Colors.white, fontSize: 24),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, List<Attendance>> events) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(8),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          final date = DateTime(day.year, day.month, day.day);
          return events[date] ?? [];
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white70),
          outsideTextStyle: TextStyle(color: Colors.white24),
          todayDecoration: BoxDecoration(
            color: Color(0xFFFFB81C).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFFFFB81C),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green, // Green dot for presence
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          titleTextStyle: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          formatButtonTextStyle: TextStyle(color: Color(0xFFFFB81C)),
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: Color(0xFFFFB81C)),
            borderRadius: BorderRadius.circular(12),
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRecentLog(List<Attendance> attendance) {
    // Show only the logs for selected day if selected, else show recent 5
    List<Attendance> showList = attendance;
    String title = "Recent Activity";

    if (_selectedDay != null) {
      final date = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      showList =
          attendance.where((a) {
            final d = DateTime(
              a.timestamp.year,
              a.timestamp.month,
              a.timestamp.day,
            );
            return d == date;
          }).toList();
      title = "Activity on ${DateFormat.MMMd().format(_selectedDay!)}";
    } else {
      showList = attendance.take(5).toList();
    }

    if (showList.isEmpty && _selectedDay != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Absent on this day",
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 12),
        ...showList
            .map(
              (record) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: Colors.green, // status present
                      width: 4,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.yMMMd().format(record.timestamp),
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    Text(
                      DateFormat.jm().format(record.timestamp),
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
