import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Christy Cares'),
        backgroundColor: const Color(0xFF2E7D8A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 80,
                  color: Color(0xFF2E7D8A),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Christy Cares',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D8A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'User',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: Color(0xFF2E7D8A)),
                          title: const Text('Schedule Appointment'),
                          subtitle: const Text('Book a session with a caregiver'),
                          onTap: () {
                            // TODO: Navigate to appointment booking
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Appointment booking coming soon')),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.message, color: Color(0xFF2E7D8A)),
                          title: const Text('Messages'),
                          subtitle: const Text('Chat with your caregiver'),
                          onTap: () {
                            // TODO: Navigate to messages
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Messaging coming soon')),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person, color: Color(0xFF2E7D8A)),
                          title: const Text('Profile'),
                          subtitle: const Text('Manage your account'),
                          onTap: () {
                            // TODO: Navigate to profile
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile management coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(currentUserProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}