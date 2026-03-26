import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';
import '../../utils/responsive_helper.dart';

class AdminDeliveryCompaniesPage extends StatefulWidget {
  const AdminDeliveryCompaniesPage({super.key});

  @override
  State<AdminDeliveryCompaniesPage> createState() =>
      _AdminDeliveryCompaniesPageState();
}

class _AdminDeliveryCompaniesPageState
    extends State<AdminDeliveryCompaniesPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _search = '';

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
      _companies = [];
    });
    try {
      final result = await context.read<AdminService>().getDeliveryCompanies(
            page: 1,
            search: _search.isNotEmpty ? _search : null,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _companies = list;
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
      final result = await context.read<AdminService>().getDeliveryCompanies(
            page: _page,
            search: _search.isNotEmpty ? _search : null,
          );
      final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final lastPage = safeInt(result['last_page'], 1);
      if (!mounted) return;
      setState(() {
        _companies.addAll(list);
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

  void _showCompanySheet(Map<String, dynamic> company) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final companyId = safeInt(company['id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.cardBg(context),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
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
                  safeString(company['company_name'],
                      safeString(company['business_name'], 'Empresa')),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $companyId',
                  style: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(Icons.email, 'Email', safeString(company['email'])),
                _detailRow(
                    Icons.phone, 'Teléfono', safeString(company['phone'])),
                _detailRow(Icons.location_on, 'Dirección',
                    safeString(company['address'])),
                _detailRow(Icons.people, 'Agentes',
                    '${safeInt(company['agents_count'], safeInt(company['agent_count']))}'),
                const SizedBox(height: 20),
                Text(
                  'Agentes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 8),
                _AgentsList(companyId: companyId),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == '0') return const SizedBox.shrink();
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
        title: const Text('Empresas de delivery'),
        backgroundColor: isDark ? AppColors.grayDark : AppColors.blueDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: AppColors.primaryText(context)),
              decoration: InputDecoration(
                hintText: 'Buscar empresa...',
                hintStyle: TextStyle(color: AppColors.secondaryText(context)),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.secondaryText(context)),
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
          Expanded(child: _buildBody()),
        ],
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
    if (_companies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping,
                size: 48, color: AppColors.secondaryText(context)),
            const SizedBox(height: 12),
            Text('No se encontraron empresas',
                style: TextStyle(color: AppColors.secondaryText(context))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ResponsiveCenter(
        maxWidth: 900,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: _companies.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _companies.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildCompanyCard(_companies[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = safeString(
      company['company_name'],
      safeString(company['business_name'], 'Empresa'),
    );
    final agentCount =
        safeInt(company['agents_count'], safeInt(company['agent_count']));
    final contact = safeString(company['phone'], safeString(company['email']));

    return GestureDetector(
      onTap: () => _showCompanySheet(company),
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
                backgroundColor: AppColors.purple.withValues(alpha: 0.15),
                child:
                    const Icon(Icons.local_shipping, color: AppColors.purple),
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
                    if (contact.isNotEmpty)
                      Text(
                        contact,
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
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 14, color: AppColors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '$agentCount',
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentsList extends StatefulWidget {
  final int companyId;
  const _AgentsList({required this.companyId});

  @override
  State<_AgentsList> createState() => _AgentsListState();
}

class _AgentsListState extends State<_AgentsList> {
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final agents = await context
          .read<AdminService>()
          .getDeliveryCompanyAgents(widget.companyId);
      if (!mounted) return;
      setState(() {
        _agents = agents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Text(_error!,
          style: TextStyle(color: AppColors.error(context), fontSize: 13));
    }
    if (_agents.isEmpty) {
      return Text(
        'Sin agentes registrados',
        style: TextStyle(
          color: AppColors.secondaryText(context),
          fontSize: 13,
        ),
      );
    }
    return Column(
      children: _agents.map((a) {
        final name = safeString(
            a['name'],
            '${safeString(a['first_name'])} ${safeString(a['last_name'])}'
                .trim());
        final phone = safeString(a['phone']);
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.green.withValues(alpha: 0.15),
            child: const Icon(Icons.person, size: 16, color: AppColors.green),
          ),
          title: Text(
            name.isNotEmpty ? name : 'Agente #${safeInt(a['id'])}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryText(context),
            ),
          ),
          subtitle: phone.isNotEmpty
              ? Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText(context),
                  ),
                )
              : null,
        );
      }).toList(),
    );
  }
}
