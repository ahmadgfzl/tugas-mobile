# Rental Motor App

Aplikasi rental motor full-stack:

- Mobile App: Flutter (login, register, list motor, detail & sewa, riwayat sewa)
- Backend API: Node.js Express + MySQL (auth JWT, CRUD motorcycles, rentals)
- Admin Dashboard: Static HTML+JS (login admin, CRUD motor, update status rental)

## 1. Struktur Proyek

```
backend/
	src/
		config/ env.js
		db/ index.js
		models/ userModel.js motorcycleModel.js rentalModel.js
		controllers/ authController.js motorcycleController.js rentalController.js
		routes/ authRoutes.js motorcycleRoutes.js rentalRoutes.js
		middleware/ auth.js
		utils/ response.js
		server.js
	public/admin/index.html (dashboard admin)
lib/
	models/ services/ providers/ screens/ utils/
```

## 2. Setup Database MySQL

Jalankan di MySQL (buat database terlebih dahulu):

```sql
CREATE DATABASE rental_motor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE rental_motor;

CREATE TABLE users (
	id INT AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	email VARCHAR(120) NOT NULL UNIQUE,
	password_hash VARCHAR(255) NOT NULL,
	role ENUM('user','admin') DEFAULT 'user',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE motorcycles (
	id INT AUTO_INCREMENT PRIMARY KEY,
	brand VARCHAR(100) NOT NULL,
	model VARCHAR(100) NOT NULL,
	plate_number VARCHAR(50) NOT NULL,
	price_per_day DECIMAL(10,2) NOT NULL,
	available TINYINT DEFAULT 1,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE rentals (
	id INT AUTO_INCREMENT PRIMARY KEY,
	user_id INT NOT NULL,
	motorcycle_id INT NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE NOT NULL,
	total_price DECIMAL(10,2) NOT NULL,
	status ENUM('pending','approved','rejected','returned') DEFAULT 'pending',
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
	FOREIGN KEY (motorcycle_id) REFERENCES motorcycles(id) ON DELETE CASCADE
);
```

Tambahkan akun admin manual (ganti hash sesuai bcrypt 10 rounds). Contoh menghasilkan hash di Node REPL:

```js
// node
const bcrypt = require('bcrypt'); bcrypt.hash('admin123',10).then(console.log);
```

Lalu insert:

```sql
INSERT INTO users(name,email,password_hash,role) VALUES('Admin','admin@example.com','<HASH_HASIL_BCRYPT>','admin');
```

## 3. Konfigurasi Backend

Salin `.env.example` menjadi `.env` di folder `backend/` dan sesuaikan kredensial database.

Contoh:

```
PORT=3000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=yourpassword
DB_NAME=rental_motor
JWT_SECRET=supersecretjwt
TOKEN_EXPIRES=7d
```

Install dependency & jalankan:

```bash
cd backend
npm install
npm run dev
```

Health check: buka http://localhost:3000/api/health

Dashboard admin: http://localhost:3000/admin

### 3.1 Seeding Admin Otomatis

Script seeding akan otomatis membuat user admin jika belum ada, menggunakan variabel ENV:

```
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123
```

Jika ingin mematikannya, hapus variabel atau kosongkan nilainya. Log akan menampilkan `[seed] Admin user created:` saat pertama kali dibuat.

## 4. Menjalankan Aplikasi Flutter

Pastikan device/emulator jalan, lalu dari root project:

```bash
flutter pub get
flutter run
```

API base URL di Flutter saat ini menggunakan `http://localhost:3000/api`. Untuk device fisik ganti ke IP lokal (misal 192.168.x.x) di `lib/utils/api_endpoints.dart`.

## 5. Endpoint Utama API (Ringkas)

- POST /api/auth/register
- POST /api/auth/login
- GET /api/motorcycles
- POST /api/motorcycles (admin)
- PUT /api/motorcycles/:id (admin)
- DELETE /api/motorcycles/:id (admin)
	- Juga menghapus file gambar terkait dari storage.
  
- DELETE /api/motorcycles/:id/images/:imageId (admin)
	- Hapus satu gambar galeri motor tertentu, termasuk file fisiknya.
	- Jika gambar yang dihapus adalah cover (motorcycles.image_url), cover otomatis diganti ke gambar pertama yang tersisa (atau null jika kosong).

