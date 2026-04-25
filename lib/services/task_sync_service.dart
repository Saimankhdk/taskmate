import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class TaskSyncService {
  final FirebaseFirestore? firestore;

  TaskSyncService({FirebaseFirestore? firestore}) : firestore = firestore;

  List<TaskModel> tasksFromSnapshot(QuerySnapshot snapshot) {
    final next = <TaskModel>[];
    for (final doc in snapshot.docs) {
      final m = (doc.data() as Map<String, dynamic>?) ?? {};
      next.add(
        TaskModel(
          id: doc.id,
          title: (m['title'] as String?) ?? '',
          description: (m['description'] as String?) ?? '',
          assignedToUids:
              ((m['assignedToUids'] as List?)?.cast<String>() ?? const []),
          assignedToNames:
              ((m['assignedToNames'] as List?)?.cast<String>() ?? const []),
          priority: parseTaskPriority((m['priority'] as String?)),
          status: parseTaskStatus((m['status'] as String?)),
          dueDate: (m['dueDate'] as Timestamp?)?.toDate(),
          groupId: (m['groupId'] as String?),
          createdByUid: (m['createdByUid'] as String?) ?? '',
          createdByName: (m['createdByName'] as String?) ?? '',
          createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
      );
    }
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return next;
  }

  Future<void> updateTaskFields(
    String taskId,
    Map<String, dynamic> fields,
  ) async {
    await _firestore.collection('tasks').doc(taskId).set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;
}
