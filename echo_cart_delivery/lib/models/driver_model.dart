class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String licenseNumber;
  final String vehicleNumber;
  final String vehicleType;
  final String status; // active, inactive, on_delivery
  final String profileImage;
  final double rating;
  final int totalDeliveries;
  final String address;
  final String city;
  final bool profileCompleted;
  final String profilePictureUrl;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.licenseNumber,
    required this.vehicleNumber,
    required this.vehicleType,
    this.status = 'active',
    this.profileImage = '',
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.address = '',
    this.city = '',
    this.profileCompleted = false,
    this.profilePictureUrl = '',
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? json['phoneNo'] ?? '',
      email: json['email'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      status: json['status'] ?? 'active',
      profileImage: json['profileImage'] ?? json['profilePictureUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      profileCompleted: json['profileCompleted'] == true,
      profilePictureUrl:
          json['profilePictureUrl'] ?? json['profilePicture'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'licenseNumber': licenseNumber,
      'vehicleNumber': vehicleNumber,
      'vehicleType': vehicleType,
      'status': status,
      'profileImage': profileImage,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'address': address,
      'city': city,
      'profileCompleted': profileCompleted,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? licenseNumber,
    String? vehicleNumber,
    String? vehicleType,
    String? status,
    String? profileImage,
    double? rating,
    int? totalDeliveries,
    String? address,
    String? city,
    bool? profileCompleted,
    String? profilePictureUrl,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      address: address ?? this.address,
      city: city ?? this.city,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
