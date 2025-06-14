import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/team_model.dart';
import 'package:afl_stats_app/screens/match_tracking_screen.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({Key? key}) : super(key: key);

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final FirestoreService _firestore = FirestoreService();

  TeamModel? _teamA;
  TeamModel? _teamB;
  List<TeamModel> _allTeams = [];
  Map<String, int> _playerCounts = {};

  final Color primaryColor = const Color(0xFF002B5C);
  final Color bgColor = const Color(0xFFF1F1F1);

  bool get _canStartMatch {
    if (_teamA == null || _teamB == null) return false;
    if (_teamA!.name == _teamB!.name) return false;

    final countA = _playerCounts[_teamA!.name] ?? 0;
    final countB = _playerCounts[_teamB!.name] ?? 0;

    return countA > 2 && countB > 2;
  }

  @override
  void initState() {
    super.initState();
    _loadTeamsAndPlayerCounts();
  }

  Future<void> _loadTeamsAndPlayerCounts() async {
    final teams = await _firestore.getAllTeams();
    final players = await _firestore.getAllPlayers();

    final counts = <String, int>{};
    for (var team in teams) {
      counts[team.name] = players.where((p) => p.teamId == team.name).length;
    }

    setState(() {
      _allTeams = teams;
      _playerCounts = counts;
    });
  }

  void _selectTeam(bool isTeamA) async {
    final selected = await showDialog<TeamModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Team'),
        children: _allTeams.map((team) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, team),
            child: Text(team.name),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        if (isTeamA) {
          _teamA = selected;
        } else {
          _teamB = selected;
        }
      });
    }
  }

  void _startMatch() async {
    final matchRef = await _firestore.createMatch({
      'teamA': _teamA!.name,
      'teamB': _teamB!.name,
      'startTime': Timestamp.now(),
      'quarter': 1,
      'status': 'ongoing',
    });

    final allPlayers = await _firestore.getAllPlayers();
    final selectedPlayers = allPlayers
        .where((player) =>
    player.teamId == _teamA!.name || player.teamId == _teamB!.name)
        .toList();

    final batch = FirebaseFirestore.instance.batch();
    for (final player in selectedPlayers) {
      final playerRef = matchRef.collection('players').doc(player.name);
      batch.set(playerRef, {
        'name': player.name,
        'teamId': player.teamId,
        'number': player.number,
        'kick': 0,
        'handball': 0,
        'mark': 0,
        'tackle': 0,
        'goal': 0,
        'behind': 0,
      });
    }

    await batch.commit();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchTrackingScreen(matchId: matchRef.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Match Setup',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select two teams to start a match. Teams must have at least 2 players to proceed.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),

            // Team selectors
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamColumn('Team A', _teamA, () => _selectTeam(true)),
                _buildTeamColumn('Team B', _teamB, () => _selectTeam(false)),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Start button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canStartMatch ? _startMatch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _canStartMatch ? Colors.redAccent : Colors.grey,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text(
                  'Start Match',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(
      String label, TeamModel? team, VoidCallback onSelect) {
    final playerCount = team != null ? _playerCounts[team.name] ?? 0 : '-';

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text('Players: $playerCount'),
        const SizedBox(height: 8),
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: onSelect,
            child: Text(
              team != null ? team.name : 'Select $label',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}