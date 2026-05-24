<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        // ── Admin account ─────────────────────────────────────────────────────
        User::updateOrCreate(
            ['email' => 'admin@booky.id'],
            [
                'name'     => 'Admin Booky',
                'email'    => 'admin@booky.id',
                'password' => Hash::make('password'),
                'role'     => 'admin',
                'phone'    => '082100000000',
            ]
        );

        // ── Student accounts ──────────────────────────────────────────────────
        $students = [
            ['name' => 'Andi Pratama',     'email' => 'andi@siswa.id',    'nis' => '2024001', 'kelas' => 'XII RPL 1', 'phone' => '081234560001'],
            ['name' => 'Budi Santoso',     'email' => 'budi@siswa.id',    'nis' => '2024002', 'kelas' => 'XI TKJ 2',  'phone' => '081234560002'],
            ['name' => 'Citra Dewi',       'email' => 'citra@siswa.id',   'nis' => '2024003', 'kelas' => 'X MM 1',    'phone' => '081234560003'],
            ['name' => 'Dian Rahayu',      'email' => 'dian@siswa.id',    'nis' => '2024004', 'kelas' => 'XII RPL 2', 'phone' => '081234560004'],
            ['name' => 'Eko Wijaya',       'email' => 'eko@siswa.id',     'nis' => '2024005', 'kelas' => 'XI AK 1',   'phone' => '081234560005'],
            ['name' => 'Fani Kusuma',      'email' => 'fani@siswa.id',    'nis' => '2024006', 'kelas' => 'XII TKJ 1', 'phone' => '081234560006'],
            ['name' => 'Gilang Ramadhan',  'email' => 'gilang@siswa.id',  'nis' => '2024007', 'kelas' => 'XI RPL 2',  'phone' => '081234560007'],
            ['name' => 'Hana Pertiwi',     'email' => 'hana@siswa.id',    'nis' => '2024008', 'kelas' => 'X AK 2',    'phone' => '081234560008'],
            ['name' => 'Indra Wijaya',     'email' => 'indra@siswa.id',   'nis' => '2024009', 'kelas' => 'XII MM 2',  'phone' => '081234560009'],
            ['name' => 'Joko Susilo',      'email' => 'joko@siswa.id',    'nis' => '2024010', 'kelas' => 'XI TKJ 1',  'phone' => '081234560010'],
            ['name' => 'Kartika Sari',     'email' => 'kartika@siswa.id', 'nis' => '2024011', 'kelas' => 'XII AK 1',  'phone' => '081234560011'],
            ['name' => 'Lukman Hakim',     'email' => 'lukman@siswa.id',  'nis' => '2024012', 'kelas' => 'XI MM 1',   'phone' => '081234560012'],
            ['name' => 'Maya Anggraini',   'email' => 'maya@siswa.id',    'nis' => '2024013', 'kelas' => 'X RPL 1',   'phone' => '081234560013'],
            ['name' => 'Nanda Prayoga',    'email' => 'nanda@siswa.id',   'nis' => '2024014', 'kelas' => 'XII TKJ 2', 'phone' => '081234560014'],
            ['name' => 'Okta Fitriani',    'email' => 'okta@siswa.id',    'nis' => '2024015', 'kelas' => 'XI AK 2',   'phone' => '081234560015'],
        ];

        foreach ($students as $s) {
            User::updateOrCreate(
                ['email' => $s['email']],
                array_merge($s, [
                    'password' => Hash::make('password'),
                    'role'     => 'student',
                ])
            );
        }
    }
}
