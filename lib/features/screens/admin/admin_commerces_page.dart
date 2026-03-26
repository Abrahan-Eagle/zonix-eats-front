import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';

class AdminCommercesPage extends StatefulWidget {
  const AdminCommercesPage({super.key});

  @override
  State<AdminCommercesPage> createState() => _AdminCommercesPageState();
}

class _AdminCommercesPageState extends State<AdminCommercesPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _commerces = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _search = '';
  bool? _filterOpen;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _commerces = [];
    });
    try {
      final result = await context.read<AdminService>().getCommerces(
            page: 1,
            search: _search.isNotEmpty ? _search : null,
            open: _filterOpen,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _commerces = list;
        _hasMore = _page < lastPage;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    _page++;
    try {
      final result = await context.read<AdminService>().getCommerces(
            page: _page,
            search: _search.isNotEmpty ? _search : null,
            open: _filterOpen,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _commerces.addAll(list);
        _hasMore = _page < lastPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      _page--;
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    _search = value.trim();
    _loadData();
  }

  void _onFilterChanged(bool? open) {
    _filterOpen = open;
    _loadData();
  }

  Color _openBadgeColor(bool open) => open ? AppColors.green : AppColors.red;

  String _ownerName(Map<String, dynamic> c) {
    final profile = c['profile'] as Map<String, dynamic>?;
    if (profile != null) {
      return '${safeString(profile['first_name'])} ${safeString(profile['last_name'])}'
          .trim();
    }
    final user = c['user'] as Map<String, dynamic>?;
    if (user != null) return safeString(user['name']);
    return '';
  }

  void _showCommerceSheet(Map<String, dynamic> commerce) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOpen = commerce['open'] == true || commerce['open'] == 1;
    final id = safeInt(commerce['id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.cardBg(context),
      builder: (ctx) {
        bool currentOpen = isOpen;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.white38 : AppColors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      safeString(commerce['business_name'], 'Sin nombre'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: $id',
                      style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow(
                      Icons.person,
                      'Propietario',
                      _ownerName(commerce),
                    ),
                    _detailRow(
                      Icons.email,
                      'Email',
                      safeString(commerce['email']),
                    ),
                    _detailRow(
                      Icons.phone,
                      'Teléfono',
                      safeString(commerce['phone']),
                    ),
                    _detailRow(
                      Icons.location_on,
                      'Dirección',
                      safeString(commerce['address']),
                    ),
                    _detailRow(
                      Icons.category,
                      'Categoría',
                      safeString(commerce['category']),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _openBadgeColor(currentOpen)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentOpen ? 'Abierto' : 'Cerrado',
                            style: TextStyle(
                              color: _openBadgeColor(currentOpen),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await context
                                  .read<AdminService>()
                                  .updateCommerceStatus(id, !currentOpen);
                              setSheetState(() => currentOpen = !currentOpen);
                              _loadData();
                            } catch (e) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          icon: Icon(
                            currentOpen ? Icons.lock : Icons.lock_open,
                            size: 18,
                          ),
                          label: Text(currentOpen ? 'Cerrar' : 'Abrir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentOpen
                                ? AppColors.red
                                : AppColors.green,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryText(context)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText(context),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.secondaryText(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Comercios'),
        backgroundColor:
            isDark ? AppColors.grayDark : AppColors.blueDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: AppColors.primaryText(context)),
              decoration: InputDecoration(
                hintText: 'Buscar comercio...',
                hintStyle:
                    TextStyle(color: AppColors.secondaryText(context)),
                prefixIcon: Icon(Icons.search,
                    color: AppColors.secondaryText(context)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: AppColors.secondaryText(context)),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.grayDark : AppColors.grayLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _filterChip('Todos', _filterOpen == null, () {
                  _onFilterChanged(null);
                }),
                const SizedBox(width: 8),
                _filterChip('Abiertos', _filterOpen == true, () {
                  _onFilterChanged(true);
                }),
                const SizedBox(width: 8),
                _filterChip('Cerrados', _filterOpen == false, () {
                  _onFilterChanged(false);
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue
              : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.grayDark
                  : AppColors.grayLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.white
                : AppColors.secondaryText(context),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.error(context)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText(context))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_commerces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront,
                size: 48, color: AppColors.secondaryText(context)),
            const SizedBox(height: 12),
            Text('No se encontraron comercios',
                style: TextStyle(color: AppColors.secondaryText(context))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _commerces.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _commerces.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildCommerceCard(_commerces[index]);
        },
      ),
    );
  }

  Widget _buildCommerceCard(Map<String, dynamic> commerce) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = safeString(commerce['business_name'], 'Sin nombre');
    final isOpen = commerce['open'] == true || commerce['open'] == 1;
    final owner = _ownerName(commerce);

    return GestureDetector(
      onTap: () => _showCommerceSheet(commerce),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.white12 : AppColors.black12,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.blue.withValues(alpha: 0.15),
                child: const Icon(Icons.storefront, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    if (owner.isNotEmpty)
                      Text(
                        owner,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _openBadgeColor(isOpen).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOpen ? 'Abierto' : 'Cerrado',
                  style: TextStyle(
                    color: _openBadgeColor(isOpen),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
