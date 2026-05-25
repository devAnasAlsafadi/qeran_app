class LinkDeviceRequestModel {
  final String token;

  const LinkDeviceRequestModel({required this.token});

  Map<String, dynamic> toJson() => {'token': token};
}
