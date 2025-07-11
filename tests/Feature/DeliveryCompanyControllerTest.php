<?php

namespace Tests\Feature;

use App\Models\DeliveryCompany;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeliveryCompanyControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_update_delivery_company_success()
    {
        $user = User::factory()->create(['role' => 'delivery_company']);
        $company = DeliveryCompany::factory()->create(['user_id' => $user->id]);

        $payload = [
            'business_name' => 'Empresa Nueva',
            'address' => 'Dirección Nueva',
            'phone' => '04141234567',
            'tax_id' => 'J-98765432-1',
        ];

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/delivery-companies/{$company->id}", $payload)
            ->assertStatus(200)
            ->assertJsonFragment(['business_name' => 'Empresa Nueva']);
    }

    public function test_update_delivery_company_validation_error()
    {
        $user = User::factory()->create(['role' => 'delivery_company']);
        $company = DeliveryCompany::factory()->create(['user_id' => $user->id]);

        $payload = [
            'business_name' => '',
            'address' => '',
            'phone' => '',
        ];

        $this->actingAs($user, 'sanctum')
            ->putJson("/api/delivery-companies/{$company->id}", $payload)
            ->assertStatus(422);
    }
} 