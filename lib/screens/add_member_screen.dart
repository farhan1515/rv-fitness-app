import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/customer.dart';
import '../services/firebase_service.dart';
import '../providers/customer_provider.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final Customer? existingCustomer;
  final bool isRenewal;

  const AddMemberScreen({
    super.key,
    this.existingCustomer,
    this.isRenewal = false,
  });

  @override
  _AddMemberScreenState createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  final _feesController = TextEditingController();
  String _gender = 'Male';
  String _trainingType = 'Self';
  String _paymentStatus = 'Paid';
  DateTime _dateOfBirth = DateTime.now().subtract(Duration(days: 365 * 18));
  DateTime _startDate = DateTime(2025, 1, 1);
  DateTime _endDate = DateTime.now().add(Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCustomer != null) {
      _nameController.text = widget.existingCustomer!.name;
      _phoneController.text = widget.existingCustomer!.phoneNumber;
      _weightController.text = widget.existingCustomer!.weight.toString();
      _feesController.text = widget.existingCustomer!.fees.toString();
      _gender = widget.existingCustomer!.gender;
      _trainingType = widget.existingCustomer!.trainingType;
      _dateOfBirth = widget.existingCustomer!.dateOfBirth;
      _startDate = widget.existingCustomer!.startDate;
      _endDate = widget.existingCustomer!.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _feesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        double? weight = double.tryParse(_weightController.text);
        double? fees = double.tryParse(_feesController.text);

        if (weight == null) {
          throw Exception('Please enter a valid weight');
        }
        if (fees == null) {
          throw Exception('Please enter a valid fee amount');
        }

        if (widget.isRenewal && widget.existingCustomer != null) {
          // Handle renewal
          await ref.read(firebaseServiceProvider).renewMembership(
                customerId: widget.existingCustomer!.id,
                newStartDate: _startDate,
                newEndDate: _endDate,
                newFees: fees,
              );
        } else {
          // Handle new member
          final customer = Customer(
            id: widget.existingCustomer?.id ?? Uuid().v4(),
            name: _nameController.text,
            dateOfBirth: _dateOfBirth,
            phoneNumber: _phoneController.text,
            gender: _gender,
            weight: weight,
            trainingType: _trainingType,
            startDate: _startDate,
            endDate: _endDate,
            fees: fees,
            paymentStatus: _paymentStatus,
          );

          await ref.read(firebaseServiceProvider).addCustomer(customer);
        }

        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      } catch (e) {
        setState(() => _isSubmitting = false);
        _showErrorDialog(e.toString());
        print('Error submitting form: $e');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 70),
              ),
              SizedBox(height: 24),
              Text(
                widget.isRenewal
                    ? 'Membership Renewed Successfully!'
                    : 'Member Added Successfully!',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                widget.isRenewal
                    ? 'The membership has been renewed successfully.'
                    : 'The new member has been added to your client list.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!widget.isRenewal) {
                // Clear form fields after successful submission
                _nameController.clear();
                _phoneController.clear();
                _weightController.clear();
                _feesController.clear();
                setState(() {
                  _gender = 'Male';
                  _trainingType = 'Self';
                  _paymentStatus = 'Paid';
                  _dateOfBirth =
                      DateTime.now().subtract(Duration(days: 365 * 18));
                  _startDate = DateTime(2025, 1, 1);
                  _endDate = DateTime.now().add(Duration(days: 30));
                });
              } else {
                Navigator.pop(
                    context); // Go back to previous screen after renewal
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF8E2DE2),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: Colors.red, size: 70),
              ),
              SizedBox(height: 24),
              Text(
                'Something Went Wrong',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF8E2DE2),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              _buildCustomAppBar(context),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member Information',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: Duration(milliseconds: 400)),
                        SizedBox(height: 20),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person,
                          hintText: 'Enter member\'s full name',
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 100)),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone,
                                hintText: 'Enter phone number',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _weightController,
                                label: 'Weight (kg)',
                                icon: Icons.fitness_center,
                                hintText: 'Enter weight in kg',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 200)),
                        SizedBox(height: 16),
                        _buildDatePicker(
                          label: 'Date of Birth',
                          icon: Icons.cake,
                          selectedDate: _dateOfBirth,
                          onDateSelected: (date) =>
                              setState(() => _dateOfBirth = date),
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 300)),
                        SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Gender',
                          icon: Icons.wc,
                          items: [
                            'Male',
                            'Female',
                          ],
                          value: _gender,
                          onChanged: (value) =>
                              setState(() => _gender = value!),
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 400)),
                        SizedBox(height: 24),
                        Text(
                          'Membership Details',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 500)),
                        SizedBox(height: 20),
                        _buildDropdown(
                          label: 'Training Type',
                          icon: Icons.fitness_center,
                          items: ['Self', 'Personal', 'General'],
                          value: _trainingType,
                          onChanged: (value) =>
                              setState(() => _trainingType = value!),
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 600)),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _feesController,
                                label: 'Fees',
                                icon: Icons.attach_money,
                                hintText: 'Amount',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown(
                                label: 'Payment Status',
                                icon: Icons.payment,
                                items: ['Paid', 'Pending'],
                                value: _paymentStatus,
                                onChanged: (value) =>
                                    setState(() => _paymentStatus = value!),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 700)),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                label: 'Start Date',
                                icon: Icons.calendar_today,
                                selectedDate: _startDate,
                                onDateSelected: (date) =>
                                    setState(() => _startDate = date),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDatePicker(
                                label: 'End Date',
                                icon: Icons.event_available,
                                selectedDate: _endDate,
                                onDateSelected: (date) =>
                                    setState(() => _endDate = date),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(
                            duration: Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 800)),
                        SizedBox(height: 40),
                        _buildSubmitButton().animate().fadeIn(
                            duration: Duration(milliseconds: 600),
                            delay: Duration(milliseconds: 900)),
                        SizedBox(height: 20),
                      ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isRenewal ? 'Renew Membership' : 'Add New Member',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.isRenewal
                        ? 'Extend membership period'
                        : 'Create a new membership',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
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
              widget.isRenewal ? Icons.refresh_rounded : Icons.person_add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: Duration(milliseconds: 400))
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFD700).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (keyboardType == TextInputType.number) {
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            if (double.parse(value) <= 0) {
              return 'Please enter a number greater than 0';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFA500).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Color(0xFF000000),
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required IconData icon,
    required DateTime selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Set appropriate date ranges based on the field type
          final DateTime firstDate;
          final DateTime lastDate;

          if (label == 'Date of Birth') {
            firstDate = DateTime(1900);
            lastDate = DateTime.now();
          } else {
            firstDate = DateTime(2000);
            lastDate = DateTime(2100);
          }

          // For date of birth, we don't need to adjust the initial date
          // For other dates, ensure it's within the valid range
          final DateTime initialDate = label == 'Date of Birth'
              ? selectedDate
              : selectedDate.isBefore(firstDate)
                  ? firstDate
                  : selectedDate.isAfter(lastDate)
                      ? lastDate
                      : selectedDate;

          final date = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Color(0xFFFFA500),
                    onPrimary: Colors.white,
                    surface: Color(0xFF000000),
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: Color(0xFF000000),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFFFA500),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) onDateSelected(date);
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Color(0xFFFFD700).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.7)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(selectedDate),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Color(0xFFFFA500),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.symmetric(vertical: 16),
          elevation: 5,
          shadowColor: Color(0xFFFFA500).withOpacity(0.5),
        ),
        child: _isSubmitting
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isRenewal ? Icons.refresh_rounded : Icons.save,
                    size: 22,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.isRenewal ? 'Renew Membership' : 'Add Member',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
