enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, done }

class TaskModel {
  final String id;
  String title;
  String description;
  List<String> assignedToUids;
  List<String> assignedToNames;
  TaskPriority priority;
  TaskStatus status;
  DateTime? dueDate;
  final String? groupId;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToUids,
    required this.assignedToNames,
    required this.priority,
    required this.status,
    this.dueDate,
    this.groupId,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
  });
}

TaskPriority parseTaskPriority(String? raw) {
  switch (raw) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    default:
      return TaskPriority.medium;
  }
}

TaskStatus parseTaskStatus(String? raw) {
  switch (raw) {
    case 'inProgress':
      return TaskStatus.inProgress;
    case 'done':
      return TaskStatus.done;
    default:
      return TaskStatus.todo;
  }
}
