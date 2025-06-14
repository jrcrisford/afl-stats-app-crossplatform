import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerModel {
  final String name;
  final int number;
  final String teamId;
  final int kick;
  final int handball;
  final int mark;
  final int tackle;
  final int goal;
  final int behind;
  final String? imageUri;

  PlayerModel({
    required this.name,
    required this.number,
    required this.teamId,
    this.kick = 0,
    this.handball = 0,
    this.mark = 0,
    this.tackle = 0,
    this.goal = 0,
    this.behind = 0,
    this.imageUri,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> data) {
    return PlayerModel(
      name: data['name'] ?? '',
      number: data['number'] ?? 0,
      teamId: data['teamId'] ?? '',
      kick: data['kick'] ?? 0,
      handball: data['handball'] ?? 0,
      mark: data['mark'] ?? 0,
      tackle: data['tackle'] ?? 0,
      goal: data['goal'] ?? 0,
      behind: data['behind'] ?? 0,
      imageUri: data['imageUri'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'teamId': teamId,
      'kick': kick,
      'handball': handball,
      'mark': mark,
      'tackle': tackle,
      'goal': goal,
      'behind': behind,
      if (imageUri != null) 'imageUri': imageUri,
    };
  }
}