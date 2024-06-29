class ProjectModel {
  final String projectId;
  final String projectName;
  final String projectDescription;
  final List<String> members; // List of user UIDs

  ProjectModel({
    required this.projectId,
    required this.projectName,
    required this.projectDescription,
    required this.members,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      projectId: json['projectId'] ?? '',
      projectName: json['projectName'] ?? '',
      projectDescription: json['projectDescription'] ?? '',
      members: List<String>.from(json['members'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'projectDescription': projectDescription,
      'members': members,
    };
  }
}
