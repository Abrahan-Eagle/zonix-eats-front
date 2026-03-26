import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/safe_parse.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;

  String? _selectedRole;
  String? _selectedStatus;

  static const _roleFilters = <String?, String>{
    null: 'Todos',
    'users': 'Buyer',
    'commerce': 'Commerce',
    'delivery_company': 'Delivery Co.',
    'delivery_agent': 'Agent',
    'delivery': 'Delivery',
    'admin': 'Admin',
  };

  static const _statusFilters = <String?, String>{
    null: 'Todos',
    'active': 'Activos',
    'suspended': 'Suspendidos',
  };

  static const _allRoles = <String, String>{
    'users': 'Buyer',
    'commerce': 'Commerce',
    'delivery_company': 'Delivery Company',
    'delivery_agent': 'Delivery Agent',
    'delivery': 'Delivery',
    'admin': 'Admin',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await context.read<AdminService>().getUsers(
        role: _selectedRole,
        status: _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _applySearch();
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

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((u) {
        final name = safeString(u['name']).toLowerCase();
        final email = safeString(u['email']).toLowerCase();
        final profile = u['profile'];
        final firstName =
            profile is Map ? safeString(profile['first_name']).toLowerCase() : '';
        final lastName =
            profile is Map ? safeString(profile['last_name']).toLowerCase() : '';
        return name.contains(query) ||
            email.contains(query) ||
            firstName.contains(query) ||
            lastName.contains(query);
      }).toList();
    }
  }

  String _displayName(Map<String, dynamic> user) {
    final profile = user['profile'];
    if (profile is Map) {
      final first = safeString(profile['first_name']).trim();
      final last = safeString(profile['last_name']).trim();
      if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    }
    final name = safeString(user['name']).trim();
    return name.isNotEmpty ? name : 'Sin nombre';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _roleLabel(String? role) => _allRoles[role] ?? role ?? '—';

  Color _roleColor(String? role) {
    switch (role) {
      case 'users':
        return AppColors.blue;
      case 'commerce':
        return AppColors.orange;
      case 'delivery_company':
        return AppColors.purple;
      case 'delivery_agent':
        return AppColors.teal;
      case 'delivery':
        return AppColors.green;
      case 'admin':
        return AppColors.red;
      default:
        return AppColors.stitchSlate;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'suspended':
        return 'Suspendido';
      case 'banned':
        return 'Baneado';
      default:
        return status ?? '—';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return AppColors.green;
      case 'suspended':
        return AppColors.orange;
      case 'banned':
        return AppColors.red;
      default:
        return AppColors.stitchSlate;
    }
  }

  String _profileStatus(Map<String, dynamic> user) {
    final profile = user['profile'];
    if (profile is Map) {
      final s = safeString(profile['status']).trim();
      if (s.isNotEmpty) return s;
    }
    return 'active';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          _buildRoleChips(isDark),
          _buildStatusChips(isDark),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() => _applySearch()),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o email…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _applySearch());
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.grayDark : AppColors.grayLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRoleChips(bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _roleFilters.entries.map((e) {
          final selected = _selectedRole == e.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              selectedColor: AppColors.blue.withAlpha(40),
              labelStyle: TextStyle(
                color: selected
                    ? AppColors.blue
                    : (isDark ? AppColors.white70 : AppColors.gray),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) {
                setState(() => _selectedRole = e.key);
                _loadUsers();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChips(bool isDark) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _statusFilters.entries.map((e) {
          final selected = _selectedStatus == e.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              selectedColor: AppColors.orange.withAlpha(40),
              labelStyle: TextStyle(
                color: selected
                    ? AppColors.orange
                    : (isDark ? AppColors.white70 : AppColors.gray),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) {
                setState(() => _selectedStatus = e.key);
                _loadUsers();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
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
              const Icon(Icons.error_outline, size: 56, color: AppColors.red),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondaryText(context)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: AppColors.secondaryText(context)),
            const SizedBox(height: 12),
            Text(
              'No se encontraron usuarios',
              style: TextStyle(color: AppColors.secondaryText(context)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _filteredUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildUserCard(_filteredUsers[i], isDark),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // USER CARD
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildUserCard(Map<String, dynamic> user, bool isDark) {
    final name = _displayName(user);
    final email = safeString(user['email']);
    final role = safeString(user['role']);
    final status = _profileStatus(user);

    return Card(
      color: AppColors.cardBg(context),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showUserSheet(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _roleColor(role).withAlpha(30),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: _roleColor(role),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(_roleLabel(role), _roleColor(role)),
                        const SizedBox(width: 6),
                        _badge(_statusLabel(status), _statusColor(status)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.secondaryText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET (details + actions)
  // ──────────────────────────────────────────────────────────────────────────

  void _showUserSheet(Map<String, dynamic> user) {
    final name = _displayName(user);
    final email = safeString(user['email']);
    final role = safeString(user['role']);
    final status = _profileStatus(user);
    final userId = safeInt(user['id']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.52,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.textMutedGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _roleColor(role).withAlpha(30),
                      child: Text(
                        _initials(name),
                        style: TextStyle(
                          color: _roleColor(role),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(email,
                              style: TextStyle(
                                  color: AppColors.secondaryText(context),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _badge(_roleLabel(role), _roleColor(role)),
                  const SizedBox(width: 8),
                  _badge(_statusLabel(status), _statusColor(status)),
                ]),
                const Divider(height: 28),

                // Cambiar rol
                Text('Cambiar rol',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText(context))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _allRoles.containsKey(role) ? role : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: _allRoles.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (newRole) async {
                    if (newRole == null || newRole == role) return;
                    Navigator.pop(ctx);
                    await _changeRole(userId, newRole);
                  },
                ),
                const SizedBox(height: 20),

                // Cambiar estado
                Text('Cambiar estado',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText(context))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusActionButton(ctx, userId, 'active', 'Activo',
                        AppColors.green, status),
                    const SizedBox(width: 8),
                    _statusActionButton(ctx, userId, 'suspended', 'Suspender',
                        AppColors.orange, status),
                    const SizedBox(width: 8),
                    _statusActionButton(ctx, userId, 'banned', 'Banear',
                        AppColors.red, status),
                  ],
                ),
                const SizedBox(height: 24),

                // Eliminar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar usuario'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(userId, name);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statusActionButton(BuildContext sheetCtx, int userId, String value,
      String label, Color color, String current) {
    final isActive = current == value;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? color.withAlpha(25) : null,
          foregroundColor: color,
          side: BorderSide(color: isActive ? color : color.withAlpha(80)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: isActive
            ? null
            : () async {
                Navigator.pop(sheetCtx);
                await _changeStatus(userId, value);
              },
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACTIONS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _changeRole(int userId, String newRole) async {
    try {
      await context.read<AdminService>().updateUserRole(userId, newRole, 0);
      if (!mounted) return;
      _snack('Rol actualizado correctamente');
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      _snack('Error al cambiar rol: $e', isError: true);
    }
  }

  Future<void> _changeStatus(int userId, String newStatus) async {
    try {
      await context.read<AdminService>().updateUserStatus(userId, newStatus);
      if (!mounted) return;
      _snack('Estado actualizado correctamente');
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      _snack('Error al cambiar estado: $e', isError: true);
    }
  }

  void _confirmDelete(int userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
            '¿Estás seguro de que deseas eliminar a "$name"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AdminService>().deleteUser(userId);
                if (!mounted) return;
                _snack('Usuario eliminado');
                await _loadUsers();
              } catch (e) {
                if (!mounted) return;
                _snack('Error al eliminar: $e', isError: true);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
