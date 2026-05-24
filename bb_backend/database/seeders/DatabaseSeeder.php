<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            AdminSeeder::class,     // 1 admin + 15 siswa
            CategorySeeder::class,  // 10 kategori buku
            BookSeeder::class,      // 30 buku dengan cover asli
            BorrowingSeeder::class, // ~20 data peminjaman (semua status)
        ]);
    }
}
