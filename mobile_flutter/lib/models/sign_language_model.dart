class GestureModel {
  final String status;
  final String predictedCharacter;
  final List<int> boundingBox;

  GestureModel({
    required this.status,
    required this.predictedCharacter,
    required this.boundingBox,
  });

  factory GestureModel.fromJson(Map<String, dynamic> json) {
    return GestureModel(
      status: json['status'],
      predictedCharacter: json['predicted_character'],
      boundingBox: List<int>.from(json['bounding_box']),
    );
  }
}