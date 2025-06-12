import 'dart:async';
import 'package:afl_stats_app/screens/main_menu_screen.dart';
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
  Duration _totalMatchDuration = Duration.zero;
  Timer? _timer;
  bool _isMatchFinished = false;
  List<ActionModel> _actionLog = [];
  ActionModel? _lastAction;
  int _teamAScore = 0;
  int _teamBScore = 0;
  Timer? _autoEndTimer;

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
    _autoEndTimer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_)
    {
      final now = DateTime.now();
      setState(() {
        _elapsedMatch = now.difference(_matchStartTime!);
        _elapsedQuarter = now.difference(_quarterStartTime!);
      });

      if (_elapsedQuarter.inSeconds >= 20) {
        _endQuarter();
      }
    });

    _autoEndTimer = Timer(const Duration(seconds: 20), () {
      if (_isQuarterRunning && mounted) {
        _endQuarter();
      }
    });
  }

  void _endQuarter() {
    _timer?.cancel();
    _autoEndTimer?.cancel();
    _isQuarterRunning = false;

    if (_quarterStartTime != null) {
      _totalMatchDuration += DateTime.now().difference(_quarterStartTime!);
    }

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

            _teamAScore = _calculateScore(_match!.teamA);
            _teamBScore = _calculateScore(_match!.teamB);
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _match!.teamA,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getLeadingTeam() == _match!.teamA && !_isScoresTied()
                              ? Colors.green
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatScore(_match!.teamA),
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _match!.teamB,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getLeadingTeam() == _match!.teamB && !_isScoresTied()
                              ? Colors.green
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatScore(_match!.teamB),
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Quarter + Timer + Start Quarter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                //Quarter Status Text
                SizedBox(
                  width: 120,
                  child: Text(
                    'Q$_quarter - ${_isQuarterRunning ? "Running" : _isMatchFinished ? "Finished" : "Not Started"}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isMatchFinished ? Colors.grey : Colors.black,
                    ),
                  ),
                ),

                // Timer
                Expanded(
                  child: Center(
                    child: Text(
                      _formatDuration(_elapsedQuarter),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Start/End Quarter Button
                SizedBox(
                  width: 120,
                  child: TextButton(
                    onPressed: _isMatchFinished
                        ? null
                        : _isQuarterRunning
                            ? _endQuarter
                            : _startQuarter,
                    style: TextButton.styleFrom(foregroundColor: secondaryColor),
                    child: Text(
                      _isMatchFinished
                          ? 'Finished'
                          : _quarter == 4 && _isQuarterRunning
                              ? 'Finish Match'
                              : _isQuarterRunning
                                  ? 'End Quarter'
                                  : 'Start Quarter',
                      textAlign: TextAlign.right,
                    ),
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
              onPressed: () async {
                if (_match == null) return;

                final teamAScore = _calculateScore(_match!.teamA);
                final teamBScore = _calculateScore(_match!.teamB);
                String winner;

                if (teamAScore > teamBScore) {
                  winner = _match!.teamA;
                } else if (teamBScore > teamAScore) {
                  winner = _match!.teamB;
                } else {
                  winner = 'Draw';
                }

                await FirebaseFirestore.instance
                    .collection('matchData')
                    .doc(widget.matchId)
                    .update({
                      'status': 'finished',
                      'winner': winner,
                      'finalScoreA': teamAScore,
                      'finalScoreB': teamBScore,
                    });

                setState(() {
                  _isMatchFinished = true;
                });

                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Match Finished'),
                    content: Text(winner == 'Draw'
                        ? 'The match ended in a draw.'
                        : 'The winner is $winner with a score of $teamAScore - $teamBScore.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => MainMenuScreen()),
                  (route) => false,
                );
              },
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
                      final newTeam = _selectedTeams[0] ? _match!.teamA : _match!.teamB;
                      final newFilteredPlayers = _matchPlayers
                          .where((player) => player.teamId == newTeam)
                          .toList();
                      _selectedPlayerName = newFilteredPlayers.isNotEmpty ? newFilteredPlayers.first.name : null;
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

                const SizedBox(height: 20),

                // Action Buttons Grid
                SizedBox(
                  height: 140,
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
                        onPressed: (!_isQuarterRunning || _isMatchFinished)
                          ? null
                          : () async {
                            if (_selectedPlayerName == null) return;

                            final selectedPlayer = _matchPlayers.firstWhere(
                              (player) => player.name == _selectedPlayerName,
                              orElse: () => throw Exception('Player not found'),
                            );

                            if (label == 'Goal') {
                              if (_lastAction == null || _lastAction!.action != 'kick') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Goal must follow a kick.')),
                                );
                                return;
                              }
                              if (_lastAction!.teamId != selectedPlayer.teamId) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Goal must be recorded by the same team as the last kick.')),
                                );
                                return;
                              }
                            }

                            if (label == 'Behind') {
                              if (_lastAction == null || (_lastAction!.action != 'kick' && _lastAction!.action != 'handball')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Behind must follow a kick or handball.')),
                                );
                                return;
                              }
                              if (_lastAction!.teamId != selectedPlayer.teamId) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Behind must be recorded by the same team as the last kick or handball.')),
                                );
                                return;
                              }
                            }

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

                            setState(() {
                              _lastAction = action;
                            });

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

  int _calculateScore(String teamId) {
    final teamActions = _actionLog.where((action) => action.teamId == teamId);
    final goals = teamActions.where((action) => action.action == 'goal').length;
    final behinds = teamActions.where((action) => action.action == 'behind').length;
    return goals * 6 + behinds;
  }

  String _formatScore(String teamId) {
    final teamActions = _actionLog.where((action) => action.teamId == teamId);
    final goals = teamActions.where((action) => action.action == 'goal').length;
    final behinds = teamActions.where((action) => action.action == 'behind').length;
    final total = goals * 6 + behinds;
    return '$goals.$behinds ($total)';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getLeadingTeam() {
    final scoreA = _calculateScore(_match!.teamA);
    final scoreB = _calculateScore(_match!.teamB);
    return scoreA > scoreB ? _match!.teamA : _match!.teamB;
  }

  bool _isScoresTied() {
    final scoreA = _calculateScore(_match!.teamA);
    final scoreB = _calculateScore(_match!.teamB);
    return scoreA == scoreB;
  }

  String _capitalize(String text) =>
      text.isNotEmpty ? text[0].toUpperCase() + text.substring(1) : text;
}