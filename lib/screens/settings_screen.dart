import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF3CB371),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.userProfile;
                      return Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF3CB371),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(user?.name ?? 'User'),
                            subtitle: Text(user?.email ?? 'user@example.com'),
                            trailing: const Icon(Icons.edit),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit Profile - Coming Soon')),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive updates about air quality'),
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications setting updated')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Location Settings'),
                    subtitle: const Text('Manage location permissions'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Location Settings - Coming Soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delhi Urban Health Monitor v1.0.0')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support - Coming Soon')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy - Coming Soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Logout Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading ? null : () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  icon: authProvider.isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: Text(authProvider.isLoading ? 'Signing out...' : 'Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
