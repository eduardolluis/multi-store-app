import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:multi_store_app/minor_screens/product_detail.dart';
import 'package:multi_store_app/models/product_model.dart';
import 'package:multi_store_app/utilities/categ_list.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  String? _selectedCategory;
  String _sortBy = 'relevance'; // 'relevance' | 'price_asc' | 'price_desc' | 'discount'

  static const List<_SortOption> _sortOptions = [
    _SortOption(label: 'Relevance', value: 'relevance', icon: Icons.sort_rounded),
    _SortOption(label: 'Price: Low → High', value: 'price_asc', icon: Icons.arrow_upward_rounded),
    _SortOption(
      label: 'Price: High → Low',
      value: 'price_desc',
      icon: Icons.arrow_downward_rounded,
    ),
    _SortOption(label: 'Biggest Discount', value: 'discount', icon: Icons.local_offer_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    var results = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // ── category filter ──
      if (_selectedCategory != null) {
        final cat = (data['category'] ?? '').toString().toLowerCase();
        if (cat != _selectedCategory!.toLowerCase()) return false;
      }

      // ── text filter ──
      if (_query.isNotEmpty) {
        final name = (data['productName'] ?? '').toString().toLowerCase();
        final desc = (data['productDescription'] ?? '').toString().toLowerCase();
        final cat = (data['category'] ?? '').toString().toLowerCase();
        final sub = (data['subcategory'] ?? '').toString().toLowerCase();
        final q = _query.toLowerCase();
        if (!name.contains(q) && !desc.contains(q) && !cat.contains(q) && !sub.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();

    // ── sort ──
    switch (_sortBy) {
      case 'price_asc':
        results.sort((a, b) {
          final pa = computeSalePrice((a.data() as Map<String, dynamic>));
          final pb = computeSalePrice((b.data() as Map<String, dynamic>));
          return pa.compareTo(pb);
        });
        break;
      case 'price_desc':
        results.sort((a, b) {
          final pa = computeSalePrice((a.data() as Map<String, dynamic>));
          final pb = computeSalePrice((b.data() as Map<String, dynamic>));
          return pb.compareTo(pa);
        });
        break;
      case 'discount':
        results.sort((a, b) {
          final da = ((a.data() as Map<String, dynamic>)['discount'] as num?)?.toInt() ?? 0;
          final db = ((b.data() as Map<String, dynamic>)['discount'] as num?)?.toInt() ?? 0;
          return db.compareTo(da);
        });
        break;
      default:
        break;
    }

    return results;
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        selectedCategory: _selectedCategory,
        selectedSort: _sortBy,
        onApply: (cat, sort) {
          setState(() {
            _selectedCategory = cat;
            _sortBy = sort;
          });
        },
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_sortBy != 'relevance') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.trim().isNotEmpty || _selectedCategory != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: hasQuery ? _buildResults() : _buildEmptyState(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
      ),
      title: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search products, brands…',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              onPressed: _showFilters,
              icon: Icon(
                Icons.tune_rounded,
                color: _activeFilterCount > 0 ? const Color(0xFF111827) : const Color(0xFF6B7280),
              ),
            ),
            if (_activeFilterCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: maincateg.map((cat) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _query = cat;
                    _searchController.text = cat;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.search_rounded, size: 36, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'What are you looking for?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Search by product name, category, or description',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong', style: TextStyle(color: Color(0xFF6B7280))),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoResults();
        }

        final filtered = _applyFilters(snapshot.data!.docs);

        if (filtered.isEmpty) {
          return _buildNoResults();
        }

        return Column(
          children: [
            // ── Result count + active filters ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  if (_selectedCategory != null)
                    _ActiveFilterChip(
                      label: _selectedCategory!,
                      onRemove: () => setState(() => _selectedCategory = null),
                    ),
                  if (_sortBy != 'relevance') ...[
                    const SizedBox(width: 6),
                    _ActiveFilterChip(
                      label: _sortOptions.firstWhere((s) => s.value == _sortBy).label,
                      onRemove: () => setState(() => _sortBy = 'relevance'),
                    ),
                  ],
                ],
              ),
            ),

            // ── Grid ──
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  childAspectRatio: 0.62,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return SearchProductCard(data: filtered[index].data() as Map<String, dynamic>);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),
            Text(
              'No results for "$_query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords or remove some filters',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),
            if (_activeFilterCount > 0)
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedCategory = null;
                  _sortBy = 'relevance';
                }),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Clear filters'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF111827)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final String? selectedCategory;
  final String selectedSort;
  final void Function(String? category, String sort) onApply;

  const _FilterSheet({
    required this.selectedCategory,
    required this.selectedSort,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _cat;
  String _sort = 'relevance';

  static const List<_SortOption> _sortOptions = [
    _SortOption(label: 'Relevance', value: 'relevance', icon: Icons.sort_rounded),
    _SortOption(label: 'Price: Low → High', value: 'price_asc', icon: Icons.arrow_upward_rounded),
    _SortOption(
      label: 'Price: High → Low',
      value: 'price_desc',
      icon: Icons.arrow_downward_rounded,
    ),
    _SortOption(label: 'Biggest Discount', value: 'discount', icon: Icons.local_offer_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _cat = widget.selectedCategory;
    _sort = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _cat = null;
                    _sort = 'relevance';
                  }),
                  child: const Text('Reset', style: TextStyle(color: Color(0xFFDC2626))),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const _SheetLabel(label: 'Sort By'),
            const SizedBox(height: 10),

            ..._sortOptions.map((opt) {
              final selected = _sort == opt.value;
              return GestureDetector(
                onTap: () => setState(() => _sort = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt.icon,
                        size: 18,
                        color: selected ? Colors.white : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                      if (selected) ...[
                        const Spacer(),
                        const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 18),
            const _SheetLabel(label: 'Category'),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CatChip(
                  label: 'All',
                  selected: _cat == null,
                  onTap: () => setState(() => _cat = null),
                ),
                ...maincateg.map(
                  (c) => _CatChip(
                    label: c[0].toUpperCase() + c.substring(1),
                    selected: _cat == c,
                    onTap: () => setState(() => _cat = _cat == c ? null : c),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_cat, _sort);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search product card ───────────────────────────────────────────────────────

class SearchProductCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const SearchProductCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final discount = (data['discount'] as num?)?.toInt() ?? 0;
    final salePrice = computeSalePrice(data);
    final hasDiscount = discount > 0 && discount <= 100;
    final images = data['images'] as List<dynamic>? ?? [];
    final imageUrl = images.isNotEmpty ? images[0].toString() : '';
    final name = (data['productName'] ?? 'Unknown').toString();
    final qty = (data['quantity'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productList: data)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: imageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFF1F3F7),
                              child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF1F3F7),
                                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-$discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (qty == 0)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Container(
                          color: Colors.black.withOpacity(0.45),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Out of stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Info ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      if (hasDiscount)
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFF9CA3AF),
                          ),
                        ),
                      Text(
                        '\$${salePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _SortOption {
  final String label;
  final String value;
  final IconData icon;
  const _SortOption({required this.label, required this.value, required this.icon});
}

class _SheetLabel extends StatelessWidget {
  final String label;
  const _SheetLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF6B7280),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.length > 14 ? '${label.substring(0, 14)}…' : label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
