# Assignment 9 – Flutter x Django Integration

This iteration wires the Flutter client to the Django backend so that authentication, product listings, and product creation all flow through real APIs.

## Features

- 🔐 **Session-based auth** using `pbp_django_auth` and `Provider` so login/logout state persists across the app.
- 📱 **Login & Register screens** that post to `/auth/login/` and `/auth/register/` and surface server-side error messages.
- 🧭 **Drawer navigation** with quick links to Home, All Products, My Products, Create Product, plus a logout action that clears the Django session.
- 📦 **All/My product lists** driven by `/json/` and `/json/user/` endpoints using the `ProductEntry` model, including pull-to-refresh and detail navigation.
- 📝 **Create product form** that validates user input locally and submits JSON to `/create-flutter/`, showing success/error SnackBars.
- 🖼 **Image proxy support** automatically routes external thumbnails through `/proxy-image/` for reliable rendering on every platform.

## Try it locally

```powershell
cd c:\Users\Aidam\pbp_flutter\KosinduyYNWA-mobile
flutter pub get
flutter run
```

Make sure the Django server (from `kosinduyYNWA_django_server`) is running on `http://10.0.2.2:8000` so the mobile app can hit the endpoints listed above.

## Tests

```powershell
flutter test
```

The widget test now validates that the login screen renders correctly.

---

# TUGAS 7 - Elemen Dasar Flutter

## Jelaskan apa itu widget tree pada Flutter dan bagaimana hubungan parent-child (induk-anak) bekerja antar widget.

Widget tree adalah struktur hierarki yang menggambarkan komposisi seluruh antarmuka pengguna dalam aplikasi Flutter. Setiap widget dapat memiliki widget lain sebagai child-nya, membentuk pohon (tree) yang dimulai dari widget root (biasanya MaterialApp atau CupertinoApp) hingga ke widget leaf (widget yang tidak memiliki child). Hubungan parent-child bekerja dengan prinsip komposisi: parent widget bertanggung jawab untuk merender child widget-nya dan mengontrol properti serta state yang diteruskan ke child melalui parameter constructor. Ketika ada perubahan pada state parent, Flutter akan merekonstruksi seluruh subtree dari widget tersebut dan child-nya untuk mencerminkan perubahan terbaru. Dalam proyek Kosinduy YNWA Shop, MyHomePage sebagai parent memiliki child berupa Scaffold, yang kemudian memiliki child AppBar dan body. Body berisi Padding, Column, Row, dan GridView yang secara hierarki membentuk struktur tampilan lengkap. ItemCard widget yang berada di dalam GridView merupakan child yang akan di-render berkali-kali sesuai dengan jumlah item dalam list.

## Sebutkan semua widget yang kamu gunakan dalam proyek ini dan jelaskan fungsinya.

Berikut adalah widget yang digunakan dalam proyek Kosinduy YNWA Shop beserta fungsinya. **MaterialApp** berfungsi sebagai widget root yang mengatur konfigurasi utama aplikasi termasuk tema, routing, dan title aplikasi. **Scaffold** menyediakan struktur dasar halaman dengan AppBar, body, dan mendukung floating action button jika diperlukan. **AppBar** menampilkan header atau judul aplikasi di bagian atas halaman dengan styling yang konsisten. **Text** menampilkan teks dengan berbagai styling seperti font, ukuran, warna, dan font weight sesuai kebutuhan. **Column** menyusun child widget secara vertikal dari atas ke bawah, memungkinkan layout yang teratur dalam arah vertikal. **Row** menyusun child widget secara horizontal dari kiri ke kanan, berguna untuk membuat layout samping-menyamping seperti InfoCard. **Padding** memberikan ruang kosong di sekitar child-nya dengan jarak yang dapat dikustomisasi. **SizedBox** memberikan ukuran tetap atau ruang kosong dengan dimensi spesifik, sering digunakan untuk spacing antar widget. **Center** menempatkan child widget di tengah-tengah parent-nya baik secara horizontal maupun vertikal. **Card** menampilkan konten dalam kartu dengan elevation dan shadow effect, digunakan untuk InfoCard agar lebih menonjol. **Container** adalah widget wrapper versatile yang memungkinkan styling, padding, decoration, dan sizing sekaligus. **GridView** menyusun child widget dalam bentuk grid dengan baris dan kolom yang dapat dikonfigurasi, digunakan untuk menampilkan tiga tombol menu dalam satu baris. **Material** memberikan material design properties seperti warna dan ripple effect pada widget yang dibungkusnya. **InkWell** menangkap user interaction (tap) dan menampilkan ripple effect saat disentuh, memberikan feedback visual yang baik. **Icon** menampilkan ikon dari material design library, digunakan untuk menampilkan icon shopping_bag, inventory, dan add_circle pada tombol menu.

