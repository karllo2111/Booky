<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Fiksi',       'description' => 'Novel, cerpen, dan karya fiksi lainnya',       'icon' => 'auto_stories'],
            ['name' => 'Non-Fiksi',   'description' => 'Buku berdasarkan fakta dan realita',           'icon' => 'menu_book'],
            ['name' => 'Sains',       'description' => 'Ilmu pengetahuan alam dan eksak',              'icon' => 'science'],
            ['name' => 'Sejarah',     'description' => 'Sejarah nasional dan dunia',                   'icon' => 'history_edu'],
            ['name' => 'Teknologi',   'description' => 'Pemrograman, komputer, dan IT',                'icon' => 'computer'],
            ['name' => 'Sastra',      'description' => 'Puisi, drama, dan karya sastra',               'icon' => 'edit_note'],
            ['name' => 'Biografi',    'description' => 'Kisah nyata tokoh-tokoh inspiratif',           'icon' => 'person'],
            ['name' => 'Agama',       'description' => 'Buku keagamaan dan spiritual',                 'icon' => 'mosque'],
            ['name' => 'Pendidikan',  'description' => 'Buku pelajaran dan referensi akademik',        'icon' => 'school'],
            ['name' => 'Kesehatan',   'description' => 'Kesehatan, olahraga, dan gaya hidup sehat',   'icon' => 'favorite'],
        ];

        foreach ($categories as $cat) {
            Category::updateOrCreate(['name' => $cat['name']], $cat);
        }
    }
}
