<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Book;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class BookController extends Controller
{
    public function index(Request $request)
    {
        $query = Book::with('category');

        if ($request->filled('q')) {
            $q = $request->q;
            $query->where(function ($sub) use ($q) {
                $sub->where('title', 'like', "%$q%")
                    ->orWhere('author', 'like', "%$q%");
            });
        }

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->filled('availability')) {
            $query->where('availability', $request->availability);
        }

        $books = $query->latest()->paginate(12);

        return response()->json([
            'success' => true,
            'data' => $books,
        ]);
    }

    public function show($id)
    {
        // Load details including category and active borrowings with the borrowing student name
        $book = Book::with(['category', 'borrowings' => function ($query) {
            $query->whereIn('status', ['pending', 'active', 'overdue'])->with('user');
        }])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $book,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'category_id'  => 'required|exists:categories,id',
            'title'        => 'required|string|max:255',
            'author'       => 'required|string|max:255',
            'publisher'    => 'nullable|string|max:255',
            'year'         => 'nullable|integer|min:1900|max:2099',
            'isbn'         => 'nullable|string|unique:books,isbn',
            'description'  => 'nullable|string',
            'cover_url'    => 'nullable|string',
            'cover_image'  => 'nullable|image|mimes:jpeg,png,jpg,gif|max:5120',
            'stock'        => 'required|integer|min:0',
            'availability' => 'required|in:available,borrowed,late',
        ]);

        $data = $request->all();

        // Handle uploaded cover image
        if ($request->hasFile('cover_image')) {
            $file = $request->file('cover_image');
            $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            // Ensure path exists
            if (!file_exists(public_path('covers'))) {
                mkdir(public_path('covers'), 0777, true);
            }
            $file->move(public_path('covers'), $filename);
            $data['cover_url'] = url('covers/' . $filename);
        }

        $book = Book::create($data);
        $book->updateAvailabilityStatus();

        return response()->json([
            'success' => true,
            'message' => 'Buku berhasil ditambahkan.',
            'data' => $book->load('category'),
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $book = Book::findOrFail($id);

        $request->validate([
            'category_id'  => 'sometimes|exists:categories,id',
            'title'        => 'sometimes|string|max:255',
            'author'       => 'sometimes|string|max:255',
            'publisher'    => 'nullable|string|max:255',
            'year'         => 'nullable|integer|min:1900|max:2099',
            'isbn'         => 'nullable|string|unique:books,isbn,' . $id,
            'description'  => 'nullable|string',
            'cover_url'    => 'nullable|string',
            'cover_image'  => 'nullable|image|mimes:jpeg,png,jpg,gif|max:5120',
            'stock'        => 'sometimes|integer|min:0',
            'availability' => 'sometimes|in:available,borrowed,late',
        ]);

        $data = $request->all();

        // Handle uploaded cover image
        if ($request->hasFile('cover_image')) {
            $file = $request->file('cover_image');
            $filename = time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            if (!file_exists(public_path('covers'))) {
                mkdir(public_path('covers'), 0777, true);
            }
            $file->move(public_path('covers'), $filename);
            $data['cover_url'] = url('covers/' . $filename);
        }

        $book->update($data);
        $book->updateAvailabilityStatus();

        return response()->json([
            'success' => true,
            'message' => 'Buku berhasil diperbarui.',
            'data' => $book->load('category'),
        ]);
    }

    public function destroy($id)
    {
        $book = Book::findOrFail($id);
        $book->delete();

        return response()->json([
            'success' => true,
            'message' => 'Buku berhasil dihapus.',
        ]);
    }

    public function updateAvailability(Request $request, $id)
    {
        $book = Book::findOrFail($id);
        $request->validate([
            'availability' => 'required|in:available,borrowed,late',
        ]);
        $book->update(['availability' => $request->availability]);
        $book->updateAvailabilityStatus();

        return response()->json([
            'success' => true,
            'message' => 'Status buku berhasil diperbarui.',
            'data' => $book,
        ]);
    }
}
