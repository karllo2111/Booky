<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Wishlist;
use App\Models\Book;
use Illuminate\Http\Request;

class WishlistController extends Controller
{
    public function index(Request $request)
    {
        $wishlists = Wishlist::with('book.category')
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $wishlists,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'book_id' => 'required|exists:books,id',
        ]);

        $exists = Wishlist::where('user_id', $request->user()->id)
            ->where('book_id', $request->book_id)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'Buku sudah ada di wishlist Anda.',
            ], 422);
        }

        $wishlist = Wishlist::create([
            'user_id' => $request->user()->id,
            'book_id' => $request->book_id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Buku berhasil ditambahkan ke wishlist.',
            'data' => $wishlist->load('book.category'),
        ], 201);
    }

    public function destroy(Request $request, $bookId)
    {
        $wishlist = Wishlist::where('user_id', $request->user()->id)
            ->where('book_id', $bookId)
            ->firstOrFail();

        $wishlist->delete();

        return response()->json([
            'success' => true,
            'message' => 'Buku dihapus dari wishlist.',
        ]);
    }
}
