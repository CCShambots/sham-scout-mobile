class Shift {

  Shift({
    required this.scouter,
    required this.station,
    required this.matchStart,
    required this.matchEnd
  });

  factory Shift.fromJson(Map<String, dynamic> data) {

    final scouter = data['scouter'] as String;
    final station = data['station'] as int;
    final matchStart = data["match_start"] as int;
    final matchEnd = data["match_end"] as int;

    return Shift(scouter: scouter, station: station, matchStart: matchStart, matchEnd: matchEnd);
  }

  static String generateCode(String scouter, List<Shift> shifts) {
    String code = "sch:$scouter:";

    shifts
        .where((e) => e.scouter == scouter)
        .toList()
        .forEach((value) => code += "s${value.station}m${value.matchStart != value.matchEnd ? "${value.matchStart}-${value.matchEnd}" : value.matchStart},"
        )
    ;

    return code;
  }

  final String scouter;
  final int station;
  final int matchStart;
  final int matchEnd;
}