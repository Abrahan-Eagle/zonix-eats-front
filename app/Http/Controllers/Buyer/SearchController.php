<?php

namespace App\Http\Controllers\Buyer;

use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class SearchController
{
    public function getCategories(): JsonResponse
    {
        try {
            $categories = Category::orderBy('name')->get(['id', 'name', 'description']);
            return response()->json([
                'success' => true,
                'data' => $categories
            ]);
        } catch (\Exception $e) {
            Log::error('Error getting categories: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener las categorías'
            ], 500);
        }
    }
} 