import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zonix/features/services/chat_service.dart';
import 'package:zonix/features/services/pusher_service.dart';
import 'package:zonix/features/services/realtime_event_utils.dart';
import 'package:zonix/features/utils/app_colors.dart';

/// Chat comercio-cliente. Usa Pusher para mensajes en tiempo real.
class CommerceChatMessagesPage extends StatefulWidget {
  const CommerceChatMessagesPage({
    super.key,
    required this.orderId,
    this.customerName = 'Cliente',
  });

  final int orderId;
  final String customerName;

  @override
  State<CommerceChatMessagesPage> createState() =>
      _CommerceChatMessagesPageState();
}

class _ChatListEntry {
  const _ChatListEntry.date(this.dateLabel) : message = null;
  const _ChatListEntry.message(this.message) : dateLabel = null;
  final String? dateLabel;
  final Map<String, dynamic>? message;
}

class _CommerceChatMessagesPageState extends State<CommerceChatMessagesPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  StreamSubscription<Map<String, dynamic>>? _pusherSubscription;

  static const double _bubbleRadius = 12;

  @override
  void initState() {
    super.initState();
    _loadMessages(silent: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToPusher());
  }

  @override
  void dispose() {
    _pusherSubscription?.cancel();
    PusherService.instance.unsubscribeFromChannel('private-orders.${widget.orderId}');
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _subscribeToPusher() async {
    final ok = await PusherService.instance.subscribeToOrderChat(widget.orderId);
    if (!ok || !mounted) return;

    _pusherSubscription?.cancel();
    _pusherSubscription = PusherService.instance.eventStream.listen((event) {
      final rawEventName =
          event['canonicalEventName']?.toString() ??
          event['eventName']?.toString() ??
          '';
      final eventName = RealtimeEventUtils.normalizeEventName(rawEventName);
      final channelName = event['channelName']?.toString() ?? '';

      if (channelName == 'private-orders.${widget.orderId}') {
        if (!mounted) return;
        if (eventName.contains('NewMessage') ||
            eventName.contains('OrderStatusChanged') ||
            eventName.contains('PaymentValidated')) {
          _loadMessages(silent: true);
        }
      }
    });
  }

  /// [silent]: recarga por Pusher sin pantalla de carga (no tapa el chat).
  Future<void> _loadMessages({required bool silent}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await _chatService.getMessages(widget.orderId);
      if (mounted) {
        setState(() {
          _messages = list;
          _loading = false;
          if (silent) _error = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _error = e.toString().replaceFirst('Exception: ', '');
          }
          _loading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  DateTime _parseCreatedAt(Map<String, dynamic> m) {
    final s = (m['created_at'] ?? m['timestamp'] ?? '').toString();
    if (s.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  List<Map<String, dynamic>> get _sortedMessages {
    final l = List<Map<String, dynamic>>.from(_messages);
    l.sort((a, b) => _parseCreatedAt(a).compareTo(_parseCreatedAt(b)));
    return l;
  }

  List<_ChatListEntry> _buildListEntries() {
    final sorted = _sortedMessages;
    if (sorted.isEmpty) return [];
    final out = <_ChatListEntry>[];
    DateTime? lastDay;
    for (final m in sorted) {
      final dt = _parseCreatedAt(m);
      final day = DateTime(dt.year, dt.month, dt.day);
      if (lastDay == null ||
          day.year != lastDay.year ||
          day.month != lastDay.month ||
          day.day != lastDay.day) {
        lastDay = day;
        out.add(_ChatListEntry.date(_dateChipLabel(day)));
      }
      out.add(_ChatListEntry.message(m));
    }
    return out;
  }

  String _dateChipLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'HOY';
    final yest = today.subtract(const Duration(days: 1));
    if (day == yest) return 'AYER';
    return DateFormat('d MMM yyyy', 'es').format(day);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _textController.clear();

    try {
      final sent = await _chatService.sendMessage(widget.orderId, {
        'content': text,
        'type': 'text',
      });
      if (mounted) {
        final msg = Map<String, dynamic>.from(sent);
        msg['is_own_message'] = true;
        msg['created_at'] ??= DateTime.now().toIso8601String();
        setState(() {
          _messages.add(msg);
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Color _canvasBg(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? Theme.of(context).colorScheme.surface : AppColors.scaffoldBgLight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvasBg(context),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInput(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.stitchChatAppBar,
      foregroundColor: AppColors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: AppColors.stitchSlate400,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.customerName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              color: AppColors.surfaceDarkLighter,
              child: const Icon(Icons.person, color: AppColors.stitchSlate400, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_error != null) {
      final cs = Theme.of(context).colorScheme;
      return Center(
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
                onPressed: () => _loadMessages(silent: false),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return _buildEmptyState(context);
    }

    final entries = _buildListEntries();
    return RefreshIndicator(
      onRefresh: () => _loadMessages(silent: false),
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          if (e.dateLabel != null) {
            return _buildDateChip(context, e.dateLabel!);
          }
          return _buildMessageRow(context, e.message!);
        },
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
              'No hay mensajes. Escribe para iniciar la conversación.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh : AppColors.stitchBgCard,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageRow(BuildContext context, Map<String, dynamic> m) {
    final isOwn = m['is_own_message'] == true;
    final content = m['content']?.toString() ?? '';
    String time = (m['created_at'] ?? m['timestamp'] ?? '').toString();
    if (time.length > 8 && time.contains('T')) {
      try {
        final dt = DateTime.parse(time);
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final senderType = m['sender_type']?.toString() ?? '';
    final senderName = m['sender_name']?.toString() ?? '';
    final roleLabel = _roleBadgeLabel(senderType, senderName);
    final cs = Theme.of(context).colorScheme;

    final incomingBg = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHigh
        : AppColors.stitchBgCard;
    final incomingFg = cs.onSurface;

    final borderRadius = isOwn
        ? const BorderRadius.only(
            topLeft: Radius.circular(_bubbleRadius),
            topRight: Radius.circular(_bubbleRadius),
            bottomLeft: Radius.circular(_bubbleRadius),
            bottomRight: Radius.zero,
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(_bubbleRadius),
            topRight: Radius.circular(_bubbleRadius),
            bottomRight: Radius.circular(_bubbleRadius),
            bottomLeft: Radius.zero,
          );

    final read = m['read'] == true;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isOwn && roleLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                roleLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _roleBadgeColor(context, senderType),
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isOwn ? AppColors.blue : incomingBg,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: isOwn ? 0.12 : 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isOwn ? FontWeight.w500 : FontWeight.w400,
                height: 1.45,
                color: isOwn ? AppColors.white : incomingFg,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 8,
              left: isOwn ? 0 : 4,
              right: isOwn ? 4 : 0,
              bottom: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (isOwn && read) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: AppColors.blue),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleBadgeLabel(String senderType, String senderName) {
    final name = senderName.isNotEmpty ? senderName : null;
    switch (senderType) {
      case 'restaurant':
        return name != null ? '$name (Comercio)' : 'Comercio';
      case 'delivery_agent':
        return name != null ? '$name (Delivery)' : 'Delivery';
      case 'admin':
        return name != null ? '$name (Admin)' : 'Admin';
      case 'customer':
        return name != null ? '$name (Cliente)' : 'Cliente';
      default:
        return name ?? '';
    }
  }

  Color _roleBadgeColor(BuildContext context, String senderType) {
    switch (senderType) {
      case 'restaurant':
        return AppColors.orange;
      case 'delivery_agent':
        return AppColors.purple;
      case 'admin':
        return AppColors.red;
      case 'customer':
        return AppColors.blue;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildInput(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassTint = isDark
        ? const Color(0xFF121C27).withValues(alpha: 0.82)
        : AppColors.white.withValues(alpha: 0.88);
    final fillColor = isDark ? cs.surfaceContainerHigh : const Color(0xFFE8EDF0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: glassTint,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: null,
                style: IconButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  disabledForegroundColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                icon: const Icon(Icons.add_circle_outline),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  enabled: !_sending,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: AppColors.blue.withValues(alpha: 0.35)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.blue,
                elevation: 4,
                shadowColor: AppColors.blue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: _sending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: AppColors.white, size: 22),
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
