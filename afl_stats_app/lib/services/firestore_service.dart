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
    await _db.collection('teamData').doc(team.name).set({
      'name': team.name,
      'createdAt': team.createdAt,
    });
  }

  Future<void> deleteTeam(String teamName) async {
    await _db.collection('teamData').doc(teamName).delete();
  }

  Future<void> renameTeam({required String oldName, required String newName}) async {
    final oldRef = _db.collection('teamData').doc(oldName);
    final newRef = _db.collection('teamData').doc(newName);

    final snapshot = await oldRef.get();
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null) {
        data['name'] = newName;

        await newRef.set(data);
        await oldRef.delete();

        // Update players' team references
        final players = await _db
            .collection('players')
            .where('team', isEqualTo: oldName)
            .get();

        for (var doc in players.docs) {
          await doc.reference.update({'team': newName});
        }
      }
    }
  }

  // Player Operations
  Future<List<PlayerModel>> getAllPlayers() async {
    final snapshot = await _db.collection('players').get();
    return snapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> addPlayer(PlayerModel player) async {
    await _db
        .collection('players')
        .doc(player.name)
        .set(player.toMap());
  }

  Future<void> deletePlayer(String playerName) async {
    await _db.collection('players').doc(playerName).delete();
  }

  Future<List<PlayerModel>> getPlayersForMatch(String matchId) async {
    final snapshot = await _db
        .collection('matchData')
        .doc(matchId)
        .collection('players')
        .get();

    return snapshot.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList();
  }

  // Match Operations
  Future<DocumentReference> createMatch(Map<String, dynamic> data) {
    return FirebaseFirestore.instance.collection('matchData').add(data);
  }

  Future<List<MatchModel>> getAllMatches() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('matchData')
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs.map((doc) => MatchModel.fromDoc(doc)).toList();
  }

  Future<PlayerModel?> getMVP(String matchId) async {
    final playersSnapshot = await _db
        .collection('matchData')
        .doc(matchId)
        .collection('players')
        .get();

    PlayerModel? mvp;
    int highestScore = -1;

    for (var doc in playersSnapshot.docs) {
      final data = doc.data();
      final player = PlayerModel.fromMap(data);

      int score = (player.goal * 6) +
          (player.behind * 1) +
          (player.kick * 1) +
          (player.handball * 1) +
          (player.mark * 1) +
          (player.tackle * 2);

      if (score > highestScore) {
        highestScore = score;
        mvp = player;
      }
    }

    return mvp;
  }

  // Action Operations
  Future<void> recordPlayerAction({
    required String matchId,
    required String name,
    required String teamId,
    required ActionModel action,
  }) async {
    final playerRef = _db
        .collection('matchData')
        .doc(matchId)
        .collection('players')
        .doc(name);

    final playerActionRef = playerRef.collection('actions');

    await addActionToMatch(matchId, action);
    await playerActionRef.add(action.toMap());
    await playerRef.update({
      action.action: FieldValue.increment(1),
    });
  }

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
        .orderBy('timestamp')
        .get();

    return snapshot.docs
        .map((doc) => ActionModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<ActionModel>> getActionsForPlayer(String matchId, String playerName) async {
    final snapshot = await _db
        .collection('matchData')
        .doc(matchId)
        .collection('players')
        .doc(playerName)
        .collection('actions')
        .get();

    return snapshot.docs.map((doc) => ActionModel.fromMap(doc.data())).toList();
  }

}
