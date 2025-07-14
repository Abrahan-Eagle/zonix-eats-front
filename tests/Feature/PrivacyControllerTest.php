<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Profile;
use Illuminate\Foundation\Testing\RefreshDatabase;

class PrivacyControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $profile;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create(['role' => 'users']);
        $this->profile = Profile::factory()->create(['user_id' => $this->user->id]);
    }

    public function test_get_privacy_settings()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/buyer/privacy');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'privacy_settings'
            ]);
    }

    public function test_update_privacy_settings()
    {
        $privacyData = [
            'profile_visible' => false,
            'reviews_visible' => true,
            'order_history_visible' => false,
        ];

        $response = $this->actingAs($this->user)
            ->putJson('/api/buyer/privacy', $privacyData);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'privacy_settings'
            ]);
    }

    public function test_delete_account()
    {
        $response = $this->actingAs($this->user)
            ->deleteJson('/api/buyer/account');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Cuenta eliminada correctamente'
            ]);

        $this->assertDatabaseMissing('users', ['id' => $this->user->id]);
        $this->assertDatabaseMissing('profiles', ['id' => $this->profile->id]);
    }

    public function test_privacy_requires_authentication()
    {
        $response = $this->getJson('/api/buyer/privacy');
        $response->assertStatus(401);
    }
} 