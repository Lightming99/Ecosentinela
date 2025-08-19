import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/analytics_provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_section.dart';
import 'widgets/analytics_section.dart';
import 'widgets/history_section.dart';

final profileRefreshProvider = StateProvider<int>((ref) => 0);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshProfile() {
    ref.read(profileRefreshProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the refresh provider to trigger rebuilds
    ref.watch(profileRefreshProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: AnimationLimiter(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                // Profile Header
                const ProfileHeader(),
                
                const SizedBox(height: 24),
                
                // Settings Section
                const SettingsSection(),
                
                const SizedBox(height: 24),
                
                // Analytics Section
                const AnalyticsSection(),
                
                const SizedBox(height: 24),
                
                // History Section
                const HistorySection(),
                
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
