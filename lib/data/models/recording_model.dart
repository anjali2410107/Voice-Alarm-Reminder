import 'package:equatable/equatable.dart';

class Recording extends Equatable {
  final String id;
  final String name;
  final String path;
  final DateTime dateTime;

  const Recording({
    required this.id,
    required this.name,
    required this.path,
    required this.dateTime,
  });

  Recording copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? dateTime,
  }) {
    return Recording(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
    );
  }

  @override
  List<Object?> get props => [id, name, path, dateTime];
}
