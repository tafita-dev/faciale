import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/logo.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch latest profile data when navigating to this screen
    Future.microtask(() {
      ref.read(authProvider.notifier).fetchProfile();
    });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('logout'.tr()),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('profile'.tr())),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Center(
                child: NeumorphicCard(
                  borderRadius: 80,
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(72),
                    child: authState.photoUrl != null && authState.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: authState.photoUrl!,
                            width: 144,
                            height: 144,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 144,
                              height: 144,
                              color: AppColors.accent,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildPlaceholderAvatar(),
                          )
                        : _buildPlaceholderAvatar(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      authState.name ?? 'user'.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: NeumorphicCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  borderRadius: 20,
                  child: Text(
                    authState.role?.toUpperCase() ?? 'USER',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              _buildActionItem(
                icon: Icons.settings,
                title: 'settings'.tr(),
                onTap: () => context.push('/settings'),
              ),
              if (authState.role == 'admin') ...[
                const SizedBox(height: 16),
                _buildActionItem(
                  icon: Icons.business,
                  title: 'organization_settings'.tr(),
                  onTap: () => context.push('/admin/org/settings'),
                ),
              ],
              const SizedBox(height: 16),
              _buildActionItem(
                icon: Icons.logout,
                title: 'logout'.tr(),
                color: AppColors.error,
                onTap: _showLogoutConfirmation,
              ),
              const SizedBox(height: 48),
              const Center(child: Logo(size: 20)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 144,
      height: 144,
      color: AppColors.accent,
      child: const Icon(
        Icons.person,
        size: 80,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return NeumorphicCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color == AppColors.error ? AppColors.error : Colors.black,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
}
