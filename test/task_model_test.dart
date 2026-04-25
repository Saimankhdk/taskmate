import 'package:capstone_project/models/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('task parsers', () {
    test('parseTaskPriority handles known and fallback values', () {
      expect(parseTaskPriority('low'), TaskPriority.low);
      expect(parseTaskPriority('high'), TaskPriority.high);
      expect(parseTaskPriority('medium'), TaskPriority.medium);
      expect(parseTaskPriority('unknown'), TaskPriority.medium);
      expect(parseTaskPriority(null), TaskPriority.medium);
    });

    test('parseTaskStatus handles known and fallback values', () {
      expect(parseTaskStatus('todo'), TaskStatus.todo);
      expect(parseTaskStatus('inProgress'), TaskStatus.inProgress);
      expect(parseTaskStatus('done'), TaskStatus.done);
      expect(parseTaskStatus('else'), TaskStatus.todo);
      expect(parseTaskStatus(null), TaskStatus.todo);
    });
  });
}
