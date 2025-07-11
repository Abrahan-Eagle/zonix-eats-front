<?php

namespace Tests\Feature;

use App\Models\DeliveryAgent;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeliveryAgentControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_update_delivery_agent_success()
    {
        $user = User::factory()->create(['role' => 'delivery_agent']);
        $agent = DeliveryAgent::factory()->create(['user_id' => $user->id]);

        $payload = [
            'first_name' => 'Juan',
            'last_name' => 'Pérez',
            'phone' => '04141234567',
            'vehicle_type' => 'Moto',
            'license_number' => 'ABC123',
        ];

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/delivery-agents/{$agent->id}", $payload)
            ->assertStatus(200)
            ->assertJsonFragment(['first_name' => 'Juan']);
    }

    public function test_update_delivery_agent_validation_error()
    {
        $user = User::factory()->create(['role' => 'delivery_agent']);
        $agent = DeliveryAgent::factory()->create(['user_id' => $user->id]);

        $payload = [
            'first_name' => '',
            'last_name' => '',
            'phone' => '',
        ];

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/delivery-agents/{$agent->id}", $payload)
            ->assertStatus(422);
    }
} 