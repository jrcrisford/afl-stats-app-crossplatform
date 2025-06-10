import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/team_model.dart';
import 'package:afl_stats_app/screens/player_management_screen.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final FirestoreService _firestore = FirestoreService();

  List<TeamModel> _teams = [];
  Map<String, int> _playerCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
   _loadTeamsAndPlayers();
  }

  Future<void> _loadTeamsAndPlayers() async {
    final teams = await _firestore.getAllTeams();
    final players = await _firestore.getAllPlayers();

    final playerCounts = <String, int>{};
    for (var team in teams) {
      playerCounts[team.name] = players
          .where((player) => player.teamId == team.name)
          .length;
    }

    setState(() {
      _teams = teams;
      _playerCounts = playerCounts;
      _isLoading = false;
    });
  }

  void _showAddTeamDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Team'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newTeam = TeamModel(
                  name: name,
                  createdAt: DateTime.now(),
                );
                await _firestore.addTeam(newTeam);
                Navigator.pop(context);
                _loadTeamsAndPlayers();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(TeamModel team) {
    final nameController = TextEditingController(text: team.name);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit team name for ${team.name}:'),
              const SizedBox(height: 8.0),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != team.name) {
                  await _firestore.renameTeam(oldName: team.name, newName: newName);
                  Navigator.pop(context);
                  _loadTeamsAndPlayers();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _showAddTeamDialog,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text(
                'Add Team',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Swipe right on a team to Edit, left to Delete.\nTap a team to add/remove players.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      final count = _playerCounts[team.name] ?? 0;

                      return Dismissible(
                        key: Key(team.name),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20.0),
                          child: const Icon(Icons.edit, color: Colors.black),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.black),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Edit team
                            _showEditTeamDialog(team);
                            return false;
                            } else {
                            // Delete team
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Team'),
                                content: Text('Are you sure you want to delete ${team.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _firestore.deleteTeam(team.name);
                              _loadTeamsAndPlayers();
                              return true;
                            }
                            return false;
                          }
                        },
                        child: ListTile(
                          title: Text('${team.name} ($count players)'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerManagementScreen(teamName: team.name),
                              ),
                            );
                          },
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}