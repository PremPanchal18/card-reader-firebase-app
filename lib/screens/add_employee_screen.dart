import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/employee_model.dart';
import '../services/employee_service.dart';
import '../services/ocr_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── OCR card image (existing) ──
  File? imageFile;

  // ── Profile image (new) ──
  File? _profileImage;

  final employeeIdController = TextEditingController();
  final nameController = TextEditingController();
  final departmentController = TextEditingController();
  final designationController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final joiningDateController = TextEditingController();

  bool loading = false;
  bool processingOcr = false;

  final picker = ImagePicker();

  // ─── OCR Card Image ────────────────────────────────────────────────────────

  Future pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
        processingOcr = true;
      });

      await extractData();

      setState(() {
        processingOcr = false;
      });
    }
  }

  // ─── Profile Image ─────────────────────────────────────────────────────────

  Future<void> _pickProfileImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _profileImage = File(picked.path);
    });
  }

  void _showProfileImageSheet() {
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
              "Select Profile Photo",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  "Remove Photo",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profileImage = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Compress + convert to Base64
  Future<String?> _imageToBase64(File file) async {
    final bytes = await file.readAsBytes();

    // Decode — runs in isolate to avoid UI freeze
    final original = await compute(img.decodeImage, bytes);
    if (original == null) return null;

    // Resize to max 400px on longest side
    final resized = img.copyResize(
      original,
      width: original.width >= original.height ? 400 : -1,
      height: original.height > original.width ? 400 : -1,
    );

    // Encode as JPEG at quality 70
    final compressed = img.encodeJpg(resized, quality: 70);

    return base64Encode(compressed);
  }

  // ─── OCR Extraction ────────────────────────────────────────────────────────

  Future extractData() async {
    if (imageFile == null) return;

    final text = await OCRService().extractText(imageFile!.path);

    debugPrint(text);

    nameController.text = extractName(text);
    emailController.text = extractEmail(text);
    mobileController.text = extractMobile(text);
    employeeIdController.text = extractEmployeeId(text);
    designationController.text = extractDesignation(text);
  }

  String extractEmployeeId(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('employee') ||
          lower.contains('emp') ||
          lower.contains('id')) {
        final match = RegExp(
          r'\b[A-Z]{0,4}[-/]?\d{3,10}\b',
          caseSensitive: false,
        ).firstMatch(line);
        if (match != null) return match.group(0)!.trim();
      }
    }
    final fallback = RegExp(
      r'\b[A-Z]{1,4}[-/]?\d{4,10}\b',
      caseSensitive: false,
    ).firstMatch(text);
    return fallback?.group(0)?.trim() ?? '';
  }

  String extractEmail(String text) {
    final reg = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');
    return reg.firstMatch(text)?.group(0)?.trim() ?? '';
  }

  String extractMobile(String text) {
    final reg = RegExp(
      r'(?:\+\d{1,3}[\s\-]?)?(?:\(?\d{2,4}\)?[\s\-]?)?\d{3,5}[\s\-]?\d{4,5}',
    );
    final matches = reg.allMatches(text);
    for (final m in matches) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 7 && digits.length <= 15) {
        return m.group(0)!.trim();
      }
    }
    return '';
  }

  String extractName(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines) {
      final stripped = line
          .replaceFirstMapped(
        RegExp(r'^(name|full\s*name)\s*[:\-]\s*', caseSensitive: false),
            (_) => '',
      )
          .trim();

      if (stripped.isEmpty) continue;
      if (stripped.contains('@')) continue;
      if (RegExp(r'\d{2,}').hasMatch(stripped)) continue;

      final words = stripped.split(RegExp(r'\s+'));
      if (words.length >= 2 &&
          words.length <= 5 &&
          RegExp(r"^[A-Za-z][A-Za-z\s.\-']+$").hasMatch(stripped)) {
        return stripped;
      }
    }
    return '';
  }

  String extractDesignation(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    const designationKeywords = [
      'engineer', 'developer', 'manager', 'executive', 'officer',
      'analyst', 'consultant', 'designer', 'director', 'lead',
      'architect', 'intern', 'specialist', 'administrator',
      'coordinator', 'staff',
    ];

    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final keyword in designationKeywords) {
        if (lower.contains(keyword)) {
          return line
              .replaceFirstMapped(
            RegExp(
              r'^(designation|title|position|role)\s*[:\-]\s*',
              caseSensitive: false,
            ),
                (_) => '',
          )
              .trim();
        }
      }
    }
    return '';
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => loading = true);

      // Convert profile image to Base64 if selected
      String? profileBase64;
      if (_profileImage != null) {
        profileBase64 = await _imageToBase64(_profileImage!);
      }

      Employee employee = Employee(
        id: '',
        employeeId: employeeIdController.text.trim(),
        name: nameController.text.trim(),
        department: departmentController.text.trim(),
        designation: designationController.text.trim(),
        email: emailController.text.trim(),
        mobile: mobileController.text.trim(),
        joiningDate: joiningDateController.text.trim(),
        imageUrl: profileBase64 ?? '',   // store Base64 in imageUrl field
      );

      await EmployeeService().addEmployee(employee);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee Saved Successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ─── Validators ────────────────────────────────────────────────────────────

  String? _validateField(String label, String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return '$label is required';

    switch (label) {
      case 'Employee ID':
        if (!RegExp(r'^[A-Za-z0-9\-\/]{3,15}$').hasMatch(v)) {
          return 'Employee ID must be 3–15 alphanumeric characters';
        }
        break;

      case 'Name':
        if (!RegExp(r"^[A-Za-z][A-Za-z\s.\-']{1,49}$").hasMatch(v)) {
          return 'Enter a valid name (letters, spaces, dots, hyphens only)';
        }
        if (v.length < 2 || v.length > 50) {
          return 'Name must be between 2 and 50 characters';
        }
        break;

      case 'Department':
        if (!RegExp(r'^[A-Za-z\s\-&]{2,50}$').hasMatch(v)) {
          return 'Enter a valid department name';
        }
        break;

      case 'Designation':
        if (!RegExp(r"^[A-Za-z\s.\-'&]{2,50}$").hasMatch(v)) {
          return 'Enter a valid designation';
        }
        break;

      case 'Email':
        if (!RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')
            .hasMatch(v)) {
          return 'Enter a valid email address';
        }
        break;

      case 'Mobile':
        final digits = v.replaceAll(RegExp(r'\D'), '');
        if (!RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(v)) {
          return 'Enter a valid mobile number';
        }
        if (digits.length < 10 || digits.length > 15) {
          return 'Mobile number must have 10–15 digits';
        }
        break;
    }

    return null;
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildProfileAvatar() {
    const double size = 110;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
            _profileImage != null ? FileImage(_profileImage!) : null,
            child: _profileImage == null
                ? Icon(Icons.person, size: size * 0.55, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showProfileImageSheet,
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

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => _validateField(label, value),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Employee")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    // ── Profile Avatar ──
                    _buildProfileAvatar(),

                    const SizedBox(height: 6),

                    TextButton.icon(
                      onPressed: _showProfileImageSheet,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Add Profile Photo"),
                    ),

                    const Divider(height: 32),

                    // ── OCR Card Section ──
                    const Text(
                      "Scan Employee Card",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: imageFile == null
                          ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 60),
                            SizedBox(height: 8),
                            Text("Select Employee Card"),
                          ],
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(imageFile!, fit: BoxFit.cover),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (processingOcr)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text("Extracting data..."),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Camera"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo),
                            label: const Text("Gallery"),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 36),

                    // ── Form Fields ──
                    buildField(
                      controller: employeeIdController,
                      label: "Employee ID",
                      icon: Icons.badge,
                    ),
                    buildField(
                      controller: nameController,
                      label: "Name",
                      icon: Icons.person,
                    ),
                    buildField(
                      controller: departmentController,
                      label: "Department",
                      icon: Icons.business,
                    ),
                    buildField(
                      controller: designationController,
                      label: "Designation",
                      icon: Icons.work_outline,
                    ),
                    buildField(
                      controller: emailController,
                      label: "Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    buildField(
                      controller: mobileController,
                      label: "Mobile",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    // ── Joining Date ──
                    TextFormField(
                      controller: joiningDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Joining Date",
                        prefixIcon: const Icon(Icons.calendar_month),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'Joining Date is required';
                        final parts = v.split('/');
                        if (parts.length != 3) return 'Invalid date format';
                        final day = int.tryParse(parts[0]);
                        final month = int.tryParse(parts[1]);
                        final year = int.tryParse(parts[2]);
                        if (day == null || month == null || year == null) {
                          return 'Invalid date';
                        }
                        if (month < 1 || month > 12) return 'Invalid month';
                        if (day < 1 || day > 31) return 'Invalid day';
                        if (year < 2000 || year > 2100) {
                          return 'Year must be between 2000–2100';
                        }
                        return null;
                      },
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

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : saveEmployee,
                        icon: const Icon(Icons.save),
                        label: loading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Text("Save Employee"),
                      ),
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