- POST /api/motorcycles/:id/images (admin)
	- Upload banyak gambar sekaligus (field form-data: `images` multiple), menambahkan ke galeri. Jika cover belum ada, otomatis di-set ke file pertama yang diunggah.
- POST /api/rentals (user)
- GET /api/rentals/me (user)
- GET /api/rentals (admin)
- PATCH /api/rentals/:id/status (admin)
- GET /api/users/me (auth)
- PUT /api/users/me (auth)
- PUT /api/users/me/password (auth)

Header auth: `Authorization: Bearer <token>`

## 6. Flow Penggunaan Mobile

1. Register / Login
2. Lihat list motor
3. Pilih motor, tentukan tanggal mulai & akhir, klik Sewa
4. Lihat riwayat & status di halaman Riwayat (Rentals)

## 7. Roadmap Lanjutan (TODO)

- Upload foto motor & caching gambar
- Pagination & pencarian
- Pembayaran (integrasi Midtrans / Xendit)
- Notifikasi push status rental
- Internationalization (i18n)
- Unit test & integration test

## 7.2 Profil Pengguna (Drawer + API)

- Drawer pada Home memiliki menu "Profil" untuk melihat dan mengubah data akun.
- Halaman Profil memiliki form: Nama, Email, Password baru (opsional).
- API yang digunakan:
	- GET `/api/users/me` untuk mengambil data profil saat ini.
	- PUT `/api/users/me` untuk memperbarui profil. Body JSON: `{ name, email, password? }`.
	- PUT `/api/users/me/password` untuk mengganti password. Body JSON: `{ current_password, new_password, confirm_password }`.
- Pastikan token terset di header Authorization. Jika 401, lakukan login ulang.

Catatan keamanan:
- Setelah password berhasil diubah dari aplikasi, pengguna akan otomatis di-logout dan diminta login ulang menggunakan password baru.

## 7.1 Upload Gambar Motor (Baru)

Kolom `image_url` telah ditambahkan. Jika database lama, jalankan:

```sql
ALTER TABLE motorcycles ADD COLUMN image_url VARCHAR(255) NULL;
```

Endpoint upload (admin):

```
POST /api/motorcycles/:id/image
Form-data field: image (file)
Auth: Bearer token admin
Max size: 2MB | Tipe: jpeg, png, webp
```

Contoh curl:

```bash
curl -X POST \
	-H "Authorization: Bearer <ADMIN_TOKEN>" \
	-F image=@/path/to/local/file.jpg \
	http://localhost:3000/api/motorcycles/1/image
```

Response sukses:

```json
{
	"success": true,
	"message": "Image uploaded",
	"data": {
		"id": 1,
		"brand": "...",
		"model": "...",
		"image_url": "/uploads/motorcycles/1_1738685300000.jpg",
		"plate_number": "...",
		"price_per_day": 100000,
		"available": 1
	}
}
```

File lama akan dihapus otomatis saat upload baru untuk motor yang sama.

Di Flutter: field `image_url` sudah dipetakan ke `imageUrl` pada model `Motorcycle` dan ditampilkan di halaman detail.

### 7.1.1 Multi Gambar per Motor & Daftar Gambar

- Tabel `motorcycle_images` digunakan untuk menyimpan banyak gambar per motor.
- GET `/api/motorcycles` sekarang mengembalikan setiap item motor dengan properti tambahan `images` (array), berisi daftar gambar terkait.
- Endpoint hapus gambar: `DELETE /api/motorcycles/:id/images/:imageId` (admin) untuk menghapus satu gambar dan file-nya.
 - Endpoint unggah banyak gambar: `POST /api/motorcycles/:id/images` (admin). Field: `images` (multiple files).

## 8. Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Flutter tidak bisa akses localhost | Gunakan IP lokal, contoh 192.168.1.5 di `ApiConfig.baseUrl` |
| 401 Unauthorized | Pastikan token tersimpan & header Authorization terkirim |
| Cannot connect MySQL | Cek port, user/password, hak akses, jalankan `mysql -u root -p` manual |
| CORS error | Pastikan server berjalan & tidak double port, cors sudah diaktifkan di `server.js` |

## 9. Lisensi

Proyek contoh edukasi. Gunakan & modifikasi sesuai kebutuhan.

