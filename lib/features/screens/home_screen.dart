import 'package:flutter/material.dart';
import 'package:lao_trust/services/firebase_service.dart';

/// 홈 화면: 3단계(메인 카테고리 → 세부 종목 → 증상 선택) + 급구 알바 카드
enum HomeView { main, subCategory, symptoms }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  HomeView _currentView = HomeView.main;
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  int _currentPage = 0;

  final List<String> _selectedSymptoms = [];
  final TextEditingController _etcController = TextEditingController();

  final Map<String, List<String>> _symptomData = {
    '에어컨': ['찬바람 안 나옴', '소음 발생', '물 새는 소리', '시원하지 않음', '기타'],
    '가전': ['전원 불량', '이상 소음', '작동 멈춤', '부품 파손', '기타'],
    '전기': ['차단기 내려감', '콘센트 탄 냄새', '조명 깜빡임', '누전 의심', '기타'],
    '배관': ['수도꼭지 누수', '하수구 막힘', '변기 역류', '수압 약함', '기타'],
  };

  @override
  void dispose() {
    _pageController.dispose();
    _etcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: PopScope(
        canPop: _currentView == HomeView.main,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _goBack();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentBody(),
        ),
      ),
    );
  }

  void _goBack() {
    setState(() {
      if (_currentView == HomeView.symptoms) {
        _currentView = HomeView.subCategory;
      } else if (_currentView == HomeView.subCategory) {
        _currentView = HomeView.main;
      }
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: _currentView != HomeView.main
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: _goBack,
            )
          : null,
      title: Text(
        _currentView == HomeView.main ? 'LAO TRUST 🛡️' : _selectedCategory,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A8A),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCurrentBody() {
    switch (_currentView) {
      case HomeView.main:
        return _buildMainContent();
      case HomeView.subCategory:
        return _buildSubCategoryContent();
      case HomeView.symptoms:
        return _buildSymptomContent();
    }
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      key: const ValueKey('main'),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildCategoryGrid(),
          const SizedBox(height: 40),
          _buildQuickJobSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<Map<String, dynamic>> services = [
      {'name': '청소', 'icon': Icons.cleaning_services, 'color': Colors.cyan},
      {'name': '경비', 'icon': Icons.shield, 'color': const Color(0xFF1E3A8A)},
      {'name': '수리', 'icon': Icons.build, 'color': Colors.orange},
      {'name': '배달', 'icon': Icons.delivery_dining, 'color': Colors.green},
      {'name': '뷰티', 'icon': Icons.face, 'color': Colors.pinkAccent},
      {'name': '과외', 'icon': Icons.menu_book, 'color': Colors.purple},
      {'name': '사진', 'icon': Icons.camera_alt, 'color': Colors.amber},
      {'name': '이벤트', 'icon': Icons.celebration, 'color': Colors.indigo},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전문가 서비스',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.85,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
              final Color color = s['color'] as Color;
              return InkWell(
                onTap: () {
                  if (s['name'] == '수리') {
                    setState(() {
                      _selectedCategory = '수리';
                      _currentView = HomeView.subCategory;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(s['icon'] as IconData, color: color, size: 30),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s['name'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryContent() {
    final subItems = [
      {'name': '에어컨', 'icon': Icons.ac_unit},
      {'name': '가전', 'icon': Icons.settings},
      {'name': '전기', 'icon': Icons.electric_bolt},
      {'name': '배관', 'icon': Icons.plumbing},
    ];

    return Padding(
      key: const ValueKey('sub'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '세부 종목 선택',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.2,
            ),
            itemCount: subItems.length,
            itemBuilder: (context, index) {
              final item = subItems[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubCategory = item['name'] as String;
                    _currentView = HomeView.symptoms;
                    _selectedSymptoms.clear();
                    _etcController.clear();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'] as IconData,
                          color: const Color(0xFF1E3A8A), size: 35),
                      const SizedBox(height: 10),
                      Text(
                        item['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomContent() {
    final symptoms = _symptomData[_selectedSubCategory] ?? ['기타'];

    return SingleChildScrollView(
      key: const ValueKey('symptoms'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Step 1 / 3',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const LinearProgressIndicator(
                    value: 0.33,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            '$_selectedSubCategory에 어떤 증상이 있나요?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            '해당하는 항목을 모두 선택해 주세요.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 25),
          ...symptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CheckboxListTile(
                title: Text(
                  symptom,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                value: isSelected,
                activeColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedSymptoms.add(symptom);
                    } else {
                      _selectedSymptoms.remove(symptom);
                    }
                  });
                },
              ),
            );
          }),
          if (_selectedSymptoms.contains('기타'))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: _etcController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '상세 증상을 자유롭게 적어주세요.',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _selectedSymptoms.isNotEmpty ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                '다음 단계로',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickJobSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '급구 알바',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 15),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firebaseService.getQuickJobs(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final jobs = snapshot.data!;
            if (jobs.isEmpty) {
              return const SizedBox(
                height: 180,
                child: Center(child: Text('현재 급구 알바가 없습니다.')),
              );
            }
            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return AnimatedScale(
                        scale: _currentPage == index ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['tag'] ?? '신규',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                job['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${job['loc'] ?? ''} | 일급 협의',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    jobs.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
