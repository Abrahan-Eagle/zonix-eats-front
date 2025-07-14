<?php

namespace App\Http\Controllers\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\JsonResponse;
use App\Models\User;
use App\Models\Profile;

class PrivacyController extends Controller
{
    /**
     * Eliminar la cuenta del usuario autenticado (y todos sus datos relacionados)
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            $profile = $user->profile;
            // Eliminar archivos asociados (fotos, documentos, etc.) si es necesario
            // ...
            // Eliminar perfil y usuario (cascade en DB)
            $profile?->delete();
            $user->delete();
            return response()->json([
                'success' => true,
                'message' => 'Cuenta eliminada correctamente'
            ]);
        } catch (\Exception $e) {
            Log::error('Error deleting user account: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar la cuenta'
            ], 500);
        }
    }

    /**
     * Actualizar configuración de privacidad (visibilidad de perfil, reviews, etc.)
     */
    public function updatePrivacy(Request $request): JsonResponse
    {
        try {
            $user = Auth::user();
            $profile = $user->profile;
            $data = $request->validate([
                'profile_visible' => 'boolean',
                'reviews_visible' => 'boolean',
                'order_history_visible' => 'boolean',
            ]);
            $profile->privacy_settings = array_merge($profile->privacy_settings ?? [], $data);
            $profile->save();
            return response()->json([
                'success' => true,
                'privacy_settings' => $profile->privacy_settings
            ]);
        } catch (\Exception $e) {
            Log::error('Error updating privacy settings: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar privacidad'
            ], 500);
        }
    }

    /**
     * Obtener configuración de privacidad
     */
    public function getPrivacy(Request $request): JsonResponse
    {
        $user = Auth::user();
        $profile = $user->profile;
        return response()->json([
            'success' => true,
            'privacy_settings' => $profile->privacy_settings ?? [
                'profile_visible' => true,
                'reviews_visible' => true,
                'order_history_visible' => true,
            ]
        ]);
    }
} 