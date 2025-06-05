import 'package:flutter/material.dart';
import 'package:flutter_customer_list/provider/customer_provider.dart';
import 'package:flutter_customer_list/provider/theme_provider.dart';
import 'package:flutter_customer_list/widgets/customer_list_item.dart';
import 'package:flutter_customer_list/widgets/loading_indicator.dart';
import 'package:flutter_customer_list/widgets/search_bar.dart';
import 'package:provider/provider.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scrollController.addListener(_onScroll);
    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().initializeCustomers();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CustomerProvider>().loadMoreCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    key: ValueKey(themeProvider.isDarkMode),
                  ),
                ),
                tooltip:
                    themeProvider.isDarkMode
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                onPressed: themeProvider.toggleTheme,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: const CustomerSearchBar(),
            ),
            // Customer List
            Expanded(
              child: Consumer<CustomerProvider>(
                builder: (context, provider, child) {
                  return _buildContent(provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CustomerProvider provider) {
    switch (provider.loadingState) {
      case LoadingState.initial:
      case LoadingState.loading:
        return const CustomLoadingIndicator(message: 'Loading customers...');
      case LoadingState.searching:
        return const CustomLoadingIndicator(message: 'Searching...');
      case LoadingState.error:
        return _buildErrorState(provider);
      case LoadingState.empty:
        return _buildEmptyState(provider);
      case LoadingState.loaded:
      case LoadingState.loadingMore:
        return _buildCustomerList(provider);
    }
  }

  Widget _buildCustomerList(CustomerProvider provider) {
    final customers = provider.displayedCustomers;
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: customers.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == customers.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: CustomLoadingIndicator(
                message: 'Loading more...',
                showMessage: false,
              ),
            );
          }
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutBack,
            child: CustomerListItem(customer: customers[index], index: index),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(CustomerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(CustomerProvider provider) {
    final isSearchEmpty = provider.isSearching;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchEmpty ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSearchEmpty ? 'No customers found' : 'No customers available',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearchEmpty
                  ? 'Try adjusting your search terms'
                  : 'Check back later for updates',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (isSearchEmpty) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: provider.clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
