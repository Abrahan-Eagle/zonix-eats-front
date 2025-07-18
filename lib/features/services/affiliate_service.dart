import 'package:flutter/foundation.dart';
import 'package:zonix/features/services/auth/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AffiliateService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final String baseUrl = const bool.fromEnvironment('dart.vm.product')
      ? dotenv.env['API_URL_PROD']!
      : dotenv.env['API_URL_LOCAL']!;
  
  // Mock data for development
  static final List<Map<String, dynamic>> _mockAffiliates = [
    {
      'id': 1,
      'name': 'Juan Pérez',
      'email': 'juan.perez@email.com',
      'phone': '+51 123 456 789',
      'referral_code': 'JUAN001',
      'status': 'active',
      'level': 'Gold',
      'total_referrals': 45,
      'active_referrals': 32,
      'total_commission': 1250.0,
      'pending_commission': 180.0,
      'paid_commission': 1070.0,
      'rating': 4.8,
      'join_date': '2024-01-01',
      'last_activity': '2024-01-15T10:30:00',
    },
    {
      'id': 2,
      'name': 'María González',
      'email': 'maria.gonzalez@email.com',
      'phone': '+51 987 654 321',
      'referral_code': 'MARIA002',
      'status': 'active',
      'level': 'Silver',
      'total_referrals': 28,
      'active_referrals': 20,
      'total_commission': 890.0,
      'pending_commission': 120.0,
      'paid_commission': 770.0,
      'rating': 4.6,
      'join_date': '2024-01-15',
      'last_activity': '2024-01-15T14:20:00',
    },
    {
      'id': 3,
      'name': 'Carlos Rodríguez',
      'email': 'carlos.rodriguez@email.com',
      'phone': '+51 456 789 123',
      'referral_code': 'CARLOS003',
      'status': 'pending',
      'level': 'Bronze',
      'total_referrals': 12,
      'active_referrals': 8,
      'total_commission': 450.0,
      'pending_commission': 75.0,
      'paid_commission': 375.0,
      'rating': 4.4,
      'join_date': '2024-02-01',
      'last_activity': '2024-01-15T16:45:00',
    },
  ];

  static final List<Map<String, dynamic>> _mockReferrals = [
    {
      'id': 1,
      'affiliate_id': 1,
      'referral_name': 'Ana Martínez',
      'referral_email': 'ana.martinez@email.com',
      'referral_phone': '+51 111 222 333',
      'status': 'active',
      'join_date': '2024-01-05',
      'first_order_date': '2024-01-10',
      'total_orders': 8,
      'total_spent': 450.0,
      'commission_earned': 45.0,
      'last_order_date': '2024-01-15',
    },
    {
      'id': 2,
      'affiliate_id': 1,
      'referral_name': 'Luis Fernández',
      'referral_email': 'luis.fernandez@email.com',
      'referral_phone': '+51 444 555 666',
      'status': 'active',
      'join_date': '2024-01-08',
      'first_order_date': '2024-01-12',
      'total_orders': 5,
      'total_spent': 320.0,
      'commission_earned': 32.0,
      'last_order_date': '2024-01-14',
    },
    {
      'id': 3,
      'affiliate_id': 2,
      'referral_name': 'Sofia López',
      'referral_email': 'sofia.lopez@email.com',
      'referral_phone': '+51 777 888 999',
      'status': 'inactive',
      'join_date': '2024-01-20',
      'first_order_date': '2024-01-25',
      'total_orders': 2,
      'total_spent': 150.0,
      'commission_earned': 15.0,
      'last_order_date': '2024-01-30',
    },
  ];

  static final List<Map<String, dynamic>> _mockCommissions = [
    {
      'id': 1,
      'order_number': 'AFF-001',
      'customer_name': 'Juan Pérez',
      'amount': 45.0,
      'commission_rate': 0.10,
      'commission_amount': 4.5,
      'status': 'pending',
      'date': DateTime.now().subtract(Duration(days: 1)),
      'url': 'assets/default_avatar.png',
    },
    {
      'id': 2,
      'order_number': 'AFF-002',
      'customer_name': 'María García',
      'amount': 32.0,
      'commission_rate': 0.10,
      'commission_amount': 3.2,
      'status': 'paid',
      'date': DateTime.now().subtract(Duration(days: 2)),
      'url': 'assets/default_avatar.png',
    },
    {
      'id': 3,
      'order_number': 'AFF-003',
      'customer_name': 'Carlos López',
      'amount': 28.0,
      'commission_rate': 0.10,
      'commission_amount': 2.8,
      'status': 'pending',
      'date': DateTime.now().subtract(Duration(days: 3)),
      'url': 'assets/default_avatar.png',
    },
    {
      'id': 4,
      'order_number': 'AFF-004',
      'customer_name': 'Ana Rodríguez',
      'amount': 55.0,
      'commission_rate': 0.10,
      'commission_amount': 5.5,
      'status': 'paid',
      'date': DateTime.now().subtract(Duration(days: 4)),
      'url': 'assets/default_avatar.png',
    },
  ];

  static final List<Map<String, dynamic>> _mockSupportTickets = [
    {
      'id': 1,
      'affiliate_id': 1,
      'subject': 'Problema con comisión',
      'description': 'No se ha acreditado mi comisión del pedido #123',
      'status': 'open',
      'priority': 'medium',
      'category': 'commission',
      'created_at': '2024-01-15T10:00:00',
      'updated_at': '2024-01-15T10:00:00',
      'assigned_to': 'Soporte Técnico',
      'messages': [
        {
          'id': 1,
          'sender': 'affiliate',
          'message': 'No se ha acreditado mi comisión del pedido #123',
          'timestamp': '2024-01-15T10:00:00',
        },
        {
          'id': 2,
          'sender': 'support',
          'message': 'Hemos revisado su caso y la comisión será acreditada en las próximas 24 horas.',
          'timestamp': '2024-01-15T11:30:00',
        },
      ],
    },
    {
      'id': 2,
      'affiliate_id': 2,
      'subject': 'Código de referido no funciona',
      'description': 'Mi código MARIA002 no está funcionando para nuevos registros',
      'status': 'resolved',
      'priority': 'high',
      'category': 'technical',
      'created_at': '2024-01-14T15:00:00',
      'updated_at': '2024-01-15T09:00:00',
      'assigned_to': 'Soporte Técnico',
      'messages': [
        {
          'id': 3,
          'sender': 'affiliate',
          'message': 'Mi código MARIA002 no está funcionando para nuevos registros',
          'timestamp': '2024-01-14T15:00:00',
        },
        {
          'id': 4,
          'sender': 'support',
          'message': 'El problema ha sido resuelto. Su código ya está funcionando correctamente.',
          'timestamp': '2024-01-15T09:00:00',
        },
      ],
    },
  ];

  // Get affiliate profile
  Future<Map<String, dynamic>> getAffiliateProfile(int affiliateId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Token no encontrado');

      final response = await http.get(
        Uri.parse('$baseUrl/api/affiliate/profile/$affiliateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? _mockAffiliates.firstWhere((a) => a['id'] == affiliateId);
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(Duration(milliseconds: 400));
        final affiliate = _mockAffiliates.firstWhere((a) => a['id'] == affiliateId);
        return affiliate;
      }
    } catch (e) {
      // Fallback to mock data on error
      await Future.delayed(Duration(milliseconds: 400));
      final affiliate = _mockAffiliates.firstWhere((a) => a['id'] == affiliateId);
      return affiliate;
    }
  }

  // Get affiliate statistics
  Future<Map<String, dynamic>> getAffiliateStatistics(int affiliateId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/affiliate/statistics/$affiliateId');
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 500));
      final affiliate = _mockAffiliates.firstWhere((a) => a['id'] == affiliateId);
      final referrals = _mockReferrals.where((r) => r['affiliate_id'] == affiliateId).toList();
      final commissions = _mockCommissions.where((c) => c['affiliate_id'] == affiliateId).toList();
      
      return {
        'total_referrals': affiliate['total_referrals'],
        'active_referrals': affiliate['active_referrals'],
        'total_commission': affiliate['total_commission'],
        'pending_commission': affiliate['pending_commission'],
        'paid_commission': affiliate['paid_commission'],
        'conversion_rate': (affiliate['active_referrals'] / affiliate['total_referrals'] * 100).toStringAsFixed(1),
        'average_commission_per_referral': (affiliate['total_commission'] / affiliate['total_referrals']).toStringAsFixed(2),
        'monthly_performance': [
          {'month': 'Enero', 'referrals': 15, 'commission': 450.0},
          {'month': 'Febrero', 'referrals': 12, 'commission': 380.0},
          {'month': 'Marzo', 'referrals': 18, 'commission': 520.0},
        ],
        'recent_activity': referrals.take(5).map((r) => {
          'referral_name': r['referral_name'],
          'status': r['status'],
          'last_order_date': r['last_order_date'],
        }).toList(),
      };
    } catch (e) {
      throw Exception('Error fetching affiliate statistics: $e');
    }
  }

  // Get referrals
  Future<List<Map<String, dynamic>>> getReferrals(int affiliateId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/affiliate/referrals/$affiliateId');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockReferrals.where((r) => r['affiliate_id'] == affiliateId).toList();
    } catch (e) {
      throw Exception('Error fetching referrals: $e');
    }
  }

  // Get commissions
  Future<List<Map<String, dynamic>>> getCommissions(int affiliateId, {String? status}) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/affiliate/commissions/$affiliateId', {'status': status});
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      var commissions = _mockCommissions.where((c) => c['affiliate_id'] == affiliateId).toList();
      if (status != null) {
        commissions = commissions.where((c) => c['status'] == status).toList();
      }
      return commissions;
    } catch (e) {
      throw Exception('Error fetching commissions: $e');
    }
  }

  // Request commission withdrawal
  Future<Map<String, dynamic>> requestWithdrawal(int affiliateId, double amount) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/affiliate/withdrawal', {
      //   'affiliate_id': affiliateId,
      //   'amount': amount,
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      return {
        'id': DateTime.now().millisecondsSinceEpoch,
        'affiliate_id': affiliateId,
        'amount': amount,
        'status': 'pending',
        'request_date': DateTime.now().toIso8601String(),
        'estimated_processing': DateTime.now().add(Duration(days: 3)).toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error requesting withdrawal: $e');
    }
  }

  // Get support tickets
  Future<List<Map<String, dynamic>>> getSupportTickets(int affiliateId) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/affiliate/support-tickets/$affiliateId');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return _mockSupportTickets.where((t) => t['affiliate_id'] == affiliateId).toList();
    } catch (e) {
      throw Exception('Error fetching support tickets: $e');
    }
  }

  // Create support ticket
  Future<Map<String, dynamic>> createSupportTicket(int affiliateId, String subject, String description, String category) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/affiliate/support-tickets', {
      //   'affiliate_id': affiliateId,
      //   'subject': subject,
      //   'description': description,
      //   'category': category,
      // });
      // return response['data'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 600));
      final newTicket = {
        'id': _mockSupportTickets.length + 1,
        'affiliate_id': affiliateId,
        'subject': subject,
        'description': description,
        'status': 'open',
        'priority': 'medium',
        'category': category,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'assigned_to': 'Soporte Técnico',
        'messages': [
          {
            'id': 1,
            'sender': 'affiliate',
            'message': description,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ],
      };
      _mockSupportTickets.add(newTicket);
      return newTicket;
    } catch (e) {
      throw Exception('Error creating support ticket: $e');
    }
  }

  // Add message to support ticket
  Future<void> addMessageToTicket(int ticketId, String message) async {
    try {
      // TODO: Replace with real API call
      // await _apiService.post('/affiliate/support-tickets/$ticketId/messages', {
      //   'message': message,
      // });
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      final ticketIndex = _mockSupportTickets.indexWhere((t) => t['id'] == ticketId);
      if (ticketIndex != -1) {
        final newMessage = {
          'id': _mockSupportTickets[ticketIndex]['messages'].length + 1,
          'sender': 'affiliate',
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _mockSupportTickets[ticketIndex]['messages'].add(newMessage);
        _mockSupportTickets[ticketIndex]['updated_at'] = DateTime.now().toIso8601String();
      }
    } catch (e) {
      throw Exception('Error adding message to ticket: $e');
    }
  }

  // Get affiliate levels and requirements
  Future<List<Map<String, dynamic>>> getAffiliateLevels() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/affiliate/levels');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      return [
        {
          'level': 'Bronze',
          'requirements': '5 referidos activos',
          'commission_rate': 0.05,
          'benefits': ['Comisión básica', 'Soporte por email'],
        },
        {
          'level': 'Silver',
          'requirements': '20 referidos activos',
          'commission_rate': 0.08,
          'benefits': ['Comisión mejorada', 'Soporte prioritario', 'Dashboard avanzado'],
        },
        {
          'level': 'Gold',
          'requirements': '50 referidos activos',
          'commission_rate': 0.10,
          'benefits': ['Comisión máxima', 'Soporte 24/7', 'Herramientas avanzadas', 'Bonos especiales'],
        },
        {
          'level': 'Platinum',
          'requirements': '100 referidos activos',
          'commission_rate': 0.12,
          'benefits': ['Comisión premium', 'Soporte dedicado', 'Eventos exclusivos', 'Comisiones por niveles'],
        },
      ];
    } catch (e) {
      throw Exception('Error fetching affiliate levels: $e');
    }
  }

  // Get marketing materials
  Future<List<Map<String, dynamic>>> getMarketingMaterials() async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.get('/affiliate/marketing-materials');
      // return List<Map<String, dynamic>>.from(response['data']);
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 400));
      return [
        {
          'id': 1,
          'type': 'banner',
          'name': 'Banner Principal',
          'url': 'assets/default_avatar.png',
          'size': '728x90',
          'format': 'PNG',
        },
        {
          'id': 2,
          'type': 'banner',
          'name': 'Banner Lateral',
          'url': 'assets/default_avatar.png',
          'size': '300x250',
          'format': 'PNG',
        },
        {
          'id': 3,
          'type': 'social',
          'name': 'Post Instagram',
          'url': 'assets/default_avatar.png',
          'size': '1080x1080',
          'format': 'JPG',
        },
        {
          'id': 4,
          'type': 'email',
          'name': 'Template Email',
          'url': 'assets/default_avatar.png',
          'size': '600x400',
          'format': 'HTML',
        },
      ];
    } catch (e) {
      throw Exception('Error fetching marketing materials: $e');
    }
  }

  // Generate referral link
  Future<String> generateReferralLink(int affiliateId, String referralCode) async {
    try {
      // TODO: Replace with real API call
      // final response = await _apiService.post('/affiliate/generate-link', {
      //   'affiliate_id': affiliateId,
      //   'referral_code': referralCode,
      // });
      // return response['data']['link'];
      
      // Mock data for now
      await Future.delayed(Duration(milliseconds: 300));
      return 'https://zonix-eats.com/ref/$referralCode';
    } catch (e) {
      throw Exception('Error generating referral link: $e');
    }
  }
} 