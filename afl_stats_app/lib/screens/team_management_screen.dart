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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Color primaryColor = const Color(0xFF002B5C);
  final Color secondaryColor = const Color(0xFFFF0000);
  final Color bgColor = const Color(0xFFF1F1F1);

  List<TeamModel> _teams = [];
  Map<String, int> _playerCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _loadTeamsAndPlayers();
      });
    });

    _loadTeamsAndPlayers();
  }

  Future<void> _loadTeamsAndPlayers() async {
    final teams = await _firestore.getAllTeams();
    final players = await _firestore.getAllPlayers();

    final playerCounts = <String, int>{};
    for (var team in teams) {
      playerCounts[team.name] =
          players.where((player) => player.teamId == team.name).length;
    }

    setState(() {
      _teams = teams.where((team) {
        return team.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
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

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team name cannot be empty')),
                );
                return;
              }

              final duplicate = _teams.any((team) => team.name.toLowerCase() == name.toLowerCase());
              if (duplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team name already exists')),
                );
                return;
              }

              final newTeam = TeamModel(
                name: name,
                createdAt: DateTime.now(),
              );

              await _firestore.addTeam(newTeam);
              Navigator.pop(context);
              _loadTeamsAndPlayers();
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

              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team name cannot be empty')),
                );
                return;
              }

              final duplicate = _teams.any((t) => t.name.toLowerCase() == newName.toLowerCase() && t.name != team.name);
              if (duplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Team name already exists')),
                );
                return;
              }

              if (newName != team.name) {
                await _firestore.renameTeam(oldName: team.name, newName: newName);
                Navigator.pop(context);
                _loadTeamsAndPlayers();
              } else {
                Navigator.pop(context);
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
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Team Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _showAddTeamDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Team',
                style: TextStyle(color: Colors.white),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                    color: Colors.green[100]!,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Icon(Icons.edit, color: primaryColor),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red[100]!,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Icon(Icons.delete, color: secondaryColor),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _showEditTeamDialog(team);
                      return false;
                    } else {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Team'),
                          content: Text(
                              'Are you sure you want to delete ${team.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        if ((_playerCounts[team.name] ?? 0) > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Cannot delete '${team.name}' with players assigned.")),
                          );
                          return false;
                      }
                        await _firestore.deleteTeam(team.name);
                        _loadTeamsAndPlayers();
                        return true;
                      }
                      return false;
                    }
                  },
                  child: ListTile(
                    title: Text('${team.name} ($count players)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerManagementScreen(teamName: team.name,),
                        ),
                      );
                      Future.delayed(Duration(microseconds: 100), () {
                        _loadTeamsAndPlayers();
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}