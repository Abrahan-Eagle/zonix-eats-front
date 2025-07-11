<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\Commerce;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CommerceControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_update_commerce_success()
    {
        $user = User::factory()->create(['role' => 'commerce']);
        $commerce = Commerce::factory()->create(['user_id' => $user->id]);

        $payload = [
            'business_name' => 'Nuevo Nombre',
            'address' => 'Nueva Dirección',
            'phone' => '04141234567',
            'tax_id' => 'J-12345678-9',
        ];

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/commerces/{$commerce->id}", $payload)
            ->assertStatus(200)
            ->assertJsonFragment(['business_name' => 'Nuevo Nombre']);
    }

    public function test_update_commerce_validation_error()
    {
        $user = User::factory()->create(['role' => 'commerce']);
        $commerce = Commerce::factory()->create(['user_id' => $user->id]);

        $payload = [
            'business_name' => '',
            'address' => '',
            'phone' => '',
        ];

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/commerces/{$commerce->id}", $payload)
            ->assertStatus(422);
    }
} 