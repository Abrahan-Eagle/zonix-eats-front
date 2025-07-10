<?php

namespace App\Http\Controllers\Commerce;

use App\Events\OrderStatusChanged;
use App\Models\Order;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function updateStatus($id, $status)
    {
        $order = Order::where('commerce_id', Auth::id())->findOrFail($id);
        $order->estado = $status;
        $order->save();
        event(new OrderStatusChanged($order));
        return response()->json(['message' => 'Estado de la orden actualizado']);
    }

    public function validarComprobante(Request $request, $id)
    {
        $request->validate([
            'accion' => 'required|in:validar,rechazar',
        ]);
        $order = \App\Models\Order::where('commerce_id', \Auth::id())->findOrFail($id);
        if (!$order->comprobante_url) {
            return response()->json(['error' => 'No hay comprobante para validar'], 400);
        }
        if ($request->accion === 'validar') {
            $order->estado = 'comprobante_validado';
        } else {
            $order->estado = 'comprobante_rechazado';
        }
        $order->save();
        event(new OrderStatusChanged($order));
        return response()->json(['message' => 'Comprobante ' . $request->accion, 'estado' => $order->estado]);
    }
} 