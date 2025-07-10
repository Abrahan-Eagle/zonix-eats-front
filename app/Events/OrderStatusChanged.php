<?php

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderStatusChanged implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $order;

    /**
     * Create a new event instance.
     */
    public function __construct(Order $order)
    {
        $this->order = $order;
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn()
    {
        // Puedes personalizar el canal según el comercio, usuario, etc.
        return new PrivateChannel('orders.' . $this->order->id);
    }

    public function broadcastWith()
    {
        return [
            'order_id' => $this->order->id,
            'estado' => $this->order->estado,
            'updated_at' => $this->order->updated_at,
        ];
    }

    public function broadcastAs()
    {
        return 'OrderStatusChanged';
    }
} 