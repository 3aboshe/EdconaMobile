class ClassModel {
  final String id;
  final String name;
  final List<String>? subjectIds;

  ClassModel({
    required this.id,
    required this.name,
    this.subjectIds,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subjectIds: (json['subjectIds'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subjectIds': subjectIds,
    };
  }
}
