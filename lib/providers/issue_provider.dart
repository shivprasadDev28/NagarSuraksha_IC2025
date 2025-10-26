import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../services/firestore_service.dart';

class IssueProvider extends ChangeNotifier {
  List<Issue> _waterIssues = [];
  List<Issue> _urbanIssues = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Issue> get waterIssues => _waterIssues;
  List<Issue> get urbanIssues => _urbanIssues;
  List<Issue> get allIssues => [..._waterIssues, ..._urbanIssues];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  IssueProvider() {
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    _setLoading(true);
    _clearError();

    try {
      _waterIssues = await FirestoreService.getIssues(IssueType.water);
      _urbanIssues = await FirestoreService.getIssues(IssueType.urban);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reportIssue(Issue issue) async {
    _setLoading(true);
    _clearError();

    try {
      await FirestoreService.reportIssue(issue);
      
      // Add to local list
      if (issue.type == IssueType.water) {
        _waterIssues.insert(0, issue);
      } else {
        _urbanIssues.insert(0, issue);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Issue>> getNearbyIssues(double latitude, double longitude, double radiusKm, IssueType type) async {
    try {
      return await FirestoreService.getNearbyIssues(latitude, longitude, radiusKm, type);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<Map<String, int>> getIssueCountsByDate(IssueType type, DateTime startDate, DateTime endDate) async {
    try {
      return await FirestoreService.getIssueCountsByDate(type, startDate, endDate);
    } catch (e) {
      _errorMessage = e.toString();
      return {};
    }
  }

  List<Issue> getIssuesByType(IssueType type) {
    switch (type) {
      case IssueType.water:
        return _waterIssues;
      case IssueType.urban:
        return _urbanIssues;
    }
  }

  int getTotalIssueCount() {
    return _waterIssues.length + _urbanIssues.length;
  }

  int getIssueCountByType(IssueType type) {
    switch (type) {
      case IssueType.water:
        return _waterIssues.length;
      case IssueType.urban:
        return _urbanIssues.length;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void refreshIssues() {
    _loadIssues();
  }
}

