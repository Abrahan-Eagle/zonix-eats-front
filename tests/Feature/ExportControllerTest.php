<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Profile;
use App\Models\Order;
use App\Models\Review;
use App\Models\Address;
use App\Models\Document;
use App\Models\Notification;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ExportControllerTest extends TestCase
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

    public function test_export_all_user_data()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/buyer/export');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'user',
                    'profile',
                    'addresses',
                    'documents',
                    'preferences',
                    'orders',
                    'reviews',
                    'notifications'
                ]
            ]);
    }

    public function test_export_requires_authentication()
    {
        $response = $this->getJson('/api/buyer/export');
        $response->assertStatus(401);
    }
} 