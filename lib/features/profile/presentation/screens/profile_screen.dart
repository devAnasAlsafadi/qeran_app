import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/widgets/logout_confirmation_dialog.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/subscription_status_block.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Lightweight profile / settings surface rendered inside the home shell
/// when the Profile bottom-nav tab is active. Intentionally minimal in
/// this phase: a user header card and the logout entry. Other sections
/// (edit profile, preferences, language) land in later sprints.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Soft refresh — the cubit short-circuits inside its 60 s TTL so
    // tab navigation doesn't spam /current.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CurrentSubscriptionCubit>().refresh();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<CurrentSubscriptionCubit>().refresh(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: BlocBuilder<UserSessionCubit, UserSessionState>(
            builder: (context, state) {
              final user = state is UserSessionAuthenticated ? state.user : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(name: user?.name, email: user?.email),
                  const SizedBox(height: 24),
                  _MyProfileTile(
                    onTap: () => NavigationManager.navigateTo(
                      context,
                      RouteNames.myProfile,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SubscriptionStatusBlock(),
                  const SizedBox(height: 24),
                  _LogoutTile(onTap: () => _handleLogout(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await LogoutConfirmationDialog.show(context);
    if (!confirmed || !context.mounted) return;
    await context.read<UserSessionCubit>().signOut();
    // Drop the cached subscription so a future sign-in re-hydrates
    // cleanly. The bloc lives at the app root so the same instance
    // survives across login sessions.
    if (context.mounted) {
      context.read<CurrentSubscriptionCubit>().clear();
    }
    if (!context.mounted) return;
    NavigationManager.pushNamedAndRemoveUntil(
      context,
      RouteNames.loginScreen,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String? name;
  final String? email;
  const _ProfileHeader({this.name, this.email});

  @override
  Widget build(BuildContext context) {
    final trimmed = (name ?? '').trim();
    final initial = trimmed.isEmpty ? '' : trimmed.substring(0, 1).toUpperCase();
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
          alignment: Alignment.center,
          child: initial.isEmpty
              ? const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 30,
                )
              : Text(
                  initial,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trimmed.isNotEmpty
                    ? trimmed
                    : LocaleKeys.home_nav_profile.t(context),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Quiet navigation tile that opens the owner-facing `MyProfileScreen`
/// where the user reads their own placements + status banner. Lives
/// here in the Settings tab so the tab content stays a single column
/// of action rows.
class _MyProfileTile extends StatelessWidget {
  final VoidCallback onTap;
  const _MyProfileTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F431C33),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  LocaleKeys.profile_my_title.t(context),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F431C33),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  LocaleKeys.common_logout.t(context),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
