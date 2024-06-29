// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import 'screen/auth/login.dart';
import 'screen/auth/register.dart';
import 'screen/project/projects.dart';
import 'screen/project/task.dart';
import 'screen/usermanagement/user_management_page.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/projects': (context) => ProjectsPage(),
        '/task_list': (context) => TasksPage(),
        '/user_management': (context) => UserManagementPage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _projectId;

  @override
  void initState() {
    super.initState();
    _initDynamicLinks();
  }

  Future<void> _initDynamicLinks() async {
    FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

    // Retrieve dynamic link data when the app is in the foreground
    dynamicLinks.onLink.listen(
      (PendingDynamicLinkData? dynamicLink) async {
        final Uri? deepLink = dynamicLink?.link;
        if (deepLink != null) {
          _handleDeepLink(deepLink);
        }
      },
      onError: (e) async {
        print('onLinkError: ${e.message}');
      },
    );

    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      final Uri? deepLink = initialLink.link;
      if (deepLink != null) {
        _handleDeepLink(deepLink);
      }
    }
  }

  void _handleDeepLink(Uri deepLink) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? projectId = deepLink.queryParameters['projectId'];
    if (projectId != null) {
      print(projectId);
      await prefs.setString('projectId', projectId);
      setState(() {
        _projectId = projectId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // Assuming you have a function to get UserModel from FirebaseUser
          UserModel userModel = UserModel(
            uid: snapshot.data!.uid,
            email: snapshot.data!.email ?? '',
            displayName: snapshot.data!.displayName ?? '',
            photoUrl: snapshot.data!.photoURL ?? '',
          );
          return ProjectsPage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
