import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_model.dart';

class EmployeeService {

  final collection =
  FirebaseFirestore.instance.collection("employees");

  Future addEmployee(Employee employee) async {

    await collection.add(employee.toMap());
  }

  Stream<QuerySnapshot> getEmployees() {

    return collection.snapshots();
  }

  Future deleteEmployee(String id) async {

    await collection.doc(id).delete();
  }

  Future updateEmployee(
      String id,
      Map<String, dynamic> data,
      ) async {

    await collection.doc(id).update(data);
  }
}