## Apa fungsi dari widget MaterialApp? Jelaskan mengapa widget ini sering digunakan sebagai widget root.

MaterialApp adalah widget yang mengatur konfigurasi dan tema aplikasi secara global dengan standar Material Design. Fungsi utamanya adalah menyediakan Material Design theme dan styling yang konsisten di seluruh aplikasi, mengelola navigasi dan routing antar halaman melalui property home atau routes, mengatur title aplikasi yang ditampilkan di device switcher atau task manager, mengkonfigurasi locale dan bahasa aplikasi, serta menyediakan akses ke MediaQuery dan BuildContext untuk seluruh widget di bawahnya.

Widget ini sering digunakan sebagai widget root karena beberapa alasan penting. Pertama, MaterialApp adalah entry point dari aplikasi Flutter yang mengeksekusi seluruh widget tree, tanpanya aplikasi tidak akan berjalan. Kedua, dengan menjadi root, MaterialApp memastikan konfigurasi tema dan navigasi berlaku secara global ke seluruh aplikasi, sehingga konsistensi desain terjaga di setiap halaman. Ketiga, MaterialApp menyediakan context dan akses ke resource global seperti theme data yang dibutuhkan oleh widget di bawahnya untuk mengakses warna dan styling. Dalam proyek ini, MaterialApp mengonfigurasi color scheme dengan warna Liverpool Football Club (red dan gold), sehingga semua widget dapat mengakses warna ini melalui Theme.of(context).

## Jelaskan perbedaan antara StatelessWidget dan StatefulWidget. Kapan kamu memilih salah satunya?

Perbedaan utama antara StatelessWidget dan StatefulWidget terletak pada kemampuan mengelola state atau data yang dapat berubah. StatelessWidget adalah widget yang tidak memiliki state internal dan bersifat immutable atau tidak berubah, hanya menerima data dari parent melalui constructor dan menampilkannya. Ketika ingin memperbarui tampilan StatelessWidget, developer harus membuat instance baru dengan data yang berbeda. Sebaliknya, StatefulWidget adalah widget yang memiliki state internal yang dapat berubah dan dapat merespons perubahan tanpa membuat instance baru. StatefulWidget terdiri dari dua class: StatefulWidget dan State, di mana State menyimpan data yang dapat diubah serta memiliki method setState() untuk memicu rebuild ketika data berubah.

Dalam proyek Kosinduy YNWA Shop, MyHomePage, InfoCard, dan ItemCard menggunakan StatelessWidget karena data yang ditampilkan tidak berubah selama widget tersebut aktif. Data nama, npm, dan kelas bersifat statis dan tidak perlu diupdate, demikian juga dengan item menu yang selalu tetap. Kapan memilih masing-masing: gunakan StatelessWidget jika tampilan widget tidak berubah atau hanya bergantung pada data dari parent yang diteruskan melalui constructor. Gunakan StatefulWidget jika widget perlu mengelola state internal, merespons user input, atau memperbarui tampilan secara dinamis berdasarkan perubahan data tanpa tergantung pada parent widget. Sebagai contoh, jika di kemudian hari ingin menambahkan fitur filter atau sorting pada menu yang mengubah tampilan tanpa reload dari parent, maka MyHomePage sebaiknya diubah menjadi StatefulWidget.

