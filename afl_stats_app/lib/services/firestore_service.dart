import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';
import '../models/match_model.dart';
import '../models/action_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Team Operations
  Future<List<TeamModel>> getAllTeams() async {
    final snapshot = await _db.collection('teamData').get();
    return snapshot.docs
        .map((doc) => TeamModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> addTeam(TeamModel team) async {
    await _db.collection('teamData').doc(team.name).set(team.toMap());
  }

  // Player Operations
  Future<List<PlayerModel>> getAllPlayers() async {
    final snapshot = await _db.collection('playerData').get();
    return snapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> addPlayer(PlayerModel player) async {
    await _db
        .collection('playerData')
        .doc(player.playerName)
        .set(player.toMap());
  }

  // Match Operations
  Future<void> createMatch(MatchModel match) async {
    await _db.collection('matchData').doc(match.id).set(match.toMap());
  }

  Future<List<MatchModel>> getAllMatches() async {
    final snapshot = await _db.collection('matchData').get();
    return snapshot.docs
        .map((doc) => MatchModel.fromDoc(doc))
        .toList();
  }

  // Action Operations
  Future<void> addActionToMatch(String matchId, ActionModel action) async {
    await _db
        .collection('matchData')
        .doc(matchId)
        .collection('matchActions')
        .add(action.toMap());
  }

  Future<List<ActionModel>> getActionsForMatch(String matchId) async {
    final snapshot = await _db
        .collection('matchData')
        .doc(matchId)
        .collection('matchActions')
        .get();

    return snapshot.docs
        .map((doc) => ActionModel.fromMap(doc.data()))
        .toList();
  }

}
