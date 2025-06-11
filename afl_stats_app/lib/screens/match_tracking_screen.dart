import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../models/action_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class MatchTrackingScreen extends StatefulWidget {
  final String matchId;

  const MatchTrackingScreen({Key? key, required this.matchId})
      : super(key: key);

  @override
  State<MatchTrackingScreen> createState() => _MatchTrackingScreenState();
}

class _MatchTrackingScreenState extends State<MatchTrackingScreen> {
  MatchModel? _match;
  bool _isLoading = true;

  List<bool> _selectedTeams = [true, false];
  List<PlayerModel> _matchPlayers = [];
  String? _selectedPlayerName;
  int _quarter = 1;
  bool _isQuarterRunning = false;
  DateTime? _matchStartTime;
  DateTime? _quarterStartTime;
  Duration _elapsedMatch = Duration.zero;
  Duration _elapsedQuarter = Duration.zero;
  Timer? _timer;
  bool _isMatchFinished = false;
  List<ActionModel> _actionLog = [];

  @override
  void initState() {
    super.initState();
    _loadMatch().then((_) {
      _listenToActionLog();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadMatch() async {
    final doc = await FirebaseFirestore.instance
        .collection('matchData')
        .doc(widget.matchId)
        .get();

    final playerDocs = await FirebaseFirestore.instance
        .collection('matchData')
        .doc(widget.matchId)
        .collection('players')
        .get();

    final players = playerDocs.docs.map((doc) =>
        PlayerModel.fromMap(doc.data())
    ).toList();

    setState(() {
      _match = MatchModel.fromDoc(doc);
      _matchPlayers = players;
      _selectedPlayerName = players.isNotEmpty ? players.first.name : null;
      _isLoading = false;
    });
  }

  void _startQuarter() {
    final now = DateTime.now();
    if (_matchStartTime == null) {
      _matchStartTime = now;
    }

    _quarterStartTime = now;
    _isQuarterRunning = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_)
    {
      final now = DateTime.now();
      setState(() {
        _elapsedMatch = now.difference(_matchStartTime!);
        _elapsedQuarter = now.difference(_quarterStartTime!);
      });
    });
  }

  void _endQuarter() {
    _timer?.cancel();
    _isQuarterRunning = false;

    if (_quarter >= 4) {
      setState(() {
        _isMatchFinished = true;
      });
    } else {
      setState(() {
        _quarter++;
        _elapsedQuarter = Duration.zero;
      });
    }
  }

  // Future<void> _loadActions() async {
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('matchData')
  //       .doc(widget.matchId)
  //       .collection('matchActions')
  //       .orderBy('timestamp', descending: true)
  //       .get();
  //
  //   setState(() {
  //     _actionLog = snapshot.docs
  //         .map((doc) => ActionModel.fromMap(doc.data()))
  //         .toList();
  //   });
  // }

  void _listenToActionLog() {
    FirebaseFirestore.instance
        .collection('matchData')
        .doc(widget.matchId)
        .collection('matchActions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          setState(() {
            _actionLog = snapshot.docs
                .map((doc) => ActionModel.fromMap(doc.data()))
                .toList();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002B5C); // Dark navy
    const secondaryColor = Color(0xFFFF0000); // Vivid red
    const bgColor = Color(0xFFF1F1F1); // Light background

    if (_isLoading || _match == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator()
        ),
      );
    }

    final selectedTeam = _selectedTeams[0] ? _match!.teamA : _match!.teamB;
    final filteredPlayers = _matchPlayers
        .where((player) => player.teamId == selectedTeam)
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Match Tracking'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Team Names + Scores
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_match!.teamA}\n0.0 (0)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_match!.teamB}\n0.0 (0)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const Divider(),

          // Quarter + Timer + Start Quarter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Q$_quarter - ${_isQuarterRunning ? "Running" : _isMatchFinished ? "Finished" : "Not Started"}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isMatchFinished ? Colors.grey : Colors.black,
                  ),
                ),
                Text(
                  _formatDuration(_elapsedQuarter),
                  style: const TextStyle(fontSize: 16, fontWeight : FontWeight.w600),
                ),
                TextButton(
                  onPressed: _isMatchFinished
                      ? null
                      : _isQuarterRunning
                          ? _endQuarter
                          : _startQuarter,
                  style: TextButton.styleFrom(foregroundColor: secondaryColor),
                  child: Text(
                    _isMatchFinished
                        ? 'Match Finished'
                        : _quarter == 4 && _isQuarterRunning
                            ? 'Finish Match'
                            : _isQuarterRunning
                                ? 'End Quarter'
                                : 'Start Quarter',
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Action Log
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6.0),
            child: Text('Action Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade300,
            child: _actionLog.isEmpty
                ? const Center(child: Text('No actions recorded yet'))
                : ListView.builder(
                    itemCount: _actionLog.length,
                    itemBuilder: (context, index) {
                      final action = _actionLog[index];
                      return Text(
                        '${action.name} - ${_capitalize(action.action)} (Q${action.quarter}, ${_formatDuration(Duration(seconds: action.timeInQuarter))})',
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                ),
          ),

          const Divider(),

          // Player/Team Stats Buttons
          const Text('View Game Stats', style: TextStyle(fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Player Stats')),
                OutlinedButton(onPressed: () {}, child: const Text('Team Stats')),
              ],
            ),
          ),

          const Divider(),

          // End Match Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () {},
              child: const Text('End Match'),
            ),
          ),

          const SizedBox(height: 8.0),

          // Bottom Panel (Team Toggle + Player + Actions)
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Team Toggle
                ToggleButtons(
                  isSelected: _selectedTeams,
                  onPressed: (int index) {
                    setState(() {
                      _selectedTeams = [index == 0, index == 1];
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: primaryColor,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(_match!.teamA),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(_match!.teamB),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Player Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<String>(
                    value: filteredPlayers.any((player) => player.name == _selectedPlayerName)
                        ? _selectedPlayerName
                        : (filteredPlayers.isNotEmpty ? filteredPlayers.first.name : null),
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlayerName = value;
                      });
                    },
                    items: filteredPlayers.map((player) {
                      return DropdownMenuItem(
                        value: player.name,
                        child: Text('${player.number} - ${player.name}'),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // Action Buttons Grid (smaller, square)
                SizedBox(
                  height: 130,
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 2.0,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      'Mark', 'Kick', 'Handball', 'Tackle', 'Goal', 'Behind'
                    ].map((label) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade300,
                          padding: const EdgeInsets.all(0),
                        ),
                        onPressed: () async {
                          if (_selectedPlayerName == null) return;

                          final selectedPlayer = _matchPlayers.firstWhere(
                            (player) => player.name == _selectedPlayerName,
                            orElse: () => throw Exception('Player not found'),
                          );

                          final action = ActionModel(
                            action: label.toLowerCase(),
                            name: selectedPlayer.name,
                            teamId: selectedPlayer.teamId,
                            quarter: _quarter,
                            timeInMatch: _elapsedMatch.inSeconds,
                            timeInQuarter: _elapsedQuarter.inSeconds,
                            timestamp: DateTime.now(),
                          );

                          await FirestoreService().recordPlayerAction(
                            matchId: widget.matchId,
                            name: selectedPlayer.name,
                            teamId: selectedPlayer.teamId,
                            action: action,
                          );

                          print('Recorded: ${action.action} by ${selectedPlayer.name} in quarter $_quarter');
                        },
                        child: Text(label, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _capitalize(String text) =>
      text.isNotEmpty ? text[0].toUpperCase() + text.substring(1) : text;
}