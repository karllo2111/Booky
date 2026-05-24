# BookingBooksApp - Complete App Flow Documentation

## Overview
BookingBooksApp adalah aplikasi perpustakaan sekolah dengan sistem peminjaman buku berbasis mobile (Flutter) dan backend (Laravel). Aplikasi ini memungkinkan siswa untuk mencari, meminjam, dan mengelola wishlist buku, serta admin untuk mengelola data buku, kategori, siswa, dan memonitor peminjaman.

## Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Laravel (PHP)
- **Database**: MySQL
- **Authentication**: Laravel Sanctum (Token-based)

## User Roles
1. **Admin**: Mengelola data buku, kategori, siswa, dan memonitor peminjaman
2. **Siswa**: Mencari buku, meminjam buku, mengelola wishlist, dan melihat riwayat peminjaman

---

## Complete User Flows

### 1. Authentication Flow

#### 1.1 Login Flow (Admin & Siswa)
```
User opens app
  ↓
Login Screen displayed
  ↓
User enters email & password
  ↓
Tap "Masuk" button
  ↓
API call: POST /api/login
  ↓
Success?
  ├─ Yes → Save token, navigate to appropriate home screen
  │         - Admin → AdminHomeScreen
  │         - Siswa → HomeScreen
  └─ No → Show error message
```

#### 1.2 Registration Flow (Siswa Only)
```
From Login Screen
  ↓
Tap "Daftar" link
  ↓
Register Screen displayed
  ↓
User fills: Nama, Email, Password, NIS, Kelas, Nomor HP
  ↓
Tap "Daftar" button
  ↓
API call: POST /api/register
  ↓
Success?
  ├─ Yes → Auto-login, navigate to HomeScreen
  └─ No → Show error message
```

#### 1.3 Logout Flow
```
User taps logout button
  ↓
Confirmation dialog shown
  ↓
User confirms
  ↓
Clear stored token & user data
  ↓
Navigate to Login Screen
```

---

### 2. Student Flows

#### 2.1 Home Screen Flow
```
User opens app (logged in as student)
  ↓
HomeScreen displayed with:
  - Welcome message with user name
  - Notification badge
  - Notice banner
  - Category filters (horizontal scroll)
  - Book collection grid
  ↓
User can:
  - Tap notification icon → NotificationScreen
  - Tap category filter → Filter books by category
  - Tap book card → BookDetailScreen
  - Tap "Peminjaman Saya" FAB → BorrowingScreen
  - Switch bottom nav tabs
```

#### 2.2 Book Search Flow
```
From HomeScreen or via bottom nav
  ↓
SearchScreen displayed
  ↓
User types in search bar
  ↓
API call: GET /api/books?search={query}
  ↓
Results displayed in grid
  ↓
User can:
  - Apply category filters
  - Tap book card → BookDetailScreen
  - Clear search
```

#### 2.3 Book Detail Flow
```
User taps book card
  ↓
BookDetailScreen displayed with:
  - Book cover image
  - Title, author, publisher, year
  - Stock availability
  - Category chip
  - Description
  - "Pinjam Sekarang" button (if available)
  ↓
User can:
  - Tap bookmark icon → Add/Remove from wishlist
  - Tap "Pinjam Sekarang" → Borrowing flow
```

#### 2.4 Book Borrowing Flow
```
From BookDetailScreen
  ↓
User taps "Pinjam Sekarang"
  ↓
Confirmation dialog shown with:
  - Book title
  - Borrowing rules (2 weeks, pickup location)
  ↓
User confirms
  ↓
API call: POST /api/borrowings
  ↓
Success?
  ├─ Yes → Show success dialog, refresh book detail
  │         - Book availability updated
  │         - Borrowing status: "pending" (booking)
  └─ No → Show error message
```

