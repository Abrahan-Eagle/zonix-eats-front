<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = [
            ['name' => 'Hamburguesas', 'description' => 'Deliciosas hamburguesas de todo tipo'],
            ['name' => 'Pizzas', 'description' => 'Pizzas artesanales y clásicas'],
            ['name' => 'Sushi', 'description' => 'Variedad de sushi y rolls'],
            ['name' => 'Pollo', 'description' => 'Pollo frito, a la brasa y más'],
            ['name' => 'Postres', 'description' => 'Dulces, helados y repostería'],
            ['name' => 'Bebidas', 'description' => 'Refrescos, jugos y más'],
            ['name' => 'Tacos', 'description' => 'Tacos mexicanos y tex-mex'],
            ['name' => 'Ensaladas', 'description' => 'Opciones frescas y saludables'],
            ['name' => 'Comida China', 'description' => 'Platos típicos chinos'],
            ['name' => 'Sandwiches', 'description' => 'Sandwiches y bocadillos variados'],
        ];
        foreach ($categories as $cat) {
            Category::firstOrCreate(['name' => $cat['name']], $cat);
        }
    }
} 