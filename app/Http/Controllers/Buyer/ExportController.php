<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\JsonResponse;
use App\Models\Profile;
use App\Models\Order;
use App\Models\Review;
use App\Models\Notification;
use App\Models\Address;
use App\Models\Document;

class ExportController extends Controller
{
    /**
     * Exportar todos los datos personales del usuario autenticado
     */
    public function exportAll(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            $profile = $user->profile;

            $data = [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'created_at' => $user->created_at,
                ],
                'profile' => $profile,
                'addresses' => Address::where('profile_id', $profile->id)->get(),
                'documents' => Document::where('profile_id', $profile->id)->get(),
                'preferences' => $profile->preferences ?? [],
                'orders' => Order::where('buyer_id', $user->id)->with(['orderItems', 'commerce'])->get(),
                'reviews' => Review::where('buyer_id', $user->id)->with(['product', 'commerce'])->get(),
                'notifications' => Notification::where('profile_id', $profile->id)->get(),
            ];

            // Guardar como archivo temporal (opcional, aquí solo devolvemos JSON)
            // $filename = 'user_export_' . $user->id . '_' . now()->timestamp . '.json';
            // Storage::disk('local')->put($filename, json_encode($data, JSON_PRETTY_PRINT));

            return response()->json([
                'success' => true,
                'data' => $data,
                // 'download_url' => Storage::url($filename),
            ]);
        } catch (\Exception $e) {
            Log::error('Error exporting user data: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al exportar datos personales'
            ], 500);
        }
    }
} 