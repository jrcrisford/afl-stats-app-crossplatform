import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/player_model.dart';

class PlayerManagementScreen extends StatefulWidget {
  final String teamName;

  const PlayerManagementScreen({Key? key, required this.teamName}) : super(key: key);

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  final FirestoreService _firestore = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<PlayerModel> _filteredPlayers = [];

  List<PlayerModel> _players = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF002B5C);
  final Color secondaryColor = const Color(0xFFFF0000);
  final Color bgColor = const Color(0xFFF1F1F1);

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _firestore.getAllPlayers();
    setState(() {
      _players = players.where((p) => p.teamId == widget.teamName).toList();
      _filterPlayers();
      _isLoading = false;
    });
  }

  void _filterPlayers() {
    setState(() {
      _filteredPlayers = _players.where((player) {
        return player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            player.number.toString().contains(_searchQuery);
      }).toList();
    });
  }

  void _showAddPlayerDialog() {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Player Number'),
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
              final name = nameController.text.trim();
              final number = int.tryParse(numberController.text.trim());

              if (name.isEmpty || number == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid player details')),
                );
                return;
              }

              final allPlayers = await _firestore.getAllPlayers();
              final nameExists = allPlayers.any((p) => p.name.toLowerCase() == name.toLowerCase());

              if (nameExists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Player "$name" already exists')),
                );
                return;
              }

              final newPlayer = PlayerModel(
                name: name,
                number: number,
                teamId: widget.teamName,
              );

              await _firestore.addPlayer(newPlayer);
              Navigator.pop(context);
              await _loadPlayers();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditPlayerDialog(PlayerModel player) {
    final nameController = TextEditingController(text: player.name);
    final numberController = TextEditingController(text: player.number.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Player Number'),
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
              final newNumber = int.tryParse(numberController.text.trim());

              if (newName.isEmpty || newNumber == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid player details')),
                );
                return;
              }

              final allPlayers = await _firestore.getAllPlayers();
              final nameExists = allPlayers.any((p) => p.name.toLowerCase() == newName.toLowerCase() && p.name != player.name);

              if (nameExists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Player "$newName" already exists')),
                );
                return;
              }

              if (newName.toLowerCase() != player.name.toLowerCase()) {
                await _firestore.deletePlayer(player.name);
              }

              final updatedPlayer = PlayerModel(
                name: newName,
                number: newNumber,
                teamId: player.teamId,
                kick: player.kick,
                handball: player.handball,
                mark: player.mark,
                tackle: player.tackle,
                goal: player.goal,
                behind: player.behind,
              );

              await _firestore.addPlayer(updatedPlayer);
              Navigator.pop(context);
              await _loadPlayers();
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
        title: Text(widget.teamName),
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _showAddPlayerDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Player',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Swipe right on a player to Edit, left to Delete\nTap the image to add a player image',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value.trim();
                _filterPlayers();
              },
              decoration: InputDecoration(
                hintText: 'Search players...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = _filteredPlayers[index];
                return Dismissible(
                  key: Key(player.name),
                  background: Container(
                    color: Colors.green[100],
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.edit, color: primaryColor),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red[100],
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: secondaryColor),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _showEditPlayerDialog(player);
                      return false;
                    } else {
                      final confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Player'),
                          content: Text('Are you sure you want to delete "${player.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      return confirm == true;
                    }
                  },
                  onDismissed: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      await _firestore.deletePlayer(player.name);
                      setState(() {
                        _players.removeAt(index);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${player.name} deleted')),
                      );
                    }
                  },
                  child: ListTile(
                    title: Text('#${player.number} - ${player.name}'),
                    leading: GestureDetector(
                      onTap: () {
                        // TODO: select image
                      },
                      child: const CircleAvatar(child: Icon(Icons.person)),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showEditPlayerDialog(player);
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
}