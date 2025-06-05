import 'package:flutter/material.dart';
import 'package:flutter_customer_list/provider/customer_provider.dart';
import 'package:provider/provider.dart';

class CustomerSearchBar extends StatefulWidget {
  const CustomerSearchBar({super.key});
  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: provider.searchCustomers,
          decoration: InputDecoration(
            hintText: 'Search customers by name...',
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.search),
            ),
            suffixIcon:
                _controller.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        provider.clearSearch();
                        _focusNode.unfocus();
                      },
                      tooltip: 'Clear search',
                    )
                    : null,
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        );
      },
    );
  }
}
