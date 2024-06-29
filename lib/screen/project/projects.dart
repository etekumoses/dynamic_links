// ignore_for_file: deprecated_member_use

import 'package:dynamiclinksapp/models/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/widgets.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectsPage extends StatefulWidget {
  @override
  _ProjectsPageState createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    updatefirestore();
    print("updating done");
    super.initState();
  }

  void updatefirestore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final User? user = FirebaseAuth.instance.currentUser;
    var projectId = await prefs.getString("projectId");
    if (projectId != null) {
      await _firestore.collection('projects').doc(projectId).update({
        'members': FieldValue.arrayUnion([user!.email]),
      });
      await prefs.remove("projectId");
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    if (_projectNameController.text.trim().isEmpty) return;

    try {
      await _firestore.collection('projects').add({
        'name': _projectNameController.text.trim(),
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': Timestamp.now(),
        'members': [FirebaseAuth.instance.currentUser!.email],
      });
      _projectNameController.clear();
    } catch (e) {
      print('Error adding project: $e');
    }
  }

  Future<void> _inviteUser(String projectId) async {
    if (_inviteEmailController.text.trim().isEmpty) return;

    try {
      String email = _inviteEmailController.text.trim();
      String inviteCode = await createDynamicLink(projectId);

      // Store invitation in 'invitations' collection
      await _firestore.collection('invitations').add({
        'email': email,
        'projectId': projectId,
        'invitedAt': Timestamp.now(),
      });

      // Send invitation email to the provided email address
      await sendInvitationEmail(email, inviteCode);

      _inviteEmailController.clear();
      Navigator.of(context).pop();
    } catch (e) {
      print('Error inviting user: $e');
    }
  }

  Future<String> createDynamicLink(String projectId) async {
    try {
      final String businessinviteurl =
          'https://dynamiclink.page.link/invite?projectId=$projectId';

      final DynamicLinkParameters parameters = DynamicLinkParameters(
        link: Uri.parse(businessinviteurl),
        uriPrefix: 'https://dynamiclink.page.link',
        androidParameters: const AndroidParameters(
          packageName:
              "com.example.dynamiclinksapp", // Replace with your app's package name
          minimumVersion: 0,
        ),
      );

      // Build the short dynamic link
      final FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;
      final ShortDynamicLink shortLink = await dynamicLinks.buildShortLink(
        parameters,
        shortLinkType: ShortDynamicLinkType.unguessable,
      );

      return shortLink.shortUrl
          .toString(); // Return the generated dynamic link URL
    } catch (e) {
      print('Error generating dynamic link: $e');
      return ''; // Return empty string or handle error as needed
    }
  }

  Future<void> sendInvitationEmail(String email, String inviteCode) async {
    try {
      final smtpServer =
          SmtpServer('', username: '', password: '', port: 465, ssl: true);

      final message = Message()
        ..from = Address('info@example.com', 'Dynamic Links')
        ..recipients.add(email)
        ..subject = 'Invitation to join project'
        ..text =
            'You have been invited to join a project. Click the link below:\n\n$inviteCode'
        ..html =
            "<p>You have been invited to join a project. Click the link below:</p>\n<p><a href=\"$inviteCode\">Accept Invitation</a></p>";

      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Stream<QuerySnapshot> _getProjectsStream() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    // Query projects where the current user is the owner or is invited
    return _firestore
        .collection('projects')
        .where('members', arrayContainsAny: [userId, userEmail]).snapshots();
  }

  Stream<QuerySnapshot> _getInvitedMembersStream(String projectId) {
    return _firestore
        .collection('invitations')
        .where('projectId', isEqualTo: projectId)
        .snapshots();
  }

  void _showInviteDialog(String projectId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invite User'),
          content: TextField(
            controller: _inviteEmailController,
            decoration: InputDecoration(labelText: 'User Email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _inviteUser(projectId),
              child: Text('Invite'),
            ),
          ],
        );
      },
    );
  }

  void _viewInvitedMembers(String projectId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Invited Members',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _getInvitedMembersStream(projectId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No invited members'));
                  }

                  final members = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        title: Text(member.id), // Assuming member id is user id
                        subtitle: Text('${member['email']}'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Welcome ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _projectNameController,
              decoration: InputDecoration(
                labelText: 'Project Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addProject,
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getProjectsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No projects found'));
                  }

                  final projects = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ListTile(
                        title: Text(project['name']),
                        subtitle: Text('Created by: ${project['createdBy']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: IconButton(
                                icon: Icon(Icons.person_add),
                                onPressed: () => _showInviteDialog(project.id),
                              ),
                            ),
                            Expanded(
                              child: IconButton(
                                icon: Icon(Icons.people),
                                onPressed: () =>
                                    _viewInvitedMembers(project.id),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/task_list',
                            arguments: project.id,
                          );
                        },
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
