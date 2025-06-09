import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String name;
  final DateTime createdAt;

  TeamModel({
    required this.name,
    required this.createdAt,
  });

  factory TeamModel.fromMap(Map<String, dynamic> data) {
    return TeamModel(
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}