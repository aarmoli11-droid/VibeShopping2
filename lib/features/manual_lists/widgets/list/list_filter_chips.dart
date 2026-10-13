import 'package:flutter/material.dart';
import '../../../../core/vibe_constants.dart';
import '../../models/manual_list_entity.dart';

class ListFilterChips extends StatelessWidget {
  final ListFilterMode currentFilter;
  final ListSortMode currentSort;
  final bool sortAscending;
  final ValueChanged<ListFilterMode> onFilterChanged;
  final void Function(ListSortMode, bool) onSortChanged;

  const ListFilterChips({
    super.key,
    required this.currentFilter,
    required this.currentSort,
    required this.sortAscending,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Todas', ListFilterMode.all, currentFilter),
              _buildChip('Vacías', ListFilterMode.empty, currentFilter),
              _buildChip(
                  'Con productos', ListFilterMode.hasProducts, currentFilter),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Orden:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              _buildSortChip('Nombre', ListSortMode.name),
              _buildSortChip('Actualizado', ListSortMode.updatedAt),
              _buildSortChip('Total', ListSortMode.totalPrice),
              GestureDetector(
                onTap: () => onSortChanged(currentSort, !sortAscending),
                child: Icon(
                  sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: VibeColors.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, ListFilterMode mode, ListFilterMode current) {
    final selected = mode == current;
    return GestureDetector(
      onTap: () => onFilterChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? VibeColors.navy : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, ListSortMode mode) {
    final selected = mode == currentSort;
    return GestureDetector(
      onTap: () => onSortChanged(mode, sortAscending),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? VibeColors.mint.withValues(alpha: 0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border:
              selected ? Border.all(color: VibeColors.mint, width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? VibeColors.navy : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
