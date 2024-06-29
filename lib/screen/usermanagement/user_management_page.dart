import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _inviteUser(String email) async {
    if (email.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('invitations').add({
        'email': email.trim(),
        'invitedBy': FirebaseAuth.instance.currentUser!.uid,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
      _emailController.clear();
    } catch (e) {
      print('Error inviting user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'User Email',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _inviteUser(_emailController.text),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No users found'));
                  }

                  final users = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user['email']),
                        // subtitle: Text('Status: ${user['status']}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