## Apa itu BuildContext dan mengapa penting di Flutter? Bagaimana penggunaannya di metode build?

BuildContext adalah objek yang merepresentasikan lokasi widget dalam widget tree dan menyimpan informasi penting seperti parent widget, theme, media query, dan navigasi yang dapat diakses oleh widget. BuildContext sangat penting di Flutter karena memungkinkan widget mengakses informasi global dan melakukan operasi yang membutuhkan konteks aplikasi. Pertama, BuildContext memungkinkan widget mengakses tema global melalui Theme.of(context), seperti AppBar di proyek ini yang mengakses Theme.of(context).colorScheme.primary untuk mendapatkan warna merah Liverpool. Kedua, BuildContext memberikan akses ke ukuran layar dan informasi device melalui MediaQuery.of(context), digunakan pada InfoCard untuk menghitung lebar dengan MediaQuery.of(context).size.width / 3.5. Ketiga, BuildContext digunakan untuk navigasi antar halaman dengan Navigator.push() atau Navigator.pop(). Keempat, BuildContext diperlukan untuk menampilkan SnackBar atau dialog dengan ScaffoldMessenger.of(context), seperti pada ItemCard saat menampilkan pesan "Kamu telah menekan tombol...!".

Penggunaan BuildContext di metode build adalah dengan menggunakannya sebagai parameter yang diteruskan otomatis, kemudian developer bisa menggunakannya untuk mengakses informasi global atau melakukan navigasi. Contohnya pada ItemCard saat user mengetuk tombol, ScaffoldMessenger.of(context) digunakan untuk menampilkan SnackBar dengan pesan yang mengandung nama item yang ditekan, memastikan pesan yang ditampilkan relevan dengan item mana yang user sentuh.

## Jelaskan konsep "hot reload" di Flutter dan bagaimana bedanya dengan "hot restart".

Hot Reload adalah fitur Flutter yang memungkinkan developer membuat perubahan pada kode dan langsung melihat hasilnya tanpa restart aplikasi atau kehilangan state. Proses hot reload hanya meng-inject kode yang berubah ke Dart VM yang sedang berjalan, sehingga sangat cepat, biasanya kurang dari 1 detik. State aplikasi tetap dipertahankan, sehingga jika user sudah navigasi ke halaman detail atau mengisi form, state tersebut tidak akan hilang setelah hot reload. Hot reload sangat berguna untuk development karena developer bisa bereksperimen dengan UI atau logic, misalnya mengubah warna tombol atau mengganti teks greeting, tanpa khawatir kehilangan progress atau harus mengulangi langkah sebelumnya untuk mencapai halaman yang sedang dikerjakan.

Hot Restart adalah proses yang menghentikan seluruh aplikasi dan me-restart dari awal, namun tetap di dalam emulator atau device yang sama tanpa perlu rebuild APK lengkap. Berbeda dengan hot reload, hot restart akan mereset seluruh state aplikasi menjadi state awal seperti saat pertama kali app dijalankan. Hot restart diperlukan ketika hot reload tidak dapat menangani perubahan kode, misalnya ketika mengubah main() function, inisialisasi global variable, dependency yang complex, atau mengubah package yang diimport. 

Perbedaan signifikan antara keduanya adalah kecepatan di mana hot reload jauh lebih cepat daripada hot restart, serta penanganan state di mana hot reload mempertahankan state sedangkan hot restart mereset state. Untuk penggunaan, hot reload cocok digunakan untuk iterasi cepat selama development seperti styling dan fine-tuning UI, sedangkan hot restart digunakan untuk perubahan yang fundamental. Cara aktivasi juga berbeda: hot reload biasanya dengan shortcut `r` di terminal atau IDE, hot restart dengan shortcut `R`. Dalam pengembangan proyek Kosinduy YNWA Shop, hot reload sangat membantu ketika melakukan styling dengan mengubah warna Liverpool atau mengatur layout widget, sehingga hasilnya bisa dilihat langsung tanpa perlu rebuild aplikasi dari awal yang memakan waktu lebih lama.




