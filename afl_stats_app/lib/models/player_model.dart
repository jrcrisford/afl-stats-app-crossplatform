import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String playerName;
  final int number;
  final String team;
  final int kick;
  final int handball;
  final int mark;
  final int tackle;
  final int goal;
  final int behind;

  PlayerModel({
    required this.playerName,
    required this.number,
    required this.team,
    this.kick = 0,
    this.handball = 0,
    this.mark = 0,
    this.tackle = 0,
    this.goal = 0,
    this.behind = 0,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> data) {
    return PlayerModel(
      playerName: data['name'] ?? '',
      number: data['number'] ?? 0,
      team: data['teamId'] ?? '',
      kick: data['kick'] ?? 0,
      handball: data['handball'] ?? 0,
      mark: data['mark'] ?? 0,
      tackle: data['tackle'] ?? 0,
      goal: data['goal'] ?? 0,
      behind: data['behind'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'number': number,
      'team': team,
      'kick': kick,
      'handball': handball,
      'mark': mark,
      'tackle': tackle,
      'goal': goal,
      'behind': behind,
    };
  }
}