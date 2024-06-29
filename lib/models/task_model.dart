class TaskModel {
  final String taskId;
  final String taskName;
  final String assignedTo; // User UID
  final bool isCompleted;

  TaskModel({
    required this.taskId,
    required this.taskName,
    required this.assignedTo,
    required this.isCompleted,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['taskId'] ?? '',
      taskName: json['taskName'] ?? '',
      assignedTo: json['assignedTo'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskName': taskName,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
    };
  }
}