# TUGAS 8 - Flutter Navigation, Layouts, Forms, and Input Elements

## Jelaskan perbedaan antara Navigator.push() dan Navigator.pushReplacement() pada Flutter. Dalam kasus apa sebaiknya masing-masing digunakan pada aplikasi Football Shop kamu?

Perbedaan utama antara Navigator.push() dan Navigator.pushReplacement() terletak pada cara mereka mengelola navigation stack. Navigator.push() menambahkan halaman baru ke atas stack navigasi yang sudah ada, sehingga user dapat kembali ke halaman sebelumnya dengan tombol back atau Navigator.pop(). Sebaliknya, Navigator.pushReplacement() menggantikan halaman saat ini dengan halaman baru di stack navigasi, sehingga halaman sebelumnya dihapus dari stack dan user tidak dapat kembali ke halaman tersebut menggunakan tombol back.

Dalam aplikasi Kosinduy YNWA, Navigator.push() digunakan ketika navigasi ke halaman form tambah produk (ProductFormPage) dari tombol "Create Product" pada halaman utama atau dari drawer. Hal ini memungkinkan user untuk kembali ke halaman utama setelah mengisi form atau jika ingin membatalkan proses penambahan produk. Navigator.pushReplacement() digunakan dalam drawer ketika user memilih "Home" atau "All Products", karena kita ingin menggantikan halaman saat ini dengan halaman utama tanpa menumpuk halaman yang sama di navigation stack. Penggunaan pushReplacement pada drawer mencegah terjadinya multiple instances dari halaman yang sama dan memberikan user experience yang lebih clean. Sebagai contoh, jika user berada di ProductFormPage dan memilih "Home" dari drawer, pushReplacement akan langsung mengganti form page dengan home page, bukan menambahkan home page di atas form page.

## Bagaimana kamu memanfaatkan hierarchy widget seperti Scaffold, AppBar, dan Drawer untuk membangun struktur halaman yang konsisten di seluruh aplikasi?

Hierarchy widget seperti Scaffold, AppBar, dan Drawer dimanfaatkan sebagai foundation untuk membangun struktur halaman yang konsisten di seluruh aplikasi Kosinduy YNWA Shop. Scaffold berfungsi sebagai kerangka utama setiap halaman yang menyediakan struktur dasar Material Design, termasuk slot untuk AppBar, body, drawer, dan floating action button. Dengan menggunakan Scaffold di setiap halaman (MyHomePage dan ProductFormPage), aplikasi memiliki struktur yang seragam dan predictable bagi user.

AppBar diimplementasikan secara konsisten dengan konfigurasi yang sama di seluruh halaman: menggunakan warna Liverpool red (Color(0xFFCE1126)) sebagai backgroundColor, teks putih dengan fontWeight bold untuk title, dan foregroundColor white untuk ikon. Hal ini menciptakan identitas visual yang kuat dan membantu user mengenali bahwa mereka masih berada dalam aplikasi yang sama. Drawer (LeftDrawer) diintegrasikan ke dalam setiap Scaffold untuk menyediakan navigasi yang konsisten dan mudah diakses dari mana saja dalam aplikasi. Drawer menggunakan DrawerHeader dengan branding Kosinduy YNWA dan warna tema yang sama, diikuti dengan ListTile yang menyediakan navigasi ke berbagai bagian aplikasi. Dengan menempatkan const LeftDrawer() di setiap Scaffold, user dapat mengakses menu navigasi yang sama terlepas dari halaman mana mereka berada, menciptakan pengalaman navigasi yang intuitif dan konsisten. Pendekatan ini juga memudahkan maintenance karena perubahan pada AppBar atau Drawer dapat dilakukan secara terpusat dan otomatis terefleksi di seluruh aplikasi.

