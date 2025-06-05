import 'dart:async';
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

enum LoadingState {
  initial,
  loading,
  loadingMore,
  searching,
  loaded,
  error,
  empty,
}

class CustomerProvider extends ChangeNotifier {
  // State variables
  List<Customer> _customers = [];
  List<Customer> _searchResults = [];
  LoadingState _loadingState = LoadingState.initial;
  String _errorMessage = '';
  String _searchQuery = '';
  // Pagination
  static const int _limit = 10;
  int _currentSkip = 0;
  bool _hasMoreData = true;
  // Search debouncing
  Timer? _searchTimer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);
  // Getters
  List<Customer> get customers => _customers;
  List<Customer> get searchResults => _searchResults;
  LoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _searchQuery.isNotEmpty;
  List<Customer> get displayedCustomers =>
      isSearching ? _searchResults : _customers;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isLoadingMore => _loadingState == LoadingState.loadingMore;
  bool get isSearchingState => _loadingState == LoadingState.searching;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isEmpty => _loadingState == LoadingState.empty;
  // Initialize and load first page
  Future<void> initializeCustomers() async {
    if (_customers.isNotEmpty) return;
    _setLoadingState(LoadingState.loading);
    _currentSkip = 0;
    _hasMoreData = true;
    try {
      final customers = await ApiService.fetchCustomers(
        limit: _limit,
        skip: _currentSkip,
      );
      _customers = customers;
      _currentSkip = customers.length;
      _hasMoreData = customers.length == _limit;
      _setLoadingState(
        customers.isEmpty ? LoadingState.empty : LoadingState.loaded,
      );
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // Load more customers for pagination
  Future<void> loadMoreCustomers() async {
    if (!_hasMoreData ||
        _loadingState == LoadingState.loadingMore ||
        isSearching) {
      return;
    }
    _setLoadingState(LoadingState.loadingMore);
    try {
      final newCustomers = await ApiService.fetchCustomers(
        limit: _limit,
        skip: _currentSkip,
      );
      // Prevent duplicates
      final uniqueNewCustomers =
          newCustomers
              .where(
                (newCustomer) =>
                    !_customers.any(
                      (existing) => existing.id == newCustomer.id,
                    ),
              )
              .toList();
      _customers.addAll(uniqueNewCustomers);
      _currentSkip += newCustomers.length;
      _hasMoreData = newCustomers.length == _limit;
      _setLoadingState(LoadingState.loaded);
    } catch (e) {
      _setLoadingState(LoadingState.loaded); // Keep existing data
      _showErrorMessage(e.toString());
    }
  }

  // Search customers with debouncing
  void searchCustomers(String query) {
    _searchQuery = query.trim();
    // Cancel previous timer
    _searchTimer?.cancel();
    if (_searchQuery.isEmpty) {
      _clearSearch();
      return;
    }
    // Set searching state immediately for UI feedback
    if (_loadingState != LoadingState.searching) {
      _setLoadingState(LoadingState.searching);
    }
    // Debounce search
    _searchTimer = Timer(_searchDebounceDelay, () {
      _performSearch();
    });
  }

  // Perform actual search
  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) return;
    try {
      final results = await ApiService.searchCustomers(_searchQuery);
      _searchResults = results;
      _setLoadingState(
        results.isEmpty ? LoadingState.empty : LoadingState.loaded,
      );
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // Clear search and return to paginated list
  void _clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    _searchTimer?.cancel();
    if (_customers.isEmpty) {
      _setLoadingState(LoadingState.initial);
    } else {
      _setLoadingState(LoadingState.loaded);
    }
  }

  // Clear search public method
  void clearSearch() {
    _clearSearch();
  }

  // Retry loading
  Future<void> retry() async {
    if (isSearching) {
      _performSearch();
    } else {
      await initializeCustomers();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    _customers.clear();
    _searchResults.clear();
    _currentSkip = 0;
    _hasMoreData = true;
    _searchQuery = '';
    _searchTimer?.cancel();
    await initializeCustomers();
  }

  // Helper methods
  void _setLoadingState(LoadingState state) {
    if (_loadingState != state) {
      _loadingState = state;
      notifyListeners();
    }
  }

  void _handleError(String error) {
    _errorMessage = error;
    _setLoadingState(LoadingState.error);
  }

  void _showErrorMessage(String error) {
    _errorMessage = error;
    // Don't change loading state, just show error message
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
