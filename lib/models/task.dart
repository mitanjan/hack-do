import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  Priority priority;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  int colorIndex;

  @HiveField(8)
  bool isOngoing;

  @HiveField(9)
  DateTime? ongoingStartTime;

  @HiveField(10)
  int elapsedSeconds;

  @HiveField(11)
  String progress;

  @HiveField(12)
  DateTime lastModifiedAt;

  int get totalElapsedSeconds {
    int total = elapsedSeconds;
    if (isOngoing && ongoingStartTime != null) {
      total += DateTime.now().difference(ongoingStartTime!).inSeconds;
    }
    return total;
  }

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = Priority.medium,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.colorIndex = 0,
    this.isOngoing = false,
    this.ongoingStartTime,
    this.elapsedSeconds = 0,
    this.progress = '',
    DateTime? lastModifiedAt,
  }) : lastModifiedAt = lastModifiedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.index,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'colorIndex': colorIndex,
        'isOngoing': isOngoing,
        'ongoingStartTime': ongoingStartTime?.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'progress': progress,
        'lastModifiedAt': lastModifiedAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        priority: Priority.values[json['priority'] as int? ?? 1],
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        colorIndex: json['colorIndex'] as int? ?? 0,
        isOngoing: json['isOngoing'] as bool? ?? false,
        ongoingStartTime: json['ongoingStartTime'] != null
            ? DateTime.parse(json['ongoingStartTime'] as String)
            : null,
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        progress: json['progress'] as String? ?? '',
        lastModifiedAt: json['lastModifiedAt'] != null
            ? DateTime.parse(json['lastModifiedAt'] as String)
            : null,
      );
}