#### 2.5 Borrowing Management Flow
```
From HomeScreen FAB or bottom nav
  ↓
BorrowingScreen displayed
  ↓
Filter dropdown (All, Booking, Dipinjam, Kembali, Terlambat, Batal)
  ↓
List of borrowings shown with:
  - Book cover & title
  - Status badge
  - Due date / pickup deadline
  - Admin notes (if any)
  ↓
For "pending" status:
  - User can tap "Batalkan" → Cancel borrowing
  ↓
API call: POST /api/borrowings/{id}/cancel
  ↓
Success?
  ├─ Yes → Remove from list, show success message
  └─ No → Show error message
```

#### 2.6 Wishlist Flow
```
From bottom nav
  ↓
WishlistScreen displayed
  ↓
Grid of saved books shown
  ↓
User can:
  - Tap book card → BookDetailScreen
  - Tap delete icon → Remove from wishlist
  ↓
API call: DELETE /api/wishlists/{bookId}
  ↓
Success?
  ├─ Yes → Remove from grid, show success message
  └─ No → Show error message
```

#### 2.7 Notification Flow
```
From HomeScreen notification icon
  ↓
NotificationScreen displayed
  ↓
List of notifications shown with:
  - Message
  - Timestamp
  - Read/unread status
  ↓
User can:
  - Pull to refresh
  - Mark as read (automatically on view)
```

#### 2.8 Profile Flow
```
From bottom nav
  ↓
ProfileScreen displayed with:
  - User avatar (initial)
  - Name, email, role
  - NIS, Kelas, Nomor HP
  ↓
User taps edit icon
  ↓
Form fields become editable
  ↓
User modifies: Name, Kelas, Nomor HP
  ↓
Tap "Simpan Perubahan"
  ↓
API call: PUT /api/profile
  ↓
Success?
  ├─ Yes → Update UI, show success message
  └─ No → Show error message
  ↓
User can also:
  - Tap "Log Out" → Logout flow
```

---

### 3. Admin Flows

#### 3.1 Admin Home Flow
```
Admin logs in
  ↓
AdminHomeScreen displayed with:
  - Welcome message
  - Stats cards (Total Buku, Total Siswa, Peminjaman Aktif, Terlambat)
  - Management menu grid:
    - Kelola Buku
    - Kelola Kategori
    - Kelola Siswa
    - Monitor Pinjam
    - Kirim Notifikasi
  ↓
User taps menu item → Navigate to respective screen
```

#### 3.2 Book Management Flow
```
From AdminHomeScreen
  ↓
BookManagementScreen displayed
  ↓
List of all books shown with:
  - Cover thumbnail
  - Title, author
  - Availability badge
  - Stock count
  - Edit/Delete actions
  ↓
User can:
  - Tap search bar → Search books
  - Tap add icon → Add new book
  - Tap edit icon → Edit book
  - Tap delete icon → Delete book
```

#### 3.2.1 Add/Edit Book Flow
```
User taps add/edit icon
  ↓
Modal bottom sheet displayed with form:
  - Judul Buku (required)
  - Penulis (required)
  - Kategori (dropdown)
  - Ketersediaan (dropdown)
  - Stok (required)
  - Tahun Terbit
  - Penerbit
  - URL Gambar Cover
  - Deskripsi Buku
  ↓
User fills form
  ↓
Tap "Simpan"
  ↓
API call:
  - Add: POST /api/admin/books
  - Edit: PUT /api/admin/books/{id}
  ↓
Success?
  ├─ Yes → Close modal, refresh list, show success message
  └─ No → Show error message
```

#### 3.2.2 Delete Book Flow
```
User taps delete icon
  ↓
Confirmation dialog shown
  ↓
User confirms
  ↓
API call: DELETE /api/admin/books/{id}
  ↓
Success?
  ├─ Yes → Remove from list, show success message
  └─ No → Show error message
```

#### 3.3 Category Management Flow
```
From AdminHomeScreen
  ↓
CategoryManagementScreen displayed
  ↓
List of categories shown with:
  - Icon
  - Name
  - Description
  - Edit/Delete actions
  ↓
User can:
  - Tap add icon → Add new category
  - Tap edit icon → Edit category
  - Tap delete icon → Delete category
```

