import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/vibe_constants.dart';
import '../models/manual_list_entity.dart';
import '../providers/manual_list_provider.dart';
import 'list_creation_sheet.dart';

class AddToListSheet extends StatelessWidget {
  const AddToListSheet({
    super.key,
    required this.product,
  });

  final ManualListItemEntity product;

  static Future<void> show(
    BuildContext context,
    ManualListItemEntity product,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: VibeColors.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddToListSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManualListProvider>();
    final lists = provider.lists;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Agregar a una lista',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: VibeColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            if (lists.isEmpty)
              _EmptyListsView(product: product)
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: lists
                        .map((list) => _ListTile(
                              list: list,
                              onTap: () async {
                                await provider.addItemToList(list.id, product);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Producto agregado correctamente.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                            ))
                        .toList(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Divider(),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                if (!context.mounted) return;
                final list = await ListCreationSheet.show(
                  context,
                  prefillProduct: product,
                );
                if (list != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto agregado correctamente.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon:
                  const Icon(Icons.add_circle_outline, color: VibeColors.mint),
              label: const Text(
                'Crear nueva lista',
                style: TextStyle(
                    color: VibeColors.mint, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.list, required this.onTap});

  final ManualListEntity list;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: VibeColors.mint.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.list_alt_rounded,
            color: VibeColors.navy, size: 22),
      ),
      title: Text(
        list.name,
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: VibeColors.navy),
      ),
      subtitle: Text(
        '${list.itemCount} productos',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _EmptyListsView extends StatelessWidget {
  const _EmptyListsView({required this.product});

  final ManualListItemEntity product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.playlist_add_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No tienes listas todavía.',
                style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 15),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            if (!context.mounted) return;
            final list = await ListCreationSheet.show(
              context,
              prefillProduct: product,
            );
            if (list != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto agregado correctamente.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Crear nueva lista'),
          style: FilledButton.styleFrom(
            backgroundColor: VibeColors.navy,
            foregroundColor: VibeColors.backgroundWhite,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}
