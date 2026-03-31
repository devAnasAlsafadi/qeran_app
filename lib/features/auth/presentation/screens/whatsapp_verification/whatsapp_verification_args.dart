import 'whatsapp_verification_mode.dart';

/// Navigation arguments for [WhatsappVerificationScreen].
class WhatsappVerificationArgs {
  final String phoneNumber;
  final WhatsappVerificationMode mode;

  const WhatsappVerificationArgs({
    required this.phoneNumber,
    required this.mode,
  });
}
