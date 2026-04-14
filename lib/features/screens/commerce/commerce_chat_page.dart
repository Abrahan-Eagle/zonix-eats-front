import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zonix/features/screens/commerce/commerce_chat_messages_page.dart';
import 'package:zonix/features/services/chat_service.dart';
import 'package:zonix/features/utils/app_colors.dart';
import 'package:zonix/features/utils/safe_parse.dart';

class CommerceChatPage extends StatefulWidget {
  const CommerceChatPage({super.key});

  @override
  State<CommerceChatPage> createState() => _CommerceChatPageState();
}

class _CommerceChatPageState extends State<CommerceChatPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _conversations = [];

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
      final service = ChatService();
      final list = await service.getConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
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

  Color _canvasBg(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).colorScheme.surface : AppColors.scaffoldBgLight;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _canvasBg(context),
        appBar: _buildAppBar(context),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (_error != null) {
      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: _canvasBg(context),
        appBar: _buildAppBar(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: cs.onSurface),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _canvasBg(context),
      appBar: _buildAppBar(context),
      body: _conversations.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _conversations.length,
                itemBuilder: (context, i) {
                  final c = _conversations[i] is Map
                      ? _conversations[i] as Map
                      : <String, dynamic>{};
                  final participants = c['participants'] as List? ?? [];
                  String customerName = 'Cliente';
                  for (final p in participants) {
                    if (p is Map && p['role'] == 'customer') {
                      customerName = p['name']?.toString() ?? 'Cliente';
                      break;
                    }
                  }
                  final lastMsg = c['last_message'];
                  final lastMsgText = lastMsg is Map
                      ? (lastMsg['content'] ?? '').toString()
                      : (c['last_message'] ?? '').toString();
                  final orderId = c['order_id'] ?? c['id'];
                  final unread = safeInt(c['unread_count']) > 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          if (orderId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommerceChatMessagesPage(
                                  orderId: orderId is int
                                      ? orderId
                                      : int.tryParse(orderId.toString()) ?? 0,
                                  customerName: customerName,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.surfaceDarkLighter,
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.stitchSlate400,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMsgText.isNotEmpty ? lastMsgText : 'Sin mensajes',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (unread)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${c['unread_count']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.stitchChatAppBar,
      foregroundColor: AppColors.white,
      elevation: 0,
      title: Text(
        'Chat con clientes',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 72, color: muted.withValues(alpha: 0.85)),
            const SizedBox(height: 20),
            Text(
              'No hay conversaciones',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
