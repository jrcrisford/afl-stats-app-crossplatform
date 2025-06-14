import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/action_model.dart';
import '../services/firestore_service.dart';
import 'team_stats_screen.dart';
import 'player_stats_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';

class MatchHistoryScreen extends StatefulWidget {
  final MatchModel match;

  const MatchHistoryScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final FirestoreService _firestore = FirestoreService();
  late Future<List<ActionModel>> _actionsFuture;
  int _selectedTab = 0;

  final Color primaryColor = const Color(0xFF002B5C);
  final Color secondaryColor = const Color(0xFFFF0000);
  final Color bgColor = const Color(0xFFF1F1F1);

  @override
  void initState() {
    super.initState();
    _actionsFuture = _firestore.getActionsForMatch(widget.match.id);
  }

  void _onTabTapped(int index) {
    setState(() => _selectedTab = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamStatsScreen(
            matchId: widget.match.id,
            match: widget.match,
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerStatsScreen(matchId: widget.match.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Match History"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ActionModel>>(
        future: _actionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final actions = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildScoreHeader(widget.match, actions),
                  const SizedBox(height: 12),
                  const Text(
                    "Actions List",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: actions.length,
                      itemBuilder: (context, index) {
                        final a = actions[index];
                        final duration = Duration(seconds: a.timeInQuarter);
                        final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
                        final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
                        final timeFormatted = "$minutes:$seconds";

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                "${a.name} – ${a.action} – Q${a.quarter} – $timeFormatted",
                                style: const TextStyle(fontSize: 15),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            if (index < actions.length - 1)
                              const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      final actions = await _actionsFuture;

                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.text_snippet),
                                  title: const Text('Share as Plain Text'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    final text = actions.map((a) {
                                      final d = Duration(seconds: a.timeInQuarter);
                                      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
                                      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
                                      return '${a.name} – ${a.action} – Q${a.quarter} – $m:$s';
                                    }).join('\n');

                                    Share.share(text, subject: 'Match Action List');
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.code),
                                  title: const Text('Share as JSON'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    final jsonText = jsonEncode(actions.map((a) => {
                                      'name': a.name,
                                      'action': a.action,
                                      'quarter': a.quarter,
                                      'timeInQuarter': a.timeInQuarter,
                                    }).toList());

                                    Share.share(jsonText, subject: 'Match Action List (JSON)');
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: const Text("Share Action List"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Teams'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Players'),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(MatchModel match, List<ActionModel> actions) {
    final teamA = match.teamA;
    final teamB = match.teamB;

    final Map<String, Map<int, Score>> scoreMap = {
      teamA: {},
      teamB: {},
    };

    for (var action in actions) {
      final team = action.teamId;
      final quarter = action.quarter;
      final type = action.action;

      if (!scoreMap.containsKey(team)) continue;
      scoreMap[team]![quarter] ??= Score();

      if (type == 'goal') {
        scoreMap[team]![quarter]!.goals += 1;
      } else if (type == 'behind') {
        scoreMap[team]![quarter]!.behinds += 1;
      }
    }

    Score totalA = Score();
    Score totalB = Score();

    for (var q = 1; q <= 4; q++) {
      totalA += scoreMap[teamA]?[q] ?? Score();
      totalB += scoreMap[teamB]?[q] ?? Score();
    }

    final int totalPointsA = totalA.totalPoints;
    final int totalPointsB = totalB.totalPoints;
    final bool isEqual = totalPointsA == totalPointsB;
    final bool isAHigher = totalPointsA > totalPointsB;
    final Color colorA = isEqual ? Colors.black : (isAHigher ? Colors.green : Colors.black);
    final Color colorB = isEqual ? Colors.black : (!isAHigher ? Colors.green : Colors.black);

    // Cumulative quarter score breakdown
    Score runningA = Score();
    Score runningB = Score();

    List<Widget> quarterRows = [];

    for (int q = 1; q <= 4; q++) {
      final a = scoreMap[teamA]?[q] ?? Score();
      final b = scoreMap[teamB]?[q] ?? Score();
      final label = q == 4 ? "Final" : "Quarter $q";

      runningA += a;
      runningB += b;

      final int pointsA = runningA.totalPoints;
      final int pointsB = runningB.totalPoints;
      final bool isEqual = pointsA == pointsB;
      final bool isAHigher = pointsA > pointsB;

      final colA = isEqual ? Colors.black : (isAHigher ? Colors.green : Colors.black);
      final colB = isEqual ? Colors.black : (!isAHigher ? Colors.green : Colors.black);

      quarterRows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(runningA.formatted(), style: TextStyle(color: colA, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: Center(
                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(runningB.formatted(), style: TextStyle(color: colB, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(teamA, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(totalA.formatted(), style: TextStyle(color: colorA, fontSize: 18)),
              ],
            ),
            Column(
              children: [
                Text(teamB, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(totalB.formatted(), style: TextStyle(color: colorB, fontSize: 18)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(thickness: 1.2),
        ...quarterRows,
        const SizedBox(height: 12),
        const Divider(thickness: 1.2),
      ],
    );
  }
}

class Score {
  int goals = 0;
  int behinds = 0;

  int get totalPoints => (goals * 6) + behinds;

  String formatted() => "$goals.$behinds ($totalPoints)";

  Score operator +(Score other) {
    return Score()
      ..goals = goals + other.goals
      ..behinds = behinds + other.behinds;
  }
}