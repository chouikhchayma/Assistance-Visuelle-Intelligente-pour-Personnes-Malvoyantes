import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ViewUsersPage extends StatefulWidget {
  const ViewUsersPage({super.key});

  @override
  State<ViewUsersPage> createState() => _ViewUsersPageState();
}

class _ViewUsersPageState extends State<ViewUsersPage> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _usersList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    _usersRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _usersList = data.entries.map((e) => {
            "id": e.key,
            ...Map<String, dynamic>.from(e.value)
          }).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _usersList = [];
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des utilisateurs'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _usersList.isEmpty
          ? Center(child: Text('Aucun utilisateur trouvé.'))
          : ListView.builder(
        itemCount: _usersList.length,
        itemBuilder: (context, index) {
          final user = _usersList[index];
          return ListTile(
            leading: Icon(Icons.person),
            title: Text(user['name'] ?? 'Nom inconnu'),
            subtitle: Text(user['email'] ?? 'Email inconnu'),
            trailing: Text(user['role'] ?? ''),
          );
        },
      ),
    );
  }
}
