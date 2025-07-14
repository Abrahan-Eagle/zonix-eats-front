<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Models\Order;
use App\Models\Review;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class ActivityController extends Controller
{
    /**
     * Obtener historial completo de actividad del usuario
     */
    public function getUserActivity(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            $profile = $user->profile;
            
            $perPage = $request->get('per_page', 20);
            $type = $request->get('type'); // orders, reviews, payments, etc.
            $startDate = $request->get('start_date');
            $endDate = $request->get('end_date');
            
            $activities = collect();
            
            // Actividad de órdenes
            if (!$type || $type === 'orders') {
                $orders = Order::where('buyer_id', $user->id)
                    ->with(['commerce', 'orderItems'])
                    ->when($startDate, function($query, $startDate) {
                        return $query->where('created_at', '>=', $startDate);
                    })
                    ->when($endDate, function($query, $endDate) {
                        return $query->where('created_at', '<=', $endDate);
                    })
                    ->orderBy('created_at', 'desc')
                    ->get()
                    ->map(function($order) {
                        return [
                            'id' => $order->id,
                            'type' => 'order',
                            'action' => 'order_created',
                            'title' => 'Orden creada',
                            'description' => "Orden #{$order->id} en {$order->commerce->name}",
                            'amount' => $order->total_amount,
                            'status' => $order->status,
                            'timestamp' => $order->created_at->toISOString(),
                            'data' => [
                                'order_id' => $order->id,
                                'commerce_name' => $order->commerce->name,
                                'items_count' => $order->orderItems->count(),
                                'payment_method' => $order->payment_method,
                            ]
                        ];
                    });
                $activities = $activities->merge($orders);
            }
            
            // Actividad de reviews
            if (!$type || $type === 'reviews') {
                $reviews = Review::where('buyer_id', $user->id)
                    ->with(['product', 'commerce'])
                    ->when($startDate, function($query, $startDate) {
                        return $query->where('created_at', '>=', $startDate);
                    })
                    ->when($endDate, function($query, $endDate) {
                        return $query->where('created_at', '<=', $endDate);
                    })
                    ->orderBy('created_at', 'desc')
                    ->get()
                    ->map(function($review) {
                        return [
                            'id' => $review->id,
                            'type' => 'review',
                            'action' => 'review_posted',
                            'title' => 'Reseña publicada',
                            'description' => "Reseña para {$review->product->name} en {$review->commerce->name}",
                            'rating' => $review->rating,
                            'timestamp' => $review->created_at->toISOString(),
                            'data' => [
                                'review_id' => $review->id,
                                'product_name' => $review->product->name,
                                'commerce_name' => $review->commerce->name,
                                'rating' => $review->rating,
                                'comment' => $review->comment,
                            ]
                        ];
                    });
                $activities = $activities->merge($reviews);
            }
            
            // Actividad de pagos
            if (!$type || $type === 'payments') {
                $payments = Order::where('buyer_id', $user->id)
                    ->whereNotNull('paid_at')
                    ->with(['commerce'])
                    ->when($startDate, function($query, $startDate) {
                        return $query->where('paid_at', '>=', $startDate);
                    })
                    ->when($endDate, function($query, $endDate) {
                        return $query->where('paid_at', '<=', $endDate);
                    })
                    ->orderBy('paid_at', 'desc')
                    ->get()
                    ->map(function($order) {
                        return [
                            'id' => $order->id,
                            'type' => 'payment',
                            'action' => 'payment_completed',
                            'title' => 'Pago completado',
                            'description' => "Pago de {$order->total_amount} PEN para orden #{$order->id}",
                            'amount' => $order->total_amount,
                            'timestamp' => $order->paid_at->toISOString(),
                            'data' => [
                                'order_id' => $order->id,
                                'payment_method' => $order->payment_method,
                                'commerce_name' => $order->commerce->name,
                                'transaction_id' => $order->payment_proof,
                            ]
                        ];
                    });
                $activities = $activities->merge($payments);
            }
            
            // Actividad de perfil
            if (!$type || $type === 'profile') {
                $profileActivities = collect([
                    [
                        'id' => 'profile_' . $profile->id,
                        'type' => 'profile',
                        'action' => 'profile_created',
                        'title' => 'Perfil creado',
                        'description' => 'Perfil de usuario creado',
                        'timestamp' => $profile->created_at->toISOString(),
                        'data' => [
                            'profile_id' => $profile->id,
                            'name' => $profile->firstName . ' ' . $profile->lastName,
                        ]
                    ]
                ]);
                $activities = $activities->merge($profileActivities);
            }
            
            // Actividad de login
            if (!$type || $type === 'login') {
                $loginActivities = collect([
                    [
                        'id' => 'login_' . time(),
                        'type' => 'login',
                        'action' => 'user_login',
                        'title' => 'Inicio de sesión',
                        'description' => 'Usuario inició sesión',
                        'timestamp' => now()->toISOString(),
                        'data' => [
                            'ip_address' => $request->ip(),
                            'user_agent' => $request->userAgent(),
                        ]
                    ]
                ]);
                $activities = $activities->merge($loginActivities);
            }
            
            // Ordenar por timestamp y paginar
            $activities = $activities->sortByDesc('timestamp');
            $total = $activities->count();
            $page = $request->get('page', 1);
            $offset = ($page - 1) * $perPage;
            $paginatedActivities = $activities->slice($offset, $perPage);
            
            return response()->json([
                'success' => true,
                'data' => [
                    'activities' => $paginatedActivities->values(),
                    'pagination' => [
                        'current_page' => $page,
                        'per_page' => $perPage,
                        'total' => $total,
                        'last_page' => ceil($total / $perPage),
                    ],
                    'summary' => [
                        'total_activities' => $total,
                        'orders_count' => $activities->where('type', 'order')->count(),
                        'reviews_count' => $activities->where('type', 'review')->count(),
                        'payments_count' => $activities->where('type', 'payment')->count(),
                        'total_spent' => $activities->where('type', 'payment')->sum('amount'),
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting user activity: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener historial de actividad'
            ], 500);
        }
    }
    
    /**
     * Obtener estadísticas de actividad
     */
    public function getActivityStats(): JsonResponse
    {
        try {
            $user = Auth::user();
            
            $stats = [
                'total_orders' => Order::where('buyer_id', $user->id)->count(),
                'completed_orders' => Order::where('buyer_id', $user->id)->where('status', 'delivered')->count(),
                'total_reviews' => Review::where('buyer_id', $user->id)->count(),
                'total_spent' => Order::where('buyer_id', $user->id)->whereNotNull('paid_at')->sum('total_amount'),
                'average_rating' => Review::where('buyer_id', $user->id)->avg('rating'),
                'favorite_restaurants' => Order::where('buyer_id', $user->id)
                    ->with('commerce')
                    ->get()
                    ->groupBy('commerce_id')
                    ->count(),
                'activity_by_month' => $this->getActivityByMonth($user->id),
            ];
            
            return response()->json([
                'success' => true,
                'data' => $stats
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting activity stats: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener estadísticas de actividad'
            ], 500);
        }
    }
    
    /**
     * Obtener actividad por mes
     */
    private function getActivityByMonth($userId): array
    {
        $months = [];
        for ($i = 11; $i >= 0; $i--) {
            $date = now()->subMonths($i);
            $monthKey = $date->format('Y-m');
            
            $orders = Order::where('buyer_id', $userId)
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->count();
                
            $spent = Order::where('buyer_id', $userId)
                ->whereYear('paid_at', $date->year)
                ->whereMonth('paid_at', $date->month)
                ->sum('total_amount');
                
            $months[$monthKey] = [
                'orders' => $orders,
                'spent' => $spent,
                'month_name' => $date->format('M Y'),
            ];
        }
        
        return $months;
    }
} 