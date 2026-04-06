import 'package:equatable/equatable.dart';

class Alarm extends Equatable {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? audioPath;
  final bool isActive;
  final bool isOneTime;

  const Alarm({
    required this.id,
    required this.title,
    required this.dateTime,
    this.audioPath,
    this.isActive = true,
    this.isOneTime = true,
  });

  Alarm copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    String? audioPath,
    bool? isActive,
    bool? isOneTime,
  }) {
    return Alarm(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      audioPath: audioPath ?? this.audioPath,
      isActive: isActive ?? this.isActive,
      isOneTime: isOneTime ?? this.isOneTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'audioPath': audioPath,
      'isActive': isActive ? 1 : 0,
      'isOneTime': isOneTime ? 1 : 0,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      title: map['title'],
      dateTime: DateTime.parse(map['dateTime']),
      audioPath: map['audioPath'],
      isActive: map['isActive'] == 1,
      isOneTime: map['isOneTime'] == 1,
    );
  }

  @override
  List<Object?> get props => [id, title, dateTime, audioPath, isActive, isOneTime];
}