## Dalam konteks desain antarmuka, apa kelebihan menggunakan layout widget seperti Padding, SingleChildScrollView, dan ListView saat menampilkan elemen-elemen form? Berikan contoh penggunaannya dari aplikasi kamu.

Layout widget seperti Padding, SingleChildScrollView, dan ListView memberikan kelebihan signifikan dalam menampilkan elemen-elemen form dengan cara yang user-friendly dan responsive. Padding memberikan kontrol presisi terhadap ruang kosong di sekitar widget, menciptakan breathing space yang membuat form tidak terlihat cramped dan lebih mudah dibaca. SingleChildScrollView memungkinkan form untuk discroll ketika kontennya melebihi tinggi layar, sangat penting untuk form panjang atau ketika keyboard muncul. ListView menyediakan scrolling yang efficient untuk daftar item yang panjang dengan lazy loading.

Dalam aplikasi Kosinduy YNWA, ketiga widget ini diimplementasikan secara strategis di ProductFormPage. Padding digunakan secara konsisten dengan EdgeInsets.all(8.0) untuk setiap field form (nama, harga, deskripsi, thumbnail, kategori, dan stock), memberikan spacing yang uniform dan menciptakan visual hierarchy yang jelas antara setiap elemen input. SingleChildScrollView membungkus seluruh Column yang berisi form fields, memungkinkan user untuk scroll ke atas dan bawah ketika form panjang atau ketika keyboard virtual muncul dan menyembunyikan sebagian form. Hal ini sangat penting untuk user experience karena semua field tetap dapat diakses terlepas dari ukuran layar device. Contoh implementasinya adalah Form widget yang dibungkus SingleChildScrollView, kemudian di dalamnya terdapat Column dengan children berupa Padding widgets yang masing-masing berisi TextFormField. Struktur ini memastikan bahwa form dapat digunakan dengan nyaman di berbagai ukuran layar dan orientasi, sambil tetap mempertahankan konsistensi visual melalui padding yang seragam.

## Bagaimana kamu menyesuaikan warna tema agar aplikasi Football Shop memiliki identitas visual yang konsisten dengan brand toko?

Penyesuaian warna tema untuk menciptakan identitas visual yang konsisten dengan brand Liverpool Football Club dilakukan melalui konfigurasi ColorScheme di MaterialApp dan penggunaan warna yang consistent di seluruh komponen aplikasi. Dalam main.dart, tema aplikasi dikonfigurasi dengan ColorScheme.fromSeed yang menggunakan seedColor Liverpool red (Color(0xFFCE1126)) sebagai warna utama, dengan primary color yang sama untuk memastikan konsistensi, dan secondary color menggunakan Liverpool gold (Color(0xFFFDB913)) untuk aksen. Surface color diset ke Colors.white untuk background yang clean, sementara onPrimary dan onSecondary color diatur untuk memastikan kontras text yang optimal.

Implementasi tema ini kemudian diterapkan secara konsisten di seluruh aplikasi melalui Theme.of(context). AppBar di setiap halaman menggunakan Theme.of(context).colorScheme.primary untuk backgroundColor, memastikan semua header memiliki warna Liverpool red yang signature. DrawerHeader juga menggunakan warna yang sama (Color(0xFFCE1126)) untuk menciptakan kontinuitas visual. Untuk komponen form di ProductFormPage, ElevatedButton menggunakan MaterialStateProperty.all(Color(0xFFCE1126)) untuk mempertahankan konsistensi warna brand. Tombol-tombol pada halaman utama (ItemCard) menggunakan warna individual yang kontras namun tetap harmonis: biru untuk "All Products", hijau untuk "My Products", dan merah untuk "Create Product", memberikan visual distinction sambil tetap mempertahankan professional appearance. Pendekatan ini memastikan bahwa identity Liverpool Football Club terefleksi dengan kuat melalui penggunaan warna signature merah di elemen-elemen kunci seperti AppBar, drawer, dan action buttons, dengan tetap mempertahankan user experience dengan kontras warna yang baik dan hierarchy visual yang jelas.