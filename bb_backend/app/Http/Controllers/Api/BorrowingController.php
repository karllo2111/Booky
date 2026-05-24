<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Book;
use App\Models\Borrowing;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class BorrowingController extends Controller
{
    public static function checkOverdueAndExpired()
    {
        $now = Carbon::now();

        // 1. Check overdue: active borrowings that have passed their due_date
        $overdues = Borrowing::with('book')
            ->where('status', 'active')
            ->where('due_date', '<', $now)
            ->get();

        foreach ($overdues as $b) {
            $b->update(['status' => 'overdue']);
            if ($b->book) {
                $b->book->updateAvailabilityStatus();
            }

            // Create notification if not already notified
            $exists = AppNotification::where('user_id', $b->user_id)
                ->where('borrowing_id', $b->id)
                ->where('title', 'Peminjaman Terlambat!')
                ->exists();

            if (!$exists) {
                AppNotification::create([
                    'user_id'      => $b->user_id,
                    'title'        => 'Peminjaman Terlambat!',
                    'message'      => "Buku \"{$b->book->title}\" Anda sudah melewati batas pengembalian (" . Carbon::parse($b->due_date)->format('d/m/Y') . "). Mohon segera kembalikan ke perpustakaan.",
                    'type'         => 'warning',
                    'borrowing_id' => $b->id,
                ]);
            }
        }

        // 2. Check expired bookings: pending bookings older than 24 hours
        $expiredBookings = Borrowing::with('book')
            ->where('status', 'pending')
            ->where('created_at', '<', $now->copy()->subHours(24))
            ->get();

        foreach ($expiredBookings as $b) {
            $b->update(['status' => 'cancelled', 'admin_notes' => 'Dibatalkan otomatis oleh sistem karena tidak diambil dalam 24 jam.']);
            if ($b->book) {
                $b->book->updateAvailabilityStatus();
            }

            AppNotification::create([
                'user_id'      => $b->user_id,
                'title'        => 'Booking Dibatalkan Otomatis',
                'message'      => "Booking untuk buku \"{$b->book->title}\" Anda dibatalkan secara otomatis karena tidak diambil dalam waktu 24 jam.",
                'type'         => 'info',
                'borrowing_id' => $b->id,
            ]);
        }
    }

    public function index(Request $request)
    {
        // Run self-healing overdue and expired check automatically
        self::checkOverdueAndExpired();

        $user = $request->user();

        if ($user->isAdmin()) {
            $query = Borrowing::with(['user', 'book.category']);

            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }
            if ($request->filled('user_id')) {
                $query->where('user_id', $request->user_id);
            }

            $borrowings = $query->latest()->paginate(15);
        } else {
            $borrowings = Borrowing::with(['book.category'])
                ->where('user_id', $user->id)
                ->latest()
                ->paginate(10);
        }

        return response()->json([
            'success' => true,
            'data' => $borrowings,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'book_id' => 'required|exists:books,id',
        ]);

        $book = Book::findOrFail($request->book_id);

        // Check active borrowings count vs book stock
        $activeCount = Borrowing::where('book_id', $request->book_id)
            ->whereIn('status', ['pending', 'active', 'overdue'])
            ->count();

        if ($activeCount >= $book->stock) {
            return response()->json([
                'success' => false,
                'message' => 'Buku ini sedang tidak tersedia untuk dipinjam (semua stok sedang dipinjam).',
            ], 422);
        }

        // Cek apakah user sudah memiliki peminjaman aktif untuk buku ini
        $existing = Borrowing::where('user_id', $request->user()->id)
            ->where('book_id', $request->book_id)
            ->whereIn('status', ['pending', 'active'])
            ->first();

        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memiliki peminjaman aktif untuk buku ini.',
            ], 422);
        }

        $borrowing = Borrowing::create([
            'user_id'     => $request->user()->id,
            'book_id'     => $request->book_id,
            'borrowed_at' => Carbon::now(),
            'due_date'    => Carbon::now()->addWeeks(2),
            'status'      => 'pending',
        ]);

        // Update availability dynamically
        $book->updateAvailabilityStatus();

        // Kirim notifikasi ke siswa
        AppNotification::create([
            'user_id'      => $request->user()->id,
            'title'        => 'Peminjaman Berhasil!',
            'message'      => "Peminjaman berhasil! Silakan ambil buku \"{$book->title}\" di Perpustakaan Lantai 1 pada jam istirahat pertama atau kedua. Mohon ambil buku di hari yang sama saat Anda melakukan pemesanan, batas waktu pinjam Anda adalah 2 minggu. Jika tidak diambil hingga batas akhir istirahat kedua hari ini, maka peminjaman Anda akan dibatalkan secara otomatis.",
            'type'         => 'success',
            'borrowing_id' => $borrowing->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Peminjaman berhasil! Silakan ambil buku Anda di Perpustakaan Lantai 1 pada jam istirahat pertama atau kedua. Mohon ambil buku di hari yang sama saat Anda melakukan pemesanan, batas waktu pinjam Anda adalah 2 minggu. Jika tidak diambil hingga batas akhir istirahat kedua hari ini, maka peminjaman Anda akan dibatalkan secara otomatis.',
            'data' => $borrowing->load(['user', 'book']),
        ], 201);
    }

    public function show($id)
    {
        $user = request()->user();

        $borrowing = Borrowing::with(['user', 'book.category'])->findOrFail($id);

        if (!$user->isAdmin() && $borrowing->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Akses ditolak.'], 403);
        }

        return response()->json([
            'success' => true,
            'data' => $borrowing,
        ]);
    }

    public function updateStatus(Request $request, $id)
    {
        $borrowing = Borrowing::with('book')->findOrFail($id);

        $request->validate([
            'status'      => 'required|in:pending,active,returned,overdue,cancelled',
            'admin_notes' => 'nullable|string',
        ]);

        $newStatus = $request->status;

        $updateData = ['status' => $newStatus];

        if ($request->filled('admin_notes')) {
            $updateData['admin_notes'] = $request->admin_notes;
        }

        if ($newStatus === 'returned') {
            $updateData['returned_at'] = Carbon::now();
        }

        $borrowing->update($updateData);

        // Update book availability dynamically
        if ($borrowing->book) {
            $borrowing->book->updateAvailabilityStatus();
        }

        // Notifikasi ke user
        $statusMessages = [
            'active'    => ['Peminjaman Dikonfirmasi', "Buku \"{$borrowing->book->title}\" Anda telah dikonfirmasi. Batas pengembalian: " . Carbon::parse($borrowing->due_date)->format('d/m/Y') . ".", 'success'],
            'returned'  => ['Buku Dikembalikan', "Buku \"{$borrowing->book->title}\" berhasil dikembalikan. Terima kasih!", 'success'],
            'overdue'   => ['Peminjaman Terlambat!', "Buku \"{$borrowing->book->title}\" Anda sudah melewati batas pengembalian. Segera kembalikan ke perpustakaan.", 'warning'],
            'cancelled' => ['Peminjaman Dibatalkan', "Peminjaman buku \"{$borrowing->book->title}\" Anda telah dibatalkan.", 'info'],
        ];

        if (isset($statusMessages[$newStatus])) {
            [$title, $message, $type] = $statusMessages[$newStatus];
            AppNotification::create([
                'user_id'      => $borrowing->user_id,
                'title'        => $title,
                'message'      => $message,
                'type'         => $type,
                'borrowing_id' => $borrowing->id,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Status peminjaman berhasil diperbarui.',
            'data' => $borrowing->fresh(['user', 'book']),
        ]);
    }

    public function cancel(Request $request, $id)
    {
        $borrowing = Borrowing::with('book')->findOrFail($id);

        if ($borrowing->user_id !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Akses ditolak.'], 403);
        }

        if (!in_array($borrowing->status, ['pending'])) {
            return response()->json([
                'success' => false,
                'message' => 'Peminjaman tidak dapat dibatalkan pada status ini.',
            ], 422);
        }

        $borrowing->update(['status' => 'cancelled']);
        
        if ($borrowing->book) {
            $borrowing->book->updateAvailabilityStatus();
        }

        return response()->json([
            'success' => true,
            'message' => 'Peminjaman berhasil dibatalkan.',
        ]);
    }
}
