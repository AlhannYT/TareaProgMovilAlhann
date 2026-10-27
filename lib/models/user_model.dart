class UserModel {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final String companyName;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.companyName,
  });

  /// Crea una instancia de [UserModel] soportando tanto el formato anidado de
  /// JSONPlaceholder (`company.name`) como el formato plano de la base de datos SQLite (`companyName`).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    String company = '';
    if (json['company'] is Map) {
      company = (json['company'] as Map)['name']?.toString() ?? '';
    } else if (json['companyName'] != null) {
      company = json['companyName'].toString();
    }

    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      companyName: company,
    );
  }

  /// Alias de [fromJson] para compatibilidad explícita con SQLite.
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel.fromJson(map);

  /// Convierte el modelo a un mapa plano apto para almacenamiento en SQLite o JSON.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'website': website,
      'companyName': companyName,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? website,
    String? companyName,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      companyName: companyName ?? this.companyName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
