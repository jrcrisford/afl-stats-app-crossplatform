import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({Key? key}) : super(key: key);

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final FirestoreService _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _testFirestore();
  }

  Future<void> _testFirestore() async {
    try {
      // TEAMS
      print('Fetching teams...');
      List<TeamModel> teams = await _firestore.getAllTeams();
      for (var team in teams) {
        print('[FIRESTORE TEST] Team: ${team.name} (${team.createdAt})');
      }

      // PLAYERS
      print('Fetching players...');
      List<PlayerModel> players = await _firestore.getAllPlayers();
      for (var player in players) {
        print('[FIRESTORE TEST] Player: ${player.name} - #${player.number} (${player.teamId})');
      }

      // MATCHES
      print('Fetching matches...');
      final matches = await _firestore.getAllMatches();
      for (var match in matches) {
        print('[FIRESTORE TEST] Match: ${match.id} - ${match.teamA} vs ${match.teamB}');

        // ACTIONS within this match
        final actions = await _firestore.getActionsForMatch(match.id);
        for (var action in actions) {
          print('[FIRESTORE TEST] Action: ${action.action} by ${action.name} '
              '(Q${action.quarter}, ${action.timeInQuarter}s)');
        }
      }
    } catch (e, stack) {
      print('Firestore read error: $e');
      print(stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore Test')),
      body: Center(child: Text('Check console for Firestore output')),
    );
  }
}
