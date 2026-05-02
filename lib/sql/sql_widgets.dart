import 'package:flutter/material.dart';
import 'package:multi_store_app/minor_screens/product_detail.dart';
import 'package:multi_store_app/sql/product_notes_provider.dart';
import 'package:multi_store_app/sql/recently_viewed_provider.dart';
import 'package:multi_store_app/sql/search_history_provider.dart';
import 'package:provider/provider.dart';
class RecentlyViewedWidget extends StatelessWidget {
  const RecentlyViewedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecentlyViewedProvider>();
    if (!provider.hasItems) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vistos recientemente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              TextButton(
                onPressed: () => context.read<RecentlyViewedProvider>().clearAll(),
                child: const Text('Borrar', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              final images = item['images_url'] as List?;
              final imageUrl = (images?.isNotEmpty == true) ? images![0].toString() : '';
              final name = item['name']?.toString() ?? '';
              final salePrice = (item['sale_price'] as num?)?.toDouble() ?? 0.0;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      productList: {
                        'productName': name,
                        'productPrice': item['price'],
                        'productSalePrice': salePrice,
                        'productImages': images ?? [],
                        'documentId': item['document_id'],
                        'supplierId': item['supplier_id'],
                        'quantity': item['quantity'],
                      },
                    ),
                  ),
                ),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, height: 110, width: 120, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(height: 110, color: Colors.grey[100], child: const Icon(Icons.image_not_supported)))
                            : Container(height: 110, color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                            const SizedBox(height: 2),
                            Text('\$${salePrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class SearchHistoryWidget extends StatelessWidget {
  final ValueChanged<String> onSelectQuery;
  const SearchHistoryWidget({super.key, required this.onSelectQuery});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchHistoryProvider>();
    if (!provider.hasHistory) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Búsquedas recientes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
              TextButton(
                onPressed: () => context.read<SearchHistoryProvider>().clearAll(),
                child: const Text('Borrar todo', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
        ),
        ...provider.history.map((query) => ListTile(
              dense: true,
              leading: const Icon(Icons.history_rounded, color: Colors.grey, size: 20),
              title: Text(query,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                onPressed: () => context.read<SearchHistoryProvider>().deleteSearch(query),
              ),
              onTap: () => onSelectQuery(query),
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class ProductNoteWidget extends StatefulWidget {
  final String documentId;
  const ProductNoteWidget({super.key, required this.documentId});

  @override
  State<ProductNoteWidget> createState() => _ProductNoteWidgetState();
}

class _ProductNoteWidgetState extends State<ProductNoteWidget> {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await context.read<ProductNotesProvider>().getNote(widget.documentId);
    if (mounted) {
      _ctrl.text = note ?? '';
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.sticky_note_2_rounded, color: Color(0xFFD97706), size: 18),
            SizedBox(width: 6),
            Text('Mi nota', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            decoration: const InputDecoration(
              hintText: 'Escribe una nota sobre este producto…',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      if (!mounted) return;
                      await context.read<ProductNotesProvider>().saveNote(widget.documentId, _ctrl.text);
                      if (mounted) {
                        setState(() => _saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nota guardada ✓'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                        );
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(8)),
                child: _saving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
