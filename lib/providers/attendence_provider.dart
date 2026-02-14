import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rv_fitness/models/attendence.dart';

import 'package:rv_fitness/providers/customer_provider.dart';



final attendanceProvider = StreamProvider.family<List<Attendance>, String>((ref, customerId) {
  return ref.watch(firebaseServiceProvider).getAttendanceForCustomer(customerId);
});