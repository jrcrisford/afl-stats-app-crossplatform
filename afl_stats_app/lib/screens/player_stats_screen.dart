import 'dart:io';

import 'package:flutter/material.dart';
import '../models/action_model.dart';
import '../models/player_model.dart';
import '../services/firestore_service.dart';

class PlayerStatsScreen extends StatefulWidget {
  final String matchId;

  const PlayerStatsScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final FirestoreService _firestore = FirestoreService();

  List<PlayerModel> _players = [];
  PlayerModel? _playerA;
  PlayerModel? _playerB;
  int _selectedQuarter = 0; // 0 = All
  PlayerModel? _mvpPlayer;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _firestore.getMVP (widget.matchId).then((player) {
      setState(() {
        _mvpPlayer = player;
      });
    });
  }

  Future<void> _loadPlayers() async {
    final players = await _firestore.getPlayersForMatch(widget.matchId);
    setState(() {
      _players = players;
      if (players.length >= 2) {
        _playerA = players[0];
        _playerB = players[1];
      }
    });
  }

  Map<String, int> _calculateStats(List<ActionModel> actions) {
    final stats = {
      'disposals': 0,
      'marks': 0,
      'tackles': 0,
      'goals': 0,
      'behinds': 0
    };

    for (var action in actions) {
      if (_selectedQuarter != 0 && action.quarter != _selectedQuarter) continue;

      if (action.action == 'kick' || action.action == 'handball') stats['disposals'] = stats['disposals']! + 1;
      if (action.action == 'mark') stats['marks'] = stats['marks']! + 1;
      if (action.action == 'tackle') stats['tackles'] = stats['tackles']! + 1;
      if (action.action == 'goal') stats['goals'] = stats['goals']! + 1;
      if (action.action == 'behind') stats['behinds'] = stats['behinds']! + 1;
    }

    return stats;
  }

  TableRow _buildStatRow(String label, int? a, int? b, {String? customA, String? customB}) {
    final valueA = customA ?? (a?.toString() ?? '-');
    final valueB = customB ?? (b?.toString() ?? '-');

    final isEqual = a == b;
    final isAHigher = (a ?? 0) > (b ?? 0);

    final styleA = TextStyle(
      fontSize: 16,
      color: isEqual ? Colors.black : (isAHigher ? Colors.green : Colors.black),
    );
    final styleB = TextStyle(
      fontSize: 16,
      color: isEqual ? Colors.black : (!isAHigher ? Colors.green : Colors.black),
    );

    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(valueA, textAlign: TextAlign.center, style: styleA),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(valueB, textAlign: TextAlign.center, style: styleB),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002B5C);
    const bgColor = Color(0xFFF1F1F1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Compare Player Stats'),
      ),
      body: _playerA == null || _playerB == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
        future: Future.wait([
          _firestore.getActionsForPlayer(widget.matchId, _playerA!.name),
          _firestore.getActionsForPlayer(widget.matchId, _playerB!.name)
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final statsA = _calculateStats(snapshot.data![0]);
          final statsB = _calculateStats(snapshot.data![1]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Text(
                  _mvpPlayer != null
                      ? '🏅 MVP: ${_mvpPlayer!.name} (#${_mvpPlayer!.number})'
                      : '🏅 MVP: Loading...',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Text('Player A  ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text('  Player B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DropdownButton<PlayerModel>(
                      value: _playerA,
                      onChanged: (value) => setState(() => _playerA = value),
                      items: _players.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    ),
                    DropdownButton<PlayerModel>(
                      value: _playerB,
                      onChanged: (value) => setState(() => _playerB = value),
                      items: _players.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 120,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        image: _playerA?.imageUri != null && File(_playerA!.imageUri!).existsSync()
                            ? DecorationImage(image: FileImage(File(_playerA!.imageUri!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _playerA?.imageUri == null ? const Icon(Icons.person, size: 60) : null,
                    ),
                    Container(
                      width: 120,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                        image: _playerB?.imageUri != null && File(_playerB!.imageUri!).existsSync()
                            ? DecorationImage(image: FileImage(File(_playerB!.imageUri!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _playerB?.imageUri == null ? const Icon(Icons.person, size: 60) : null,
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade400),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    _buildStatRow('Disposals', statsA['disposals'], statsB['disposals']),
                    _buildStatRow('Marks', statsA['marks'], statsB['marks']),
                    _buildStatRow('Tackles', statsA['tackles'], statsB['tackles']),
                    _buildStatRow(
                      'Score',
                      statsA['goals']! * 6 + statsA['behinds']!,
                      statsB['goals']! * 6 + statsB['behinds']!,
                      customA: '${statsA['goals']}.${statsA['behinds']} (${(statsA['goals']! * 6 + statsA['behinds']!)})',
                      customB: '${statsB['goals']}.${statsB['behinds']} (${(statsB['goals']! * 6 + statsB['behinds']!)})',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Center(
                  child: ToggleButtons(
                    isSelected: List.generate(5, (index) => index == _selectedQuarter),
                    onPressed: (index) => setState(() => _selectedQuarter = index),
                    constraints: const BoxConstraints(minHeight: 40, minWidth: 65),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black,
                    selectedColor: Colors.white,
                    fillColor: primaryColor,
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('All')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Q1')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Q2')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Q3')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Q4')),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}