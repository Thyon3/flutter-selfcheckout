//EXTENDED FROM shopping_list.dart
class ToDo {
  String title;
  bool complete;
  String? id;
  DateTime? createdAt;
  DateTime? completedAt;
  String? notes;

  ToDo({
    required this.title,
    this.complete = false,
    this.id,
    this.createdAt,
    this.completedAt,
    this.notes,
  });

  // Constructor for creating from Map (SharedPreferences)
  factory ToDo.fromMap(Map<String, dynamic> map) {
    return ToDo(
      title: map['title'] ?? '',
      complete: map['complete'] ?? false,
      id: map['id'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : null,
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
      notes: map['notes'],
    );
  }

  // Convert to Map for SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'complete': complete,
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  // Toggle completion status
  ToDo toggleComplete() {
    return ToDo(
      title: title,
      complete: !complete,
      id: id,
      createdAt: createdAt,
      completedAt: !complete ? DateTime.now() : null,
      notes: notes,
    );
  }

  // Create a copy with updated title
  ToDo copyWith({String? title, String? notes}) {
    return ToDo(
      title: title ?? this.title,
      complete: complete,
      id: id,
      createdAt: createdAt,
      completedAt: completedAt,
      notes: notes ?? this.notes,
    );
  }

  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  String toString() {
    return 'ToDo(title: $title, complete: $complete, id: $id)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToDo && 
           other.title == title && 
           other.id == id;
  }

  @override
  int get hashCode {
    return title.hashCode ^ (id?.hashCode ?? 0);
  }

  // Get status text
  String get statusText => complete ? 'Completed' : 'Pending';

  // Get status color
  String get statusColor => complete ? 'green' : 'orange';
}
