import 'package:flutter/material.dart';

class MatchTrackingScreen extends StatelessWidget {
  final String matchId;

  const MatchTrackingScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Tracking'),
      ),
      body: Center(
        child: Text('Tracking Match ID: $matchId'),
      ),
    );
  }
}