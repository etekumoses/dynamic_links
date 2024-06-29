import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TextEditingController _taskNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String projectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    projectId = ModalRoute.of(context)!.settings.arguments as String;
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (_taskNameController.text.trim().isEmpty) return;

    try {
      await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .add({
        'title': _taskNameController.text.trim(),
        'status': 'incomplete',
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': Timestamp.now(),
      });
      _taskNameController.clear();
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Stream<QuerySnapshot> _getTasksStream() {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(
                labelText: 'Task Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No tasks found'));
                  }

                  final tasks = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        title: Text(task['title']),
                        subtitle: Text('Status: ${task['status']}'),
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
