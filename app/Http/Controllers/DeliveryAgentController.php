<?php

namespace App\Http\Controllers;

use App\Models\DeliveryAgent;
use Illuminate\Http\Request;

class DeliveryAgentController extends Controller
{
    public function update(Request $request, $id)
    {
        $agent = DeliveryAgent::findOrFail($id);

        $validated = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'vehicle_type' => 'nullable|string|max:50',
            'license_number' => 'nullable|string|max:50',
            // ...otros campos
        ]);

        $agent->update($validated);

        return response()->json([
            'message' => 'Datos del repartidor actualizados correctamente',
            'agent' => $agent
        ]);
    }
} 