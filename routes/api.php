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