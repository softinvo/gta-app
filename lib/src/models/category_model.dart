class Category {
  final String id;
  final String name;
  final String? thumbnail;
  final String? description;
  final String status;

  Category({
    required this.id,
    required this.name,
    this.thumbnail,
    this.description,
    this.status = 'active',
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'] ?? '',
      thumbnail: json['thumbnail'],
      description: json['description'],
      status: json['status'] ?? 'active',
    );
  }
}

class SubCategory {
  final String id;
  final String name;
  final String? thumbnail;
  final String? description;
  final String status;

  SubCategory({
    required this.id,
    required this.name,
    this.thumbnail,
    this.description,
    this.status = 'active',
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['_id'],
      name: json['name'] ?? '',
      thumbnail: json['thumbnail'],
      description: json['description'],
      status: json['status'] ?? 'active',
    );
  }
}

class ProductType {
  final String id;
  final String name;
  final String status;
  final String? thumbnail;
  final List<ProductAttributeField> fields;

  ProductType({
    required this.id,
    required this.name,
    this.thumbnail,
    this.status = 'active',
    this.fields = const [],
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    return ProductType(
      id: json['_id'],
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
      thumbnail: json['thumbnail'],
      fields: rawFields is List
          ? rawFields
              .whereType<Map>()
              .map(
                (field) => ProductAttributeField.fromJson(
                  Map<String, dynamic>.from(field),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class ProductAttributeField {
  final String id;
  final String fieldName;
  final String fieldType;
  final List<String> options;
  final bool required;

  const ProductAttributeField({
    required this.id,
    required this.fieldName,
    this.fieldType = 'text',
    this.options = const [],
    this.required = false,
  });

  factory ProductAttributeField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return ProductAttributeField(
      id: json['_id']?.toString() ?? json['fieldName']?.toString() ?? '',
      fieldName: json['fieldName']?.toString() ?? '',
      fieldType: json['fieldType']?.toString().toLowerCase() ?? 'text',
      options: rawOptions is List
          ? rawOptions.map((option) => option.toString()).toList()
          : const [],
      required: json['required'] == true,
    );
  }
}
