<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::put('commerces/{id}', [App\Http\Controllers\Admin\CommerceController::class, 'update']);
Route::put('delivery-companies/{id}', [App\Http\Controllers\DeliveryCompanyController::class, 'update']);
Route::put('delivery-agents/{id}', [App\Http\Controllers\DeliveryAgentController::class, 'update']);

Route::get('/reviews/{reviewableId}/{reviewableType}/can-review', [\App\Http\Controllers\ReviewController::class, 'canReview']);

// Rutas de actividad del usuario
Route::get('/activity', [\App\Http\Controllers\Buyer\ActivityController::class, 'getUserActivity']);
Route::get('/activity/stats', [\App\Http\Controllers\Buyer\ActivityController::class, 'getActivityStats']);
        // Rutas de exportación de datos personales
        Route::get('/export', [\App\Http\Controllers\Buyer\ExportController::class, 'exportAll']);
        // Rutas de privacidad
        Route::get('/privacy', [\App\Http\Controllers\Buyer\PrivacyController::class, 'getPrivacy']);
        Route::put('/privacy', [\App\Http\Controllers\Buyer\PrivacyController::class, 'updatePrivacy']);
        Route::delete('/account', [\App\Http\Controllers\Buyer\PrivacyController::class, 'deleteAccount']); 