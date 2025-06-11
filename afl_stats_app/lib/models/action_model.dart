import 'package:cloud_firestore/cloud_firestore.dart';

class ActionModel {
  final String action;
  final String name;
  final String teamId;
  final int quarter;
  final int timeInMatch;
  final int timeInQuarter;
  final DateTime timestamp;

  ActionModel({
    required this.action,
    required this.name,
    required this.teamId,
    required this.quarter,
    required this.timeInMatch,
    required this.timeInQuarter,
    required this.timestamp,
  });

  factory ActionModel.fromMap(Map<String, dynamic> data) {
    return ActionModel(
      action: data['action'] ?? '',
      name: data['playerName'] ?? '',
      teamId: data['team'] ?? '',
      quarter: data['quarter'] ?? 1,
      timeInMatch: data['timeInMatch'] ?? 0,
      timeInQuarter: data['timeInQuarter'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'playerName': name,
      'team': teamId,
      'quarter': quarter,
      'timeInMatch': timeInMatch,
      'timeInQuarter': timeInQuarter,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}