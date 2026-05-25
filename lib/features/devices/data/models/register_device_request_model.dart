class RegisterDeviceRequestModel {
  final String token;
  final int deviceType;
  final String? deviceName;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final String language;

  const RegisterDeviceRequestModel({
    required this.token,
    required this.deviceType,
    required this.language,
    this.deviceName,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'deviceType': deviceType,
    if (deviceName != null && deviceName!.isNotEmpty) 'deviceName': deviceName,
    if (deviceModel != null && deviceModel!.isNotEmpty)
      'deviceModel': deviceModel,
    if (osVersion != null && osVersion!.isNotEmpty) 'osVersion': osVersion,
    if (appVersion != null && appVersion!.isNotEmpty) 'appVersion': appVersion,
    'language': language,
  };
}
