import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/air_data_provider.dart';
import '../../providers/issue_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/issue_model.dart';
import '../widgets/air_quality_card.dart';
import '../widgets/water_issues_card.dart';
import '../widgets/urban_issues_card.dart';
import '../issue_submission_screen.dart';

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

    // Load current location air quality data (already loaded in provider constructor)
    // Also load Indian cities data for map
    await airDataProvider.fetchIndianCitiesAirData();

    // Load issues
    issueProvider.refreshIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('NagarSuraksha'),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const IssueSubmissionScreen(
                              issueType: IssueType.water,
                            ),
                          ),
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const IssueSubmissionScreen(
                              issueType: IssueType.urban,
                            ),
                          ),
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
              
              const SizedBox(height: 24),
              
              // Recent Issues Section
              const Text(
                'Recent Issues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<IssueProvider>(
                builder: (context, issueProvider, child) {
                  if (issueProvider.isLoading) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  
                  final recentIssues = issueProvider.allIssues.take(5).toList();
                  
                  if (recentIssues.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.report_problem_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No issues reported yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to report an issue in your area',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: recentIssues.map((issue) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: issue.type == IssueType.water 
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: issue.type == IssueType.water 
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: issue.type == IssueType.water 
                                        ? Colors.blue
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    issue.type == IssueType.water 
                                        ? Icons.water_drop 
                                        : Icons.construction,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        issue.typeDisplayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        issue.description,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: issue.status == 'resolved' 
                                                  ? Colors.green
                                                  : issue.status == 'verified'
                                                      ? Colors.blue
                                                      : Colors.orange,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              issue.status.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${issue.timestamp.day}/${issue.timestamp.month}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

