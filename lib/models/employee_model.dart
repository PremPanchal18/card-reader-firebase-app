class Employee {
  String id;
  String employeeId;
  String name;
  String department;
  String designation;
  String email;
  String mobile;
  String joiningDate;
  String imageUrl;

  Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.department,
    required this.designation,
    required this.email,
    required this.mobile,
    required this.joiningDate,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'name': name,
      'department': department,
      'designation': designation,
      'email': email,
      'mobile': mobile,
      'joiningDate': joiningDate,
      'imageUrl': imageUrl,
    };
  }

  factory Employee.fromMap(
      String id, Map<String, dynamic> map) {
    return Employee(
      id: id,
      employeeId: map['employeeId'],
      name: map['name'],
      department: map['department'],
      designation: map['designation'],
      email: map['email'],
      mobile: map['mobile'],
      joiningDate: map['joiningDate'],
      imageUrl: map['imageUrl'],
    );
  }
}