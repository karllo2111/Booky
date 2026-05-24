<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Book extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id', 'title', 'author', 'publisher', 'year',
        'isbn', 'description', 'cover_url', 'stock', 'availability',
    ];

    protected $casts = [
        'year' => 'integer',
        'stock' => 'integer',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function borrowings()
    {
        return $this->hasMany(Borrowing::class);
    }

    public function wishlists()
    {
        return $this->hasMany(Wishlist::class);
    }

    public function activeBorrowing()
    {
        return $this->hasOne(Borrowing::class)->whereIn('status', ['pending', 'active']);
    }

    /**
     * Recalculate and update the book's availability status dynamically.
     */
    public function updateAvailabilityStatus(): void
    {
        $activeCount = $this->borrowings()
            ->whereIn('status', ['pending', 'active', 'overdue'])
            ->count();

        $hasOverdue = $this->borrowings()
            ->where('status', 'overdue')
            ->exists();

        if ($activeCount >= $this->stock) {
            $this->update(['availability' => 'borrowed']);
        } elseif ($hasOverdue) {
            $this->update(['availability' => 'late']);
        } else {
            $this->update(['availability' => 'available']);
        }
    }
}
