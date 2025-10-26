import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/air_data_provider.dart';
import '../../providers/issue_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/water_issues_card.dart';
import '../widgets/urban_issues_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final airDataProvider = Provider.of<AirDataProvider>(context, listen: false);
    final issueProvider = Provider.of<IssueProvider>(context, listen: false);
    
    // Load Delhi air quality data
    await airDataProvider.fetchDelhiAirData();
    
    // Load issues
    issueProvider.refreshIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Delhi Urban Health Monitor'),
        backgroundColor: const Color(0xFF3CB371),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3CB371), Color(0xFF2E8B57)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${authProvider.userProfile?.name ?? 'User'}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Monitor Delhi\'s air quality and report urban issues',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Air Quality Card
              const Text(
                'Air Quality',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<AirDataProvider>(
                builder: (context, airDataProvider, child) {
                  if (airDataProvider.isLoading) {
                    return const AirQualityCard(
                      airData: null,
                      isLoading: true,
                    );
                  }
                  return AirQualityCard(
                    airData: airDataProvider.currentAirData,
                    isLoading: false,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Water Issues Card
              const Text(
                'Water Issues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<IssueProvider>(
                builder: (context, issueProvider, child) {
                  return WaterIssuesCard(
                    issues: issueProvider.waterIssues,
                    isLoading: issueProvider.isLoading,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Urban Issues Card
              const Text(
                'Urban Issues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<IssueProvider>(
                builder: (context, issueProvider, child) {
                  return UrbanIssuesCard(
                    issues: issueProvider.urbanIssues,
                    isLoading: issueProvider.isLoading,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to report water issue
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report Water Issue - Coming Soon')),
                        );
                      },
                      icon: const Icon(Icons.water_drop),
                      label: const Text('Report Water Issue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to report urban issue
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report Urban Issue - Coming Soon')),
                        );
                      },
                      icon: const Icon(Icons.construction),
                      label: const Text('Report Urban Issue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

