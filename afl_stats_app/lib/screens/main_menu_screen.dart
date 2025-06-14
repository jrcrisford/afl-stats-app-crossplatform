import 'package:flutter/material.dart';
import 'package:afl_stats_app/screens/create_match_screen.dart';
import 'package:afl_stats_app/screens/team_management_screen.dart';
import 'package:afl_stats_app/screens/match_history_screen.dart';
import '../models/match_model.dart';
import '../services/firestore_service.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final Color primaryColor = const Color(0xFF002B5C);
  final Color bgColor = const Color(0xFFF1F1F1);

  void _showMatchPicker(BuildContext context) async {
    final firestoreService = FirestoreService();

    final selectedMatch = await showModalBottomSheet<MatchModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<List<MatchModel>>(
          future: firestoreService.getAllMatches(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final matches = snapshot.data!;
            if (matches.isEmpty) {
              return const Center(child: Text("No matches found."));
            }

            return ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return ListTile(
                  title: Text("${match.teamA} vs ${match.teamB}"),
                  subtitle: Text("Started: ${match.startTime.toLocal()}"),
                  onTap: () => Navigator.pop(context, match),
                );
              },
            );
          },
        );
      },
    );

    if (selectedMatch != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchHistoryScreen(match: selectedMatch),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AFL Stats Tracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Track player stats, manage teams, and analyze matches.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40.0),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateMatchScreen(),
                  ),
                );
              },
              child: const Text('Create Match'),
            ),

            const SizedBox(height: 16.0),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _showMatchPicker(context),
              child: const Text('Match History'),
            ),

            const SizedBox(height: 16.0),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeamManagementScreen(),
                  ),
                );
              },
              child: const Text('Team Management'),
            ),

            const SizedBox(height: 32.0),

            const Text(
              'Developed by Joshua Crisford\nUTAS KIT305 2025',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}