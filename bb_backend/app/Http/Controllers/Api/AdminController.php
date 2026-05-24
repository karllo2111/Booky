<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Book;
use App\Models\Borrowing;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class AdminController extends Controller
{
    public function dashboard()
    {
        $totalBooks     = Book::count();
        $totalStudents  = User::where('role', 'student')->count();
        $activeBorrows  = Borrowing::whereIn('status', ['pending', 'active'])->count();
        $overdueBorrows = Borrowing::where('status', 'overdue')->count();
        $returnedToday  = Borrowing::where('status', 'returned')
            ->whereDate('returned_at', Carbon::today())
            ->count();
        $pendingBorrows = Borrowing::where('status', 'pending')->count();

        $recentBorrowings = Borrowing::with(['user', 'book'])
            ->latest()
            ->take(5)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'stats' => [
                    'total_books'     => $totalBooks,
                    'total_students'  => $totalStudents,
                    'active_borrows'  => $activeBorrows,
                    'overdue_borrows' => $overdueBorrows,
                    'returned_today'  => $returnedToday,
                    'pending_borrows' => $pendingBorrows,
                ],
                'recent_borrowings' => $recentBorrowings,
            ],
        ]);
    }

    public function users(Request $request)
    {
        $query = User::where('role', 'student');

        if ($request->filled('q')) {
            $q = $request->q;
            $query->where(function ($sub) use ($q) {
                $sub->where('name', 'like', "%$q%")
                    ->orWhere('email', 'like', "%$q%")
                    ->orWhere('nis', 'like', "%$q%");
            });
        }

        $users = $query->withCount(['borrowings as active_borrow_count' => function ($q) {
            $q->whereIn('status', ['pending', 'active']);
        }])->latest()->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    public function updateUser(Request $request, $id)
    {
        $user = User::where('role', 'student')->findOrFail($id);

        $request->validate([
            'name'  => 'sometimes|string|max:255',
            'kelas' => 'nullable|string|max:50',
            'phone' => 'nullable|string|max:20',
            'nis'   => 'nullable|string|unique:users,nis,' . $id,
        ]);

        $user->update($request->only(['name', 'kelas', 'phone', 'nis']));

        return response()->json([
            'success' => true,
            'message' => 'Data siswa berhasil diperbarui.',
            'data' => $user->fresh(),
        ]);
    }

    public function deleteUser($id)
    {
        $user = User::where('role', 'student')->findOrFail($id);

        if ($user->borrowings()->whereIn('status', ['pending', 'active'])->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus siswa yang masih memiliki peminjaman aktif.',
            ], 422);
        }

        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'Data siswa berhasil dihapus.',
        ]);
    }

    public function sendReminder(Request $request, $borrowingId)
    {
        $borrowing = Borrowing::with(['user', 'book'])->findOrFail($borrowingId);

        $dueDate = Carbon::parse($borrowing->due_date)->format('d/m/Y');

        AppNotification::create([
            'user_id'      => $borrowing->user_id,
            'title'        => '⏰ Pengingat Pengembalian Buku',
            'message'      => "Halo {$borrowing->user->name}! Pengingat bahwa buku \"{$borrowing->book->title}\" harus dikembalikan paling lambat tanggal {$dueDate}. Mohon kembalikan tepat waktu ya!",
            'type'         => 'reminder',
            'borrowing_id' => $borrowing->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Pengingat berhasil dikirim ke {$borrowing->user->name}.",
        ]);
    }
}
