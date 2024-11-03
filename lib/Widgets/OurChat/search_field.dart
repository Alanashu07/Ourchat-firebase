import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearchScreen;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final double borderRadius;
  const SearchField({super.key, required this.controller, this.borderRadius = 12, this.isSearchScreen = false, this.onTap, this.onSubmitted, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onTap: onTap,
      readOnly: !isSearchScreen,
      autofocus: isSearchScreen,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_sharp),
          hintText: "Search",
          hintStyle: const TextStyle(fontSize: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Colors.black12)
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Colors.black12)
          ),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: Colors.deepPurple)
          ),
          fillColor: Colors.grey.shade100,
          filled: true
      ),
    );
  }
}
