import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskService {
  static const String _boxName = 'tasks';
  static const String _deletedBoxName = 'deleted_task_ids';
  late Box<Task> _box;
  late Box<String> _deletedBox;
  final _uuid = const Uuid();

  Future<void> init() async {
    _box = await Hive.openBox<Task>(_boxName);
    _deletedBox = await Hive.openBox<String>(_deletedBoxName);
  }

  List<Task> getAll() {
    return _box.values.toList();
  }

  Future<Task> add({
    required String title,
    String description = '',
    Priority priority = Priority.medium,
    DateTime? dueDate,
    int colorIndex = 0,
    String progress = '',
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      colorIndex: colorIndex,
      progress: progress,
      lastModifiedAt: now,
    );
    await _box.put(task.id, task);
    return task;
  }

  Future<void> update(Task task) async {
    task.lastModifiedAt = DateTime.now();
    await _box.put(task.id, task);
  }

  Future<void> delete(String id) async {
    await _deletedBox.put(id, id);
    await _box.delete(id);
  }

  Future<void> toggleComplete(String id) async {
    final task = _box.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      task.lastModifiedAt = DateTime.now();
      await task.save();
    }
  }

  void toggleOngoing(String id) {
    final task = _box.get(id);
    if (task == null) return;
    if (task.isOngoing) {
      if (task.ongoingStartTime != null) {
        task.elapsedSeconds +=
            DateTime.now().difference(task.ongoingStartTime!).inSeconds;
      }
      task.isOngoing = false;
      task.ongoingStartTime = null;
    } else {
      task.isOngoing = true;
      task.ongoingStartTime = DateTime.now();
    }
    task.lastModifiedAt = DateTime.now();
    task.save();
  }

  void resetTimer(String id) {
    final task = _box.get(id);
    if (task == null) return;
    task.isOngoing = false;
    task.ongoingStartTime = null;
    task.elapsedSeconds = 0;
    task.lastModifiedAt = DateTime.now();
    task.save();
  }

  Set<String> getDeletedIds() {
    return _deletedBox.values.toSet();
  }

  List<Map<String, dynamic>> getAllAsJson() {
    return _box.values.map((t) => t.toJson()).toList();
  }

  /// Merges remote tasks into local storage.
  /// Returns (added, updated) counts.
  Future<(int, int)> mergeTasks(
    List<Map<String, dynamic>> remoteTasks,
    List<String> remoteDeletedIds,
  ) async {
    int added = 0;
    int updated = 0;

    // Apply remote deletions locally
    for (final id in remoteDeletedIds) {
      if (_box.containsKey(id)) {
        await _box.delete(id);
      }
      await _deletedBox.put(id, id);
    }

    final localDeletedIds = getDeletedIds();

    for (final json in remoteTasks) {
      final remoteTask = Task.fromJson(json);

      // Skip tasks that are deleted locally
      if (localDeletedIds.contains(remoteTask.id)) continue;

      final localTask = _box.get(remoteTask.id);
      if (localTask == null) {
        // New task from remote
        await _box.put(remoteTask.id, remoteTask);
        added++;
      } else {
        // Conflict: keep the one with later lastModifiedAt
        if (remoteTask.lastModifiedAt.isAfter(localTask.lastModifiedAt)) {
          await _box.put(remoteTask.id, remoteTask);
          updated++;
        }
      }
    }

    return (added, updated);
  }
}
