import 'package:flutter/material.dart';

class SearchableSelect<T> extends FormField<T> {
  final List<T> items;
  final String Function(T) itemLabel;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String hint;
  final String labelText;

  SearchableSelect({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.selectedValue,
    required this.onChanged,
    this.hint = 'Cari...',
    required this.labelText,
    super.validator,
    super.onSaved,
  }) : super(
          initialValue: selectedValue,
          builder: (FormFieldState<T> state) {
            final context = state.context;
            final displayLabel = state.value != null 
                ? itemLabel(state.value as T) 
                : 'Pilih $labelText';

            void showSearchSheet() {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.8,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) {
                      return _SearchSheetBody<T>(
                        items: items,
                        itemLabel: itemLabel,
                        selectedValue: state.value,
                        onChanged: (val) {
                          state.didChange(val);
                          onChanged(val);
                        },
                        hint: hint,
                        labelText: labelText,
                        scrollController: scrollController,
                      );
                    },
                  );
                },
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: showSearchSheet,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: labelText,
                      errorText: state.errorText,
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6849EF)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: state.hasError ? Colors.red : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: state.hasError ? Colors.red : Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        color: state.value != null ? const Color(0xFF2D3142) : Colors.grey.shade600,
                        fontSize: 15,
                        fontWeight: state.value != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

class _SearchSheetBody<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String hint;
  final String labelText;
  final ScrollController scrollController;

  const _SearchSheetBody({
    super.key,
    required this.items,
    required this.itemLabel,
    required this.selectedValue,
    required this.onChanged,
    required this.hint,
    required this.labelText,
    required this.scrollController,
  });

  @override
  State<_SearchSheetBody<T>> createState() => _SearchSheetBodyState<T>();
}

class _SearchSheetBodyState<T> extends State<_SearchSheetBody<T>> {
  final _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return widget.itemLabel(item).toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih ${widget.labelText}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6849EF)),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6849EF), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada hasil ditemukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item == widget.selectedValue;
                      final label = widget.itemLabel(item);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6849EF).withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF6849EF) : const Color(0xFF2D3142),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check, color: Color(0xFF6849EF))
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () {
                            widget.onChanged(item);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
