import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id; // match document ID
  final String teamA;
  final String teamB;
  final DateTime startTime;
  final DateTime? finishedTime;
  final int quarter;
  final String status;

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.startTime,
    this.finishedTime,
    required this.quarter,
    required this.status,
  });

  factory MatchModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MatchModel(
      id: doc.id,
      teamA: data['teamA'] ?? '',
      teamB: data['teamB'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      finishedTime: data['finishedTime'] != null
          ? (data['finishedTime'] as Timestamp).toDate()
          : null,
      quarter: data['quarter'] ?? 1,
      status: data['status'] ?? 'in_progress',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamA': teamA,
      'teamB': teamB,
      'startTime': Timestamp.fromDate(startTime),
      'finishedTime':
      finishedTime != null ? Timestamp.fromDate(finishedTime!) : null,
      'quarter': quarter,
      'status': status,
    };
  }
}