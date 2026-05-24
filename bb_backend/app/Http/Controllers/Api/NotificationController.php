<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = AppNotification::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        $unreadCount = AppNotification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'success' => true,
            'data' => $notifications,
            'unread_count' => $unreadCount,
        ]);
    }

    public function markRead(Request $request, $id)
    {
        $notification = AppNotification::where('user_id', $request->user()->id)
            ->findOrFail($id);

        $notification->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi ditandai sudah dibaca.',
        ]);
    }

    public function markAllRead(Request $request)
    {
        AppNotification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Semua notifikasi ditandai sudah dibaca.',
        ]);
    }

    // Admin: kirim notifikasi
    public function send(Request $request)
    {
        $request->validate([
            'title'   => 'required|string|max:255',
            'message' => 'required|string',
            'type'    => 'required|in:info,reminder,warning,success',
            'user_id' => 'nullable|exists:users,id', // null = kirim ke semua siswa
        ]);

        if ($request->filled('user_id')) {
            AppNotification::create([
                'user_id' => $request->user_id,
                'title'   => $request->title,
                'message' => $request->message,
                'type'    => $request->type,
            ]);
            $count = 1;
        } else {
            $students = User::where('role', 'student')->pluck('id');
            $count = $students->count();
            foreach ($students as $userId) {
                AppNotification::create([
                    'user_id' => $userId,
                    'title'   => $request->title,
                    'message' => $request->message,
                    'type'    => $request->type,
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => "Notifikasi berhasil dikirim ke $count pengguna.",
        ]);
    }
}
