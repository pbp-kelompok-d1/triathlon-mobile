<div align="center">

# 🏊‍♂️🚴‍♂️🏃‍♂️ **TRIATHLON** [![Build Status](https://app.bitrise.io/app/3b5e62c5-5201-4305-a4a0-460a802bc349/status.svg?token=JdURd9e3M7Uzkr81PhIpIg&branch=main)](https://app.bitrise.io/app/3b5e62c5-5201-4305-a4a0-460a802bc349)  
### _Integrated Triathlon Lifestyle Platform_

</div>

---

## 👥 **Anggota Kelompok**
| Nama | NPM |
|------|------|
| Jarred Muhammad Raditya | 2406432425 |
| Justin Dwitama Seniang | 2406406742 |
| Muhammad Helmi Alfarissi | 2406402416 |
| Muhammad Kaila Aidam Riyan | 2406404781 |
| Randuichi Touya | 2406350021 |
| Syakirah Zahra Dhawini | 2406353950 |

---

## TAUTAN APLIKASI
[Download Triathlon Now!](https://app.bitrise.io/app/3b5e62c5-5201-4305-a4a0-460a802bc349/installable-artifacts/a264195e716c2995/public-install-page/a2b025bfb6cf98ac9d137a7a4960b988)

## 🧭 **Deskripsi Aplikasi**

Di tengah meningkatnya tren gaya hidup sehat dan popularitas olahraga ketahanan (endurance sports) seperti lari, sepeda, dan renang di Indonesia, muncul sebuah tantangan besar: **fragmentasi ekosistem digital.**

Data menunjukkan bahwa para pegiat olahraga ini seringkali harus berpindah-pindah platform untuk memenuhi kebutuhan mereka:

> Perjalanan digital seorang atlet saat ini sangat terpecah-belah. Mereka memulai dengan aplikasi pelacak seperti Strava untuk mencatat setiap detail jarak dan durasi latihan. Untuk kebutuhan sosial, seperti berdiskusi dan mencari teman berlatih, mereka beralih ke media sosial layaknya Facebook. Saat membutuhkan peralatan baru, mereka harus membuka aplikasi e-commerce seperti Tokopedia atau Shopee. Bahkan untuk hal mendasar seperti memesan kolam renang atau stadion, mereka masih sering dihadapkan pada sistem pemesanan manual, membuktikan betapa tersebarnya semua kebutuhan mereka di berbagai platform yang berbeda.

Fragmentasi ini menciptakan **inefisiensi** dan **memecah belah pengalaman pengguna.**  
Seorang atlet harus mengelola banyak akun, komunitasnya tersebar, dan sulit menemukan semua yang dibutuhkan dalam satu tempat.

**Triathlon** lahir sebagai solusi dari masalah ini. Aplikasi kami adalah **sebuah platform terintegrasi** yang dirancang khusus untuk komunitas olahraga ketahanan di Indonesia. Kami menyiapkan semua kebutuhan atlet dan para peminat olahraga—mulai dari **pelacakan aktivitas, interaksi komunitas, jual-beli perlengkapan, hingga pemesanan fasilitas**—ke dalam **satu ekosistem yang solid dan mudah diakses.**

## 🧩 **Daftar Modul yang Akan Diimplementasikan**

### 1. 👤 User Profile & Authentication — _Helmi_
Modul **User Profile** memungkinkan pengguna memiliki beberapa peran (_User, Seller, Facility Administrator_) dan melakukan **switch role** pada halaman profil. Tampilan data akan menyesuaikan role aktif:

- **User:** menampilkan aktivitas olahraga (Activities), forum post, dan review di Place Recommendation.  
- **Seller:** menampilkan daftar produk yang dijual (Shop).  
- **Facility Administrator:** menampilkan daftar fasilitas yang dikelola, opsi tambah fasilitas, serta daftar tiket pemesanan (Ticket).

Untuk dapat menghubungkan _backend_ django dengan _frontend_ flutter, modul **Authentication** dibuat. Modul ini berguna untuk melakukan register, login, logout pada aplikasi flutter melalui endpoint di django.

Selain itu, modul ini juga berpengaruh pada Profile View ketika pengguna lain melihat halaman profil seseorang: data yang ditampilkan tetap bergantung pada role aktif dari pemilik profil tersebut.

---

### 2. 💬 Forum — _Aidam_
Modul **Forum** memungkinkan user membuat, membaca, dan berinteraksi melalui **threads dan replies**, sistem diskusi terinspirasi Hypixel Forums.  
Fitur utama:
- Sistem **bumping otomatis** ketika ada balasan baru pada sebuah thread.
- Pengguna dapat memfilter thread berdasarkan kategori, popularitas, dan filter lainnya.

Fungsionalitas per peran:
- **User:** dapat membuat thread baru, membalas thread, melakukan edit atau delete pada post miliknya, serta memberi upvote/downvote pada thread atau balasan. 
- **Admin:** memiliki kemampuan moderasi seperti menghapus thread, mengunci diskusi, atau menandai thread tertentu sebagai pinned.


**Implementasi MVT Django:**
- **Model:**  Menyimpan data thread, reply, category dan upvote/downvote. Setiap thread memiliki atribut seperti judul, isi, pembuat, waktu dibuat, waktu terakhir dibalas, jumlah upvote/downvote, serta relasi ke kategori. Reply menyimpan isi balasan, pengirim, dan waktu. Field last_activity pada thread akan diperbarui setiap kali ada balasan baru untuk mendukung mekanisme thread dengan aktivitas terakhir di atas.  
- **View:** Mengelola logika untuk menampilkan daftar thread yang otomatis diurutkan berdasarkan recent activity, menampilkan detail thread beserta balasannya, memproses pembuatan, pengeditan, dan penghapusan thread atau reply, dan menangani upvote/downvote serta filtering.
- **Template:**  Menyediakan tampilan halaman utama forum dengan daftar thread yang bisa difilter. Halaman detail thread dengan daftar balasan secara hierarkis. Formulir untuk membuat thread baru dan membalas thread. Tombol interaksi seperti reply, edit, delete, upvote/downvote, dan filter dropdown.

---

### 3. 🛒 Shop — _Jarred_
Modul **Shop** memungkinkan pengguna berperan sebagai:
- **User:** melihat-lihat katalog, memasukkan produk ke keranjang, memasukkan produk ke wishlist dan melakukan pembelian.
- **Seller:** menambahkan produk, mengedit produk, dan menghapus produk.  
- **Admin:** menghapus produk dari semua user.

**Implementasi MVT Django:**
- **Model:** Menyimpan nama, harga, stok, category, thumbnail, description dari produk.
- **View:** Mengelola logika untuk menampilkan produk-produk yang dijual oleh masing-masing pengguna dan juga pengguna dapat melakukan aksi jual beli.  
- **Template:** Menyediakan interface untuk menampilkan semua produk, menambahkan produk, mengedit produk, menghapus produk, melakukan pembelian.
---

### 4. 🏃 Activities — _Touya_
Modul **Activities** memungkinkan pengguna untuk menyimpan data kegiatan olahraga mereka dalam aplikasi. Kegiatan tersebut disimpan pribadi setiap user pada page khusus, mirip user profile. Pada page ini, user dapat melihat kegiatan mereka sebelumnya, me-log aktivitas baru, dan melihat data aktivitas lebih rinci.

---

### 5. 🎫 Ticket — _Syakirah_
Modul Tiket adalah sebuah sistem terintegrasi yang dirancang untuk menyederhanakan proses pemesanan tiket masuk ke berbagai fasilitas olahraga. Modul ini menjembatani kebutuhan pengguna untuk mendapatkan akses yang mudah dan cepat, dengan kebutuhan administrator fasilitas untuk mengelola pesanan secara efisien dan terorganisir.
Fungsionalitas modul ini sebagai berikut:
- **User:** dapat dengan mudah mencari fasilitas olahraga yang diinginkan, memeriksa ketersediaan jadwal secara real-time, dan melakukan pemesanan tiket untuk tanggal serta waktu spesifik.
- **Administrator:** dapat memantau semua transaksi secara real-time melalui dashboard, melihat detail setiap pemesanan, dan melacak pendapatan dengan mudah.

---

### 6. 📍 Place — _Justin_
Modul Place memungkinkan pengguna untuk melihat berbagai rekomendasi tempat latihan yang tersedia. Fungsionalitas utamanya adalah:
Fungsionalitas:
- **User:** mencari tempat, melihat detail, memesan, memberi rating dan ulasan.  
- **Facility Administrator:** mendaftarkan fasilitas olahraganya, mengelola halaman informasi tempat dan memantau data pemesanan yang masuk.

---

## 🧑‍💻 **Role atau Aktor Pengguna**

| Role | Deskripsi |
|------|------------|
| **User** | Membuat dan mengedit Profile, melihat dan berbagi informasi di Forum, memantau aktivitas di Activities, melihat dan membeli perlengkapan di Shop, membeli tiket masuk fasilitas olahraga di Ticket, melihat rekomendasi tempat di Place Recommendation.|
| **Admin** | Memantau dan mengelola seluruh aktivitas aplikasi, moderasi Forum, mengelola data profile, memastikan modul Shop, Ticket, dan Place Recommendation berjalan lancar. |
| **Seller** | Menjual perlengkapan olahraga melalui modul Shop, mengelola produk (menambah, mengedit, dan menghapus), melihat pesanan. |
| **Facility Administrator** | Menyediakan tiket masuk fasilitas olahraga, mengelola profile tempat, melihat daftar pembeli tiket, memasukkan tempat ke dalam Place Recommendation. |

---

## 🔌 **Alur Pengintegrasian** 
Aplikasi mobile ini beroperasi sebagai client yang mengambil dan mengirim data ke proyek web (_backend_) yang telah dibuat sebelumnya. Komunikasi data dilakukan melalui REST API dengan format response JSON.

### **1. Mekanisme Autentikasi dan Session**

Saat pengguna login di aplikasi mobile, aplikasi akan mengirim request ke server berisi kredensial pengguna.
Jika kredensial valid, server akan mengembalikan cookies atau token autentikasi.
Aplikasi mobile kemudian menyimpan informasi session tersebut secara lokal. Penyimpanan dapat menggunakan package seperti pbp_django_auth atau provider terkait.
Selama session masih tersimpan dan valid, pengguna tidak perlu login ulang setiap kali berpindah halaman atau ketika melakukan request yang membutuhkan otorisasi seperti memposting di forum atau melakukan booking tiket.

### **2. Pengambilan Data (Data Fetching)**

Untuk menampilkan daftar data seperti daftar tempat olahraga (List Places), katalog produk, atau thread forum, aplikasi mobile melakukan request GET secara asynchronous ke endpoint API yang sesuai.
Response dari server berupa data JSON.
Data JSON ini kemudian diparsing menjadi objek model di Flutter.
Objek model tersebut digunakan untuk membangun dan menampilkan tampilan antarmuka (UI) di aplikasi mobile.

### **3. Pengiriman Data (Data Submission)**

Saat pengguna mengisi formulir, misalnya untuk membuat thread baru, menulis ulasan, atau menambah produk, data input dari pengguna akan dikumpulkan dan dikemas dalam format JSON.
Aplikasi kemudian mengirim data tersebut ke server menggunakan method POST ke endpoint API yang relevan.
Jika server mengembalikan status sukses, aplikasi akan menyesuaikan tampilan. Contohnya, aplikasi dapat memuat ulang daftar data terkait atau mengarahkan pengguna kembali ke halaman tertentu seperti halaman daftar ulasan.

### **4. Keterhubungan Antar Modul (Foreign Key)**

Relasi data antar modul diatur di sisi backend. Aplikasi mobile mengirimkan ID yang diperlukan sehingga backend dapat mencatat hubungan tersebut di database.
Contoh keterhubungan modul:

#### 🎫 Ticket dan Place
Saat pengguna memesan tiket, aplikasi akan mengirim ID tempat (Place ID) dan ID pengguna ke backend.
Backend mencatat pemesanan tersebut di database sehingga riwayat tiket dapat dikelola dengan benar.

#### 🚴 Activities dan Place
Fitur log activity mengambil referensi dari modul Place.
Pengguna hanya dapat memilih lokasi olahraga yang valid dan sudah terdaftar di sistem.

#### 💬 Forum dan Place
Saat pengguna membuat forum baru terkait suatu tempat, aplikasi mengirimkan ID tempat yang sedang dibahas serta ID pengguna ke backend.
Dengan cara ini, diskusi di forum dapat ditampilkan secara spesifik di halaman detail tempat olahraga yang bersangkutan.

---
## **Blog**
Syakirah - Ticket

https://medium.com/@syaasiui/building-scalable-flutter-features-lessons-from-implementing-a-ticket-management-module-e65ec27d93cd

Helmi - User Profile

https://medium.com/@alfarissimhelmi/elevating-user-experience-implementing-staggered-pulsing-animations-in-flutter-b969e37e4084 

Aidam - Forum 

1. https://www.linkedin.com/posts/aidamkaila_flutter-mobiledev-pbp-activity-7408457829206130688-hhN3?utm_source=social_share_send&utm_medium=member_desktop_web&rcm=ACoAAEDrR-kBC8BXmNvK2-1yT6nkUs4KDiCDHYw
2. https://www.linkedin.com/posts/aidamkaila_flutterperformance-mobileux-dart-activity-7408460584842825728-n6O8?utm_source=share&utm_medium=member_desktop&rcm=ACoAAEDrR-kBC8BXmNvK2-1yT6nkUs4KDiCDHYw
3. https://www.linkedin.com/posts/aidamkaila_unittesting-flutter-softwaretesting-activity-7408467574214057984-cJAr?utm_source=share&utm_medium=member_desktop&rcm=ACoAAEDrR-kBC8BXmNvK2-1yT6nkUs4KDiCDHYw

Jarred - Shop 

https://medium.com/@jarrrredddd/menghidupkan-ui-statis-implementasi-scroll-coupled-parallax-animation-pada-flutter-2bdb3919236e?postPublishedType=initial

Justin - Place

https://medium.com/@jdwitamaseniang/enhancing-user-experience-in-flutter-implementing-shimmer-loading-for-the-triathlon-app-70337c52d119

---
## 🔗 **Tautan Penting**

🏃‍♀️ **Sprint**
[Link Sheets](https://docs.google.com/spreadsheets/d/1wv4zPaE6LCFSGGPjezmJt8sShTBBssdVITUtwUqTJIo/edit?gid=1588075117#gid=1588075117)

🌐 **Deployment (PWS):**  
[Link Deployment](https://muhammad-kaila-triathlon.pbp.cs.ui.ac.id/)

🎨 **Figma Design:**  
[Figma Canvas Design](https://www.figma.com/design/4N2nIU7CkaN1RpViD1iRxu/Triathlon-Mobile?node-id=1-15&t=BzFDQnV09evDWk60-1)

---

<div align="center">

✨ _Where athletes connect, grow, and go further together._ 💪  
Proudly Present by **Team D1**

</div>