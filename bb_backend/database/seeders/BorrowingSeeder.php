<?php

namespace Database\Seeders;

use App\Models\Book;
use App\Models\User;
use App\Models\Borrowing;
use App\Models\Notification;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class BorrowingSeeder extends Seeder
{
    public function run(): void
    {
        $students = User::where('role', 'student')->get()->keyBy('email');
        $books    = Book::all()->keyBy('title');
        $now      = Carbon::now();

        if ($students->isEmpty() || $books->isEmpty()) {
            return;
        }

        // Helper closure
        $student = fn(string $email) => $students[$email] ?? $students->first();
        $book    = fn(string $title) => $books[$title]  ?? $books->first();

        // ── 1. Active borrowings (sedang dipinjam, belum lewat batas) ────────
        $actives = [
            ['email' => 'andi@siswa.id',    'title' => 'Laskar Pelangi',                     'days_ago' => 5],
            ['email' => 'budi@siswa.id',    'title' => 'Atomic Habits',                      'days_ago' => 3],
            ['email' => 'citra@siswa.id',   'title' => 'Clean Code',                         'days_ago' => 7],
            ['email' => 'dian@siswa.id',    'title' => 'Sapiens: A Brief History of Humankind', 'days_ago' => 2],
            ['email' => 'eko@siswa.id',     'title' => 'Bumi Manusia',                        'days_ago' => 9],
            ['email' => 'fani@siswa.id',    'title' => 'Elon Musk',                           'days_ago' => 1],
        ];

        foreach ($actives as $row) {
            $s          = $student($row['email']);
            $b          = $book($row['title']);
            $borrowedAt = $now->copy()->subDays($row['days_ago']);
            $dueDate    = $borrowedAt->copy()->addDays(14);

            Borrowing::updateOrCreate(
                ['user_id' => $s->id, 'book_id' => $b->id, 'status' => 'active'],
                [
                    'borrowed_at' => $borrowedAt,
                    'due_date'    => $dueDate,
                    'returned_at' => null,
                    'admin_notes' => null,
                ]
            );

            $b->updateAvailabilityStatus();
        }

        // ── 2. Overdue borrowings (melewati batas, belum dikembalikan) ───────
        $overdues = [
            ['email' => 'gilang@siswa.id', 'title' => 'Rich Dad Poor Dad',                'days_ago' => 17, 'note' => 'Mohon segera dikembalikan, sudah melewati batas waktu.'],
            ['email' => 'hana@siswa.id',   'title' => 'Perahu Kertas',                    'days_ago' => 20, 'note' => 'Sudah 6 hari terlambat. Harap segera kembalikan.'],
            ['email' => 'indra@siswa.id',  'title' => 'The Pragmatic Programmer',         'days_ago' => 18, 'note' => 'Buku sangat dibutuhkan siswa lain. Segera kembalikan.'],
            ['email' => 'joko@siswa.id',   'title' => 'Design Patterns',                  'days_ago' => 25, 'note' => 'Peringatan terakhir. Buku sudah 11 hari terlambat.'],
        ];

        foreach ($overdues as $row) {
            $s          = $student($row['email']);
            $b          = $book($row['title']);
            $borrowedAt = $now->copy()->subDays($row['days_ago']);
            $dueDate    = $borrowedAt->copy()->addDays(14);

            Borrowing::updateOrCreate(
                ['user_id' => $s->id, 'book_id' => $b->id, 'status' => 'overdue'],
                [
                    'borrowed_at' => $borrowedAt,
                    'due_date'    => $dueDate,
                    'returned_at' => null,
                    'admin_notes' => $row['note'],
                ]
            );

            $b->updateAvailabilityStatus();
        }

        // ── 3. Pending borrowings (booking, belum diambil) ───────────────────
        $pendings = [
            ['email' => 'kartika@siswa.id', 'title' => 'Negeri 5 Menara',        'note' => 'Menunggu pengambilan di perpustakaan. Ambil saat istirahat.'],
            ['email' => 'lukman@siswa.id',  'title' => 'Steve Jobs',              'note' => 'Menunggu pengambilan. Batas ambil: 2 hari ke depan.'],
            ['email' => 'maya@siswa.id',    'title' => 'Thinking, Fast and Slow', 'note' => 'Siap diambil di meja perpustakaan.'],
        ];

        foreach ($pendings as $row) {
            $s          = $student($row['email']);
            $b          = $book($row['title']);
            $borrowedAt = $now->copy()->subHours(rand(1, 6));
            $dueDate    = $borrowedAt->copy()->addDays(14);

            Borrowing::updateOrCreate(
                ['user_id' => $s->id, 'book_id' => $b->id, 'status' => 'pending'],
                [
                    'borrowed_at' => $borrowedAt,
                    'due_date'    => $dueDate,
                    'returned_at' => null,
                    'admin_notes' => $row['note'],
                ]
            );
        }

        // ── 4. Returned borrowings (sudah dikembalikan) ──────────────────────
        $returneds = [
            ['email' => 'nanda@siswa.id',  'title' => 'Laskar Pelangi',          'days_ago' => 40, 'note' => 'Dikembalikan tepat waktu. Terima kasih.'],
            ['email' => 'okta@siswa.id',   'title' => 'Ayat-Ayat Cinta',         'days_ago' => 35, 'note' => 'Dikembalikan lebih awal. Buku dalam kondisi baik.'],
            ['email' => 'andi@siswa.id',   'title' => 'Cosmos',                  'days_ago' => 50, 'note' => 'Dikembalikan tepat waktu.'],
            ['email' => 'budi@siswa.id',   'title' => 'A Brief History of Time', 'days_ago' => 28, 'note' => 'Dikembalikan 3 hari lebih awal.'],
            ['email' => 'citra@siswa.id',  'title' => 'Sitti Nurbaya',           'days_ago' => 22, 'note' => 'Kondisi buku baik.'],
            ['email' => 'dian@siswa.id',   'title' => 'Fiqih Islam',             'days_ago' => 60, 'note' => 'Dikembalikan tepat waktu.'],
            ['email' => 'eko@siswa.id',    'title' => 'Elon Musk',               'days_ago' => 45, 'note' => 'Terima kasih telah mengembalikan tepat waktu.'],
        ];

        foreach ($returneds as $row) {
            $s          = $student($row['email']);
            $b          = $book($row['title']);
            $borrowedAt = $now->copy()->subDays($row['days_ago']);
            $dueDate    = $borrowedAt->copy()->addDays(14);
            $returnedAt = $dueDate->copy()->subDays(rand(0, 3));

            Borrowing::updateOrCreate(
                ['user_id' => $s->id, 'book_id' => $b->id, 'status' => 'returned'],
                [
                    'borrowed_at' => $borrowedAt,
                    'due_date'    => $dueDate,
                    'returned_at' => $returnedAt,
                    'admin_notes' => $row['note'],
                ]
            );
        }

        // ── 5. Cancelled borrowings ───────────────────────────────────────────
        $cancelleds = [
            ['email' => 'fani@siswa.id',   'title' => 'Salah Asuhan',   'note' => 'Dibatalkan oleh siswa.'],
            ['email' => 'gilang@siswa.id', 'title' => 'Why We Sleep',   'note' => 'Buku diperlukan mendadak oleh siswa lain, booking dibatalkan.'],
        ];

        foreach ($cancelleds as $row) {
            $s          = $student($row['email']);
            $b          = $book($row['title']);
            $borrowedAt = $now->copy()->subDays(rand(5, 15));
            $dueDate    = $borrowedAt->copy()->addDays(14);

            Borrowing::updateOrCreate(
                ['user_id' => $s->id, 'book_id' => $b->id, 'status' => 'cancelled'],
                [
                    'borrowed_at' => $borrowedAt,
                    'due_date'    => $dueDate,
                    'returned_at' => null,
                    'admin_notes' => $row['note'],
                ]
            );
        }
    }
}
