import 'package:cloud_firestore/cloud_firestore.dart';

class ActionModel {
  final String action;
  final String playerName;
  final String team;
  final int quarter;
  final int timeInMatch;
  final int timeInQuarter;
  final DateTime timestamp;

  ActionModel({
    required this.action,
    required this.playerName,
    required this.team,
    required this.quarter,
    required this.timeInMatch,
    required this.timeInQuarter,
    required this.timestamp,
  });

  factory ActionModel.fromMap(Map<String, dynamic> data) {
    return ActionModel(
      action: data['action'] ?? '',
      playerName: data['playerName'] ?? '',
      team: data['team'] ?? '',
      quarter: data['quarter'] ?? 1,
      timeInMatch: data['timeInMatch'] ?? 0,
      timeInQuarter: data['timeInQuarter'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'playerName': playerName,
      'team': team,
      'quarter': quarter,
      'timeInMatch': timeInMatch,
      'timeInQuarter': timeInQuarter,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}