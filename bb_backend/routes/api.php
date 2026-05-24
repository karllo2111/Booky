<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\BorrowingController;
use App\Http\Controllers\Api\WishlistController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\AdminController;

// ─── Public Routes ────────────────────────────────────────────────────────────
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login',    [AuthController::class, 'login']);
});

// Public: buku & kategori (bisa dilihat tanpa login)
Route::get('/books',            [BookController::class, 'index']);
Route::get('/books/{id}',       [BookController::class, 'show']);
Route::get('/categories',       [CategoryController::class, 'index']);

// ─── Authenticated Routes ─────────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    // Auth
    Route::prefix('auth')->group(function () {
        Route::post('/logout',          [AuthController::class, 'logout']);
        Route::get('/me',               [AuthController::class, 'me']);
        Route::put('/profile',          [AuthController::class, 'updateProfile']);
    });

    // Wishlist
    Route::get('/wishlist',             [WishlistController::class, 'index']);
    Route::post('/wishlist',            [WishlistController::class, 'store']);
    Route::delete('/wishlist/{bookId}', [WishlistController::class, 'destroy']);

    // Borrowings (user sees own, admin sees all)
    Route::get('/borrowings',           [BorrowingController::class, 'index']);
    Route::post('/borrowings',          [BorrowingController::class, 'store']);
    Route::get('/borrowings/{id}',      [BorrowingController::class, 'show']);
    Route::post('/borrowings/{id}/cancel', [BorrowingController::class, 'cancel']);

    // Notifications
    Route::get('/notifications',              [NotificationController::class, 'index']);
    Route::post('/notifications/{id}/read',   [NotificationController::class, 'markRead']);
    Route::post('/notifications/read-all',    [NotificationController::class, 'markAllRead']);

    // ─── Admin-only Routes ─────────────────────────────────────────────────────
    Route::middleware('admin')->group(function () {

        // Books CRUD
        Route::post('/books',                [BookController::class, 'store']);
        Route::put('/books/{id}',            [BookController::class, 'update']);
        Route::delete('/books/{id}',         [BookController::class, 'destroy']);
        Route::patch('/books/{id}/availability', [BookController::class, 'updateAvailability']);

        // Categories CRUD
        Route::post('/categories',           [CategoryController::class, 'store']);
        Route::put('/categories/{id}',       [CategoryController::class, 'update']);
        Route::delete('/categories/{id}',    [CategoryController::class, 'destroy']);

        // Borrowings management
        Route::put('/borrowings/{id}/status', [BorrowingController::class, 'updateStatus']);

        // Notifications
        Route::post('/notifications/send',   [NotificationController::class, 'send']);

        // Admin dashboard & user management
        Route::get('/admin/dashboard',           [AdminController::class, 'dashboard']);
        Route::get('/admin/users',               [AdminController::class, 'users']);
        Route::put('/admin/users/{id}',          [AdminController::class, 'updateUser']);
        Route::delete('/admin/users/{id}',       [AdminController::class, 'deleteUser']);
        Route::post('/admin/remind/{borrowingId}', [AdminController::class, 'sendReminder']);
    });
});
