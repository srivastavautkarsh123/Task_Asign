import '../../domain/entities/organization.dart';

class OrganizationDto {
  final String id;
  final String name;
  final String createdAt;

  OrganizationDto({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory OrganizationDto.fromJson(Map<String, dynamic> json) {
    return OrganizationDto(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  Organization toEntity() {
    return Organization(
      id: id,
      name: name,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
