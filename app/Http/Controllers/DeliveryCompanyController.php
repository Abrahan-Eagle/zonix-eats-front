<?php

namespace App\Http\Controllers;

use App\Models\DeliveryCompany;
use Illuminate\Http\Request;

class DeliveryCompanyController extends Controller
{
    public function update(Request $request, $id)
    {
        $company = DeliveryCompany::findOrFail($id);

        $validated = $request->validate([
            'business_name' => 'required|string|max:255',
            'address' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'tax_id' => 'nullable|string|max:30',
            // ...otros campos
        ]);

        $company->update($validated);

        return response()->json([
            'message' => 'Datos de la empresa de delivery actualizados correctamente',
            'company' => $company
        ]);
    }
} 