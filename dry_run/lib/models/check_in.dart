import 'day_status.dart';

class CheckIn {
  final DateTime date;
  final DayStatus status;

  CheckIn({
    required this.date,
    required this.status,
  });

  CheckIn copyWith({
    DateTime? date,
    DayStatus? status,
  }) {
    return CheckIn(
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'status': status.name,
    };
  }

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      date: DateTime.parse(json['date']),
      status: DayStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DayStatus.unknown,
      ),
    );
  }
}