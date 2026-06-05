import 'day_status.dart';

class CheckIn {
  final DateTime date;
  final DayStatus status;
  final String? note;

  CheckIn({
    required this.date,
    required this.status,
    this.note,
  });

  CheckIn copyWith({
    DateTime? date,
    DayStatus? status,
    // Use a sentinel so callers can explicitly clear the note by passing null.
    Object? note = _keep,
  }) {
    return CheckIn(
      date: date ?? this.date,
      status: status ?? this.status,
      note: identical(note, _keep) ? this.note : note as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'status': status.name,
      if (note != null) 'note': note,
    };
  }

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      date: DateTime.parse(json['date']),
      status: DayStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DayStatus.unknown,
      ),
      note: json['note'] as String?,
    );
  }
}

// Sentinel object used by copyWith to distinguish "not provided" from null.
const Object _keep = Object();
