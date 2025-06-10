import 'package:flutter/material.dart';
import 'package:afl_stats_app/screens/team_management_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AFL Stats Tracker')),
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

            // Create Match Button
            ElevatedButton(
              onPressed: () {
                // TODO Navigation
              },
              child: const Text('Create Match'),
            ),

            const SizedBox(height: 16.0),

            // Match History Button
            ElevatedButton(
              onPressed: () {
                // TODO Navigation
              },
              child: const Text('Match History'),
            ),

            const SizedBox(height: 16.0),

            // Team Management Button
            ElevatedButton(
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
          ],
        ),
      ),
    );
  }
}