#### 3.4 User Management Flow
```
From AdminHomeScreen
  ↓
UserManagementScreen displayed
  ↓
List of students shown with:
  - Name
  - Email
  - NIS
  - Kelas
  - Edit/Delete actions
  ↓
User can:
  - Tap add icon → Add new student
  - Tap edit icon → Edit student
  - Tap delete icon → Delete student
```

#### 3.5 Borrowing Monitor Flow
```
From AdminHomeScreen
  ↓
BorrowingMonitorScreen displayed
  ↓
Filter dropdown (All, Pending, Active, Returned, Overdue, Cancelled)
  ↓
List of borrowings shown with:
  - Book title
  - Student name & class
  - Status badge
  - Due date
  - Admin notes
  - Actions: "Ubah Status", "Kirim Pengingat"
  ↓
User can:
  - Tap "Ubah Status" → Update borrowing status
  - Tap "Kirim Pengingat" → Send reminder notification
```

#### 3.5.1 Update Borrowing Status Flow
```
User taps "Ubah Status"
  ↓
Dialog displayed with:
  - Book & student info
  - Status dropdown (Pending, Active, Returned, Overdue, Cancelled)
  - Admin notes field (optional)
  ↓
User selects new status & adds notes
  ↓
Tap "Simpan"
  ↓
API call: PUT /api/admin/borrowings/{id}
  ↓
Success?
  ├─ Yes → Update list, show success message
  │         - Notification sent to student if applicable
  └─ No → Show error message
```

#### 3.5.2 Send Reminder Flow
```
User taps "Kirim Pengingat" (for active/overdue)
  ↓
API call: POST /api/admin/remind/{borrowingId}
  ↓
Success?
  ├─ Yes → Show success message
  │         - Notification sent to student
  └─ No → Show error message
```

#### 3.6 Send Notification Flow
```
From AdminHomeScreen
  ↓
AdminNotificationScreen displayed
  ↓
Form with:
  - Target audience (All students / Specific class)
  - Message
  ↓
User fills form
  ↓
Tap "Kirim"
  ↓
API call: POST /api/admin/notifications
  ↓
Success?
  ├─ Yes → Show success message
  │         - Notifications sent to target students
  └─ No → Show error message
```

---

## API Endpoints

### Authentication
- `POST /api/login` - Login user
- `POST /api/register` - Register new student
- `POST /api/logout` - Logout user
- `GET /api/profile` - Get current user profile
- `PUT /api/profile` - Update user profile

### Books
- `GET /api/books` - List all books (with search & filter)
- `GET /api/books/{id}` - Get book details
- `POST /api/admin/books` - Create new book (admin only)
- `PUT /api/admin/books/{id}` - Update book (admin only)
- `DELETE /api/admin/books/{id}` - Delete book (admin only)

### Categories
- `GET /api/categories` - List all categories
- `POST /api/admin/categories` - Create category (admin only)
- `PUT /api/admin/categories/{id}` - Update category (admin only)
- `DELETE /api/admin/categories/{id}` - Delete category (admin only)

### Borrowings
- `GET /api/borrowings` - List user's borrowings
- `POST /api/borrowings` - Create borrowing request
- `POST /api/borrowings/{id}/cancel` - Cancel borrowing
- `GET /api/admin/borrowings` - List all borrowings (admin only)
- `PUT /api/admin/borrowings/{id}` - Update borrowing status (admin only)
- `POST /api/admin/remind/{id}` - Send reminder (admin only)

### Wishlists
- `GET /api/wishlists` - List user's wishlist
- `POST /api/wishlists` - Add book to wishlist
- `DELETE /api/wishlists/{bookId}` - Remove from wishlist

### Notifications
- `GET /api/notifications` - List user's notifications
- `POST /api/admin/notifications` - Send notification (admin only)

### Users (Admin)
- `GET /api/admin/users` - List all users (admin only)
- `POST /api/admin/users` - Create user (admin only)
- `PUT /api/admin/users/{id}` - Update user (admin only)
- `DELETE /api/admin/users/{id}` - Delete user (admin only)

### Dashboard
- `GET /api/admin/dashboard` - Get dashboard stats (admin only)

---

## Database Schema

