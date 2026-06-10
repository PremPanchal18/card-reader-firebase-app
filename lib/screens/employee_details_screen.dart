import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> employeeData;

  const EmployeeDetailsScreen({
    super.key,
    required this.documentId,
    required this.employeeData,
  });

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController departmentController;
  late TextEditingController designationController;
  late TextEditingController employeeIdController;
  late TextEditingController emailController;
  late TextEditingController mobileController;
  late TextEditingController joiningDateController;

  bool loading = false;

  File? _pickedImage;
  String? _existingBase64;
  bool _imageChanged = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.employeeData['name'] ?? '',
    );
    departmentController = TextEditingController(
      text: widget.employeeData['department'] ?? '',
    );
    designationController = TextEditingController(
      text: widget.employeeData['designation'] ?? '',
    );
    employeeIdController = TextEditingController(
      text: widget.employeeData['employeeId'] ?? '',
    );
    emailController = TextEditingController(
      text: widget.employeeData['email'] ?? '',
    );
    mobileController = TextEditingController(
      text: widget.employeeData['mobile'] ?? '',
    );
    joiningDateController = TextEditingController(
      text: widget.employeeData['joiningDate'] ?? '',
    );

    _existingBase64 = widget.employeeData['imageUrl'];
  }

  @override
  void dispose() {
    nameController.dispose();
    departmentController.dispose();
    designationController.dispose();
    employeeIdController.dispose();
    emailController.dispose();
    mobileController.dispose();
    joiningDateController.dispose();
    super.dispose();
  }

  // ─── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _imageChanged = true;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Select Image Source",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_pickedImage != null || _existingBase64 != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Remove Photo",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImage = null;
                    _existingBase64 = null;
                    _imageChanged = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _imageToBase64(File file) async {
    final bytes = await file.readAsBytes();

    final original = await compute(img.decodeImage, bytes);
    if (original == null) return null;

    final resized = img.copyResize(
      original,
      width: original.width >= original.height ? 400 : -1,
      height: original.height > original.width ? 400 : -1,
    );

    final compressed = img.encodeJpg(resized, quality: 70);
    return base64Encode(compressed);
  }

  // ─── Validators ────────────────────────────────────────────────────────────

  String? _validateEmployeeId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Employee ID is required';
    if (!RegExp(r'^[A-Za-z0-9\-\/]{3,15}$').hasMatch(v)) {
      return 'Employee ID must be 3–15 alphanumeric characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2 || v.length > 50) return 'Name must be 2–50 characters';
    if (!RegExp(r"^[A-Za-z][A-Za-z\s.\-']+$").hasMatch(v)) {
      return 'Enter a valid name (letters, spaces, dots, hyphens only)';
    }
    return null;
  }

  String? _validateDepartment(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Department is required';
    if (!RegExp(r'^[A-Za-z\s\-&]{2,50}$').hasMatch(v)) {
      return 'Enter a valid department name';
    }
    return null;
  }

  String? _validateDesignation(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Designation is required';
    if (!RegExp(r"^[A-Za-z\s.\-'&]{2,50}$").hasMatch(v)) {
      return 'Enter a valid designation';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')
        .hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Mobile number is required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(v)) {
      return 'Enter a valid mobile number';
    }
    if (digits.length < 7 || digits.length > 15) {
      return 'Mobile number must have 7–15 digits';
    }
    return null;
  }

  String? _validateJoiningDate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Joining date is required';
    final parts = v.split('/');
    if (parts.length != 3) return 'Invalid date format';
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return 'Invalid date';
    if (month < 1 || month > 12) return 'Invalid month';
    if (day < 1 || day > 31) return 'Invalid day';
    if (year < 2000 || year > 2100) return 'Year must be between 2000–2100';
    return null;
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => loading = true);

      String? base64Image = _existingBase64;
      if (_imageChanged) {
        base64Image =
        _pickedImage != null ? await _imageToBase64(_pickedImage!) : null;
      }

      await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.documentId)
          .update({
        'employeeId': employeeIdController.text.trim(),
        'name': nameController.text.trim(),
        'department': departmentController.text.trim(),
        'designation': designationController.text.trim(),
        'email': emailController.text.trim(),
        'mobile': mobileController.text.trim(),
        'joiningDate': joiningDateController.text.trim(),
        'imageUrl': base64Image,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee updated successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteEmployee() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Employee"),
        content: const Text("Are you sure you want to delete this employee?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => loading = true);

      await FirebaseFirestore.instance
          .collection('employees')
          .doc(widget.documentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee deleted successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    const double size = 110;

    ImageProvider? imageProvider;

    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (_existingBase64 != null && _existingBase64!.isNotEmpty) {
      imageProvider = MemoryImage(base64Decode(_existingBase64!));
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.person, size: size * 0.55, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildAvatar(),

                const SizedBox(height: 8),

                TextButton.icon(
                  onPressed: _showImageSourceSheet,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("Change Photo"),
                ),

                const SizedBox(height: 16),

                Text(
                  "Employee Details",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                _buildField(
                  controller: employeeIdController,
                  label: "Employee ID",
                  icon: Icons.badge,
                  validator: _validateEmployeeId,
                ),
                _buildField(
                  controller: nameController,
                  label: "Employee Name",
                  icon: Icons.person,
                  validator: _validateName,
                ),
                _buildField(
                  controller: departmentController,
                  label: "Department",
                  icon: Icons.business,
                  validator: _validateDepartment,
                ),
                _buildField(
                  controller: designationController,
                  label: "Designation",
                  icon: Icons.work_outline,
                  validator: _validateDesignation,
                ),
                _buildField(
                  controller: emailController,
                  label: "Email",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                _buildField(
                  controller: mobileController,
                  label: "Mobile",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: _validateMobile,
                ),
                _buildField(
                  controller: joiningDateController,
                  label: "Joining Date",
                  icon: Icons.calendar_month,
                  readOnly: true,
                  validator: _validateJoiningDate,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (date != null) {
                      joiningDateController.text =
                      "${date.day}/${date.month}/${date.year}";
                    }
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : updateEmployee,
                    icon: const Icon(Icons.save),
                    label: loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text("Update Employee"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : deleteEmployee,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Delete Employee"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}