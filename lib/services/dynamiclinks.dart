import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DynamicLinksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> handleDynamicLinks(BuildContext context) async {
    // Initialize Firebase Dynamic Links
    FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

    // Retrieve dynamic link data when the app is in the foreground
    dynamicLinks.onLink.listen((PendingDynamicLinkData? dynamicLink) async {
      final Uri? deepLink = dynamicLink?.link;

      if (deepLink != null) {
        print('Dynamic Link: ${deepLink.toString()}');

        // Extract invite code or project ID from the dynamic link
        if (deepLink.queryParameters.containsKey('projectId')) {
          String projectId = deepLink.queryParameters['projectId'] ?? '';

          // Check if the project exists or handle as needed
          DocumentSnapshot projectSnapshot =
              await _firestore.collection('projects').doc(projectId).get();
          if (projectSnapshot.exists) {
            String userId = FirebaseAuth.instance.currentUser!.uid;

            // Add user to the project's members subcollection
            await _firestore
                .collection('projects')
                .doc(projectId)
                .collection('members')
                .doc(userId);

            // Optionally, perform additional actions like navigating to a specific page
            // Navigator.pushNamed(context, '/project-details', arguments: projectId);
          } else {
            print('Project not found');
            // Handle project not found scenario
          }
        }
      }
    }, onError: (e) {
      print('Dynamic Link Error: ${e.message}');
    });

    // Check if the app was launched with a dynamic link
    final PendingDynamicLinkData? data = await dynamicLinks.getInitialLink();
    final Uri? deepLink = data?.link;

    if (deepLink != null) {
      print('Dynamic Link on launch: ${deepLink.toString()}');
      return deepLink.queryParameters['projectId'];
    }

    return null;
  }
}
