class Matiere {
  final String nomMat;
  final int codMatiere;
  final String hours; // Separate fields for hours and minutes
  final String minutes;

  Matiere({
    required this.nomMat,
    required this.codMatiere,
    required this.hours,
    required this.minutes,
  });

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      nomMat: json['nomMat'],
      codMatiere: json['codMatiere'],
      hours: json['hours'],
      minutes: json['minutes'],
    );
  }
}
