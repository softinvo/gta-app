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

  ProductType({required this.id, required this.name, this.status = 'active'});

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: json['_id'],
      name: json['name'] ?? '',
      status: json['status'] ?? 'active',
    );
  }
}
