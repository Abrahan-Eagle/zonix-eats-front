import 'package:flutter/material.dart';
import 'package:zonix/features/screens/commerce/commerce_profile_edit_page.dart';
import 'package:zonix/features/services/commerce_data_service.dart';
import 'package:zonix/features/utils/app_colors.dart';

class CommerceProfilePage extends StatefulWidget {
  const CommerceProfilePage({
    Key? key,
    this.initialProfile,
    this.isTestMode = false,
  }) : super(key: key);

  final dynamic initialProfile;
  final bool isTestMode;

  @override
  State<CommerceProfilePage> createState() => _CommerceProfilePageState();
}

class _CommerceProfilePageState extends State<CommerceProfilePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _commerce = {};
  bool _commerceOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await CommerceDataService.getCommerceData();
      if (mounted) {
        setState(() {
          _commerce = data;
          _commerceOpen = data['open'] == true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleOpen(bool value) async {
    try {
      await CommerceDataService.updateCommerceData({'open': value});
      if (mounted) {
        setState(() => _commerceOpen = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Comercio abierto' : 'Comercio cerrado'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil comercio')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil comercio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => CommerceProfileEditPage(
                    initialData: _commerce,
                  ),
                ),
              );
              if (result == true) _loadData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _commerceOpen ? 'Comercio abierto' : 'Comercio cerrado',
                        style: TextStyle(
                          color: _commerceOpen ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: _commerceOpen,
                        onChanged: _toggleOpen,
                        activeColor: AppColors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nombre: ${_commerce['business_name'] ?? '-'}'),
                      Text('Tipo: ${_commerce['business_type'] ?? '-'}'),
                      Text('Dirección: ${_commerce['address'] ?? '-'}'),
                      Text('Teléfono: ${_commerce['phone'] ?? '-'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Horarios'),
                subtitle: Text(
                  _commerce['schedule']?.toString() ?? 'No configurado',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommerceProfileEditPage(
                        initialData: _commerce,
                      ),
                    ),
                  );
                  if (result == true) _loadData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
