import 'package:flutter/material.dart';
import '../models/action_model.dart';
import '../models/match_model.dart';
import '../services/firestore_service.dart';

class TeamStatsScreen extends StatefulWidget {
  final String matchId;
  final MatchModel match;

  const TeamStatsScreen({Key? key, required this.matchId, required this.match}) : super(key: key);

  @override
  State<TeamStatsScreen> createState() => _TeamStatsScreenState();
}

class _TeamStatsScreenState extends State<TeamStatsScreen> {
  final FirestoreService _firestore = FirestoreService();
  int _selectedQuarter = 0;
  List<ActionModel> _allActions = [];

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    final actions = await _firestore.getActionsForMatch(widget.matchId);
    setState(() {
      _allActions = actions;
    });
  }

  Map<String, int> _calculateTeamStats(String teamId) {
    final stats = {'disposals': 0, 'marks': 0, 'tackles': 0, 'goals': 0, 'behinds': 0};

    for (var action in _allActions) {
      if (action.teamId != teamId) continue;
      if (_selectedQuarter != 0 && action.quarter != _selectedQuarter) continue;

      if (action.action == 'kick' || action.action == 'handball') stats['disposals'] = stats['disposals']! + 1;
      if (action.action == 'mark') stats['marks'] = stats['marks']! + 1;
      if (action.action == 'tackle') stats['tackles'] = stats['tackles']! + 1;
      if (action.action == 'goal') stats['goals'] = stats['goals']! + 1;
      if (action.action == 'behind') stats['behinds'] = stats['behinds']! + 1;
    }

    return stats;
  }

  TableRow _buildStatRow(String label, int a, int b, {String? customA, String? customB}) {
    final isEqual = a == b;
    final isAHigher = a > b;

    final styleA = TextStyle(fontSize: 16, color: isEqual ? Colors.black : (isAHigher ? Colors.green : Colors.black));
    final styleB = TextStyle(fontSize: 16, color: isEqual ? Colors.black : (!isAHigher ? Colors.green : Colors.black));

    return TableRow(children: [
      Padding(padding: const EdgeInsets.all(8), child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      Padding(padding: const EdgeInsets.all(8), child: Text(customA ?? a.toString(), style: styleA, textAlign: TextAlign.center)),
      Padding(padding: const EdgeInsets.all(8), child: Text(customB ?? b.toString(), style: styleB, textAlign: TextAlign.center)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002B5C);
    const bgColor = Color(0xFFF1F1F1);

    final statsA = _calculateTeamStats(widget.match.teamA);
    final statsB = _calculateTeamStats(widget.match.teamB);

    final scoreA = statsA['goals']! * 6 + statsA['behinds']!;
    final scoreB = statsB['goals']! * 6 + statsB['behinds']!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Compare Team Stats'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              '${widget.match.teamA} vs ${widget.match.teamB}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                _buildStatRow('Disposals', statsA['disposals']!, statsB['disposals']!),
                _buildStatRow('Marks', statsA['marks']!, statsB['marks']!),
                _buildStatRow('Tackles', statsA['tackles']!, statsB['tackles']!),
                _buildStatRow(
                  'Score',
                  scoreA,
                  scoreB,
                  customA: '${statsA['goals']}.${statsA['behinds']} ($scoreA)',
                  customB: '${statsB['goals']}.${statsB['behinds']} ($scoreB)',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ToggleButtons(
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
            )
          ],
        ),
      ),
    );
  }
}