### Users
- id
- name
- email
- password (hashed)
- role (admin/student)
- nis (Nomor Induk Siswa)
- kelas (Class)
- phone
- created_at
- updated_at

### Categories
- id
- name
- description
- icon
- created_at
- updated_at

### Books
- id
- category_id
- title
- author
- publisher
- year
- isbn
- description
- cover_url
- stock
- availability (available/borrowed/late)
- created_at
- updated_at

### Borrowings
- id
- user_id
- book_id
- status (pending/active/returned/overdue/cancelled)
- borrowed_at
- due_date
- returned_at
- admin_notes
- created_at
- updated_at

### Wishlists
- id
- user_id
- book_id
- created_at

### Notifications
- id
- user_id
- message
- is_read
- created_at

---

## Key Features

### For Students
1. **Book Discovery**: Browse and search books by title, author, or category
2. **Borrowing System**: Book books with 2-week borrowing period
3. **Wishlist**: Save books for later
4. **Borrowing History**: Track current and past borrowings
5. **Notifications**: Receive reminders and updates
6. **Profile Management**: Update personal information

### For Admins
1. **Book Management**: Add, edit, delete books with cover images
2. **Category Management**: Organize books into categories
3. **User Management**: Manage student accounts
4. **Borrowing Monitoring**: Track all borrowing requests and statuses
5. **Status Updates**: Approve, reject, or update borrowing status
6. **Notifications**: Send broadcast notifications to students
7. **Dashboard**: View statistics and overview

---

## Business Rules

1. **Borrowing Period**: Maximum 2 weeks (14 days)
2. **Pickup Location**: Library, 1st Floor, during break time (Istirahat 2)
3. **Booking System**: Students must book first, then pick up physically
4. **Late Returns**: Marked as "overdue" after due date
5. **Stock Management**: Book availability depends on stock count
6. **Cancellation**: Students can cancel pending bookings only
7. **Reminders**: Admin can send reminders for active/overdue borrowings

---

## Error Handling

Common error scenarios:
- **Invalid credentials**: Show "Email atau password salah"
- **Book unavailable**: Show "Buku tidak tersedia"
- **Already borrowed**: Show "Anda sudah meminjam buku ini"
- **Stock exhausted**: Show "Stok buku habis"
- **Network error**: Show "Gagal terhubung ke server"
- **Validation error**: Show specific field errors

---

## Security Considerations

1. **Authentication**: Token-based authentication using Laravel Sanctum
2. **Authorization**: Role-based access control (admin vs student)
3. **Data Validation**: Server-side validation for all inputs
4. **Password Security**: Hashed using bcrypt
5. **API Protection**: Sanctum middleware for protected routes

---

## Future Enhancements

Potential features for future development:
1. **QR Code Scanning**: For book checkout/return
2. **Fine System**: Automatic calculation of late fees
3. **Book Reservations**: Queue system for popular books
4. **Reading History**: Track books read by students
5. **Book Reviews**: Allow students to rate and review books
6. **Recommendation Engine**: Suggest books based on reading history
7. **Barcode Integration**: For faster book processing
8. **Email Notifications**: Send email reminders in addition to in-app
9. **Export Reports**: Generate borrowing reports for admin
10. **Multi-language Support**: Support for Indonesian and English

---

## Deployment Checklist

### Backend
- [ ] Configure environment variables (.env)
- [ ] Set up database and run migrations
- [ ] Run seeders for initial data
- [ ] Configure CORS for frontend domain
- [ ] Set up SSL/HTTPS
- [ ] Configure queue worker for notifications (if using queues)

### Frontend
- [ ] Configure API base URL
- [ ] Set up proper error handling
- [ ] Test on iOS and Android
- [ ] Configure app icons and splash screens
- [ ] Set up app signing for release builds
- [ ] Test all user flows end-to-end

---

## Contact & Support

For issues or questions about the BookingBooksApp:
- **Project Name**: BookingBooksApp
- **Backend**: Laravel API
- **Frontend**: Flutter Mobile App
- **Database**: MySQL

---

*Last Updated: 2026-05-24*
