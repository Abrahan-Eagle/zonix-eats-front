import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zonix_glasses/features/DomainProfiles/Profiles/api/profile_service.dart';
import 'package:zonix_glasses/features/screens/auth/sign_in_screen.dart';
import 'package:zonix_glasses/features/utils/user_provider.dart';

/// Solicitud de eliminación de cuenta (GDPR). Usa DELETE /api/user/account.
class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final _reasonController = TextEditingController();
  bool _confirmed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirma que entiendes que la acción es irreversible.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ProfileService().deleteAccount();
      if (!mounted) return;
      await context.read<UserProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Esta acción eliminará tu cuenta y datos asociados de forma permanente.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            title: const Text('Entiendo que esta acción no se puede deshacer'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );
  }
}
