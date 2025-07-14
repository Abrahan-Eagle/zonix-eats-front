<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Profile;
use App\Models\Order;
use App\Models\Review;
use App\Models\Commerce;
use App\Models\Product;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ActivityControllerTest extends TestCase
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

    public function test_get_user_activity()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/buyer/activity');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'activities',
                    'pagination',
                    'summary'
                ]
            ]);
    }

    public function test_get_activity_stats()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/buyer/activity/stats');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'total_orders',
                    'completed_orders',
                    'total_reviews',
                    'total_spent',
                    'average_rating',
                    'favorite_restaurants',
                    'activity_by_month'
                ]
            ]);
    }

    public function test_get_user_activity_with_filters()
    {
        $response = $this->actingAs($this->user)
            ->getJson('/api/buyer/activity?type=orders&per_page=10');

        $response->assertStatus(200);
    }
} 