import 'package:flutter/material.dart';
import 'login.dart';

const Color primaryBlue = Color(0xFF433BFF); // Biru yang digunakan di Halaman 1
const Color darkBlue = Color(0xFF282399); // Biru gelap untuk Halaman 2
const Color accentRed = Color(0xFFFF4136); // Merah untuk tombol

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Mengubah List<Widget> menjadi List<Map> untuk passing data
  final List<Map<String, dynamic>> _pagesData = [
    {
      'isSplash': true,
      'imagePath': 'assets/images/logo_triathlon.png',
      'title': 'TRIATHLON',
    },
    {
      'isSplash': false,
      'imagePath': 'assets/images/onboarding_bg.png',
      'title': 'Welcome, Champion!',
      'subtitle': '"We Achieve, We Persevere, We Triumph."',
      'description': "Platform kami menyediakan semua yang Anda butuhkan untuk memulai, berkembang, dan bersaing dalam dunia triatlon.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!.round(); 
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk navigasi ke halaman berikutnya
  void _goToNextPage() {
    if (_currentPage < _pagesData.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  // Fungsi untuk navigasi ke Login Page
  void _goToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _pagesData.length - 1;

    return Scaffold(
      backgroundColor: primaryBlue,
      body: Stack(
        children: [
          // Konten Halaman: PageView dibungkus GestureDetector
          GestureDetector(
            // Tap hanya berfungsi jika BUKAN halaman terakhir
            onTap: isLastPage ? null : _goToNextPage,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pagesData.length,
              itemBuilder: (context, index) {
                // IntroPage menerima Map data
                return IntroPage(data: _pagesData[index]);
              },
            ),
          ),
          
          // Indikator Halaman (Dots)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Sesuaikan padding (lebih tinggi jika tombol muncul)
              padding: EdgeInsets.only(bottom: isLastPage ? 105.0 : 80.0), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pagesData.length, (index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double selectedness = (_pageController.hasClients && _pageController.page != null)
                          ? Curves.easeOut.transform(
                              (1.0 - (_pageController.page! - index).abs()).clamp(0.0, 1.0),
                            )
                          : (index == 0 ? 1.0 : 0.0);
                          
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 4.0,
                        width: 10.0 + (selectedness * 30.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.0), 
                          color: Colors.white,
                        ),
                        // Kontrol opacity berdasarkan selectedness (agar terlihat di halaman 2 yang gelap)
                        foregroundDecoration: BoxDecoration(
                           color: index == _currentPage
                              ? Colors.white
                              : Colors.white,
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
          
          // Tombol "Join The Challenge"
          if (isLastPage)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed, // Merah
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: _goToLoginPage, // Langsung ke Login Page
                    child: const Text(
                      'Join The Challenge', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Widget untuk setiap halaman Onboarding yang Disesuaikan

class IntroPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const IntroPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data['isSplash']) {
      // Tampilan Halaman 1 (Splash Screen)
      return Container(
        color: primaryBlue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                data['imagePath'],
                height: 150, 
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                data['title'],
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      );
    } else {
      // Tampilan Halaman 2 (Intro dengan Gambar & Konten)
      return Column(
        children: [
          // Bagian atas: Gambar Full Width
          Expanded(
            flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                  ),
                  gradient: LinearGradient(
                    colors: [primaryBlue, darkBlue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  image: DecorationImage(
                    image: AssetImage(data['imagePath']),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    opacity: 0.7, 
                  ),
                ),
              ),
          ),
          
          // Bagian bawah: Konten Teks
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, darkBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    data['title'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    data['subtitle'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    data['description'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}