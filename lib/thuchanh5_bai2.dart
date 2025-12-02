import 'package:flutter/material.dart';

// --- 1. DATA MODEL & MOCK DATA ---

class Recipe {
  final String name;
  final String imageUrl;
  final String description;
  final List<String> ingredients;
  final List<String> steps;

  Recipe({
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.steps,
  });
}

// Danh sách dữ liệu mẫu
final List<Recipe> recipes = [
  Recipe(
    name: 'Phở Bò',
    // Đây là ảnh Offline (trong máy)
    imageUrl: 'assets/pho.jpg',
    description: 'Món ăn quốc hồn quốc túy của Việt Nam với nước dùng đậm đà.',
    ingredients: [
      '500g Bánh phở',
      '300g Thịt bò thăn',
      'Xương bò hầm nước dùng',
      'Hành tây, hành tím, gừng',
      'Gia vị: Quế, hồi, thảo quả',
      'Rau sống: Húng quế, ngò gai'
    ],
    steps: [
      'Bước 1: Hầm xương bò khoảng 6-8 tiếng để lấy nước ngọt.',
      'Bước 2: Nướng hành tây, hành tím, gừng cho thơm rồi thả vào nồi nước dùng cùng gói gia vị.',
      'Bước 3: Thái thịt bò mỏng.',
      'Bước 4: Chần bánh phở qua nước sôi rồi cho vào bát.',
      'Bước 5: Xếp thịt bò lên trên, chan nước dùng sôi sùng sục vào để làm chín thịt tái.',
      'Bước 6: Thêm rau thơm và thưởng thức.'
    ],
  ),
  Recipe(
    name: 'Bánh Mì Kẹp',
    // Đây là ảnh Online
    imageUrl: 'assets/banhmi.jpg',
    description: 'Bánh mì giòn rụm kẹp thịt, pate và rau dưa chua ngọt.',
    ingredients: [
      '2 ổ Bánh mì',
      '100g Pate gan',
      '100g Thịt nguội hoặc chả lụa',
      'Dưa leo, ngò rí, ớt',
      'Đồ chua (cà rốt, củ cải trắng)',
      'Bơ, nước tương'
    ],
    steps: [
      'Bước 1: Nướng lại bánh mì cho nóng giòn.',
      'Bước 2: Xẻ dọc ổ bánh mì, phết bơ và pate vào hai mặt trong.',
      'Bước 3: Xếp lần lượt dưa leo, thịt nguội/chả lụa vào.',
      'Bước 4: Thêm đồ chua, ngò rí và vài lát ớt.',
      'Bước 5: Xịt thêm xì dầu hoặc nước sốt tùy thích.'
    ],
  ),
  Recipe(
    name: 'Cà Phê Trứng',
    // Đây là ảnh Online
    imageUrl: 'assets/caphe.jpg',
    description: 'Đồ uống đặc sản Hà Nội với vị béo ngậy của trứng và thơm đắng của cà phê.',
    ingredients: [
      '2 lòng đỏ trứng gà',
      '20g đường hoặc sữa đặc',
      '1 phin cà phê đen nóng',
      'Một chút mật ong (tùy chọn)'
    ],
    steps: [
      'Bước 1: Pha cà phê phin lấy nước cốt đậm đặc.',
      'Bước 2: Cho lòng đỏ trứng, sữa đặc và mật ong vào bát.',
      'Bước 3: Dùng máy đánh trứng đánh bông hỗn hợp cho đến khi thành kem mịn, màu vàng nhạt.',
      'Bước 4: Đổ cà phê nóng vào cốc, sau đó nhẹ nhàng đổ lớp kem trứng lên trên.',
      'Bước 5: Thưởng thức ngay khi còn nóng.'
    ],
  ),
];

// --- 2. HÀM HỖ TRỢ HIỂN THỊ ẢNH (QUAN TRỌNG) ---
// Hàm này kiểm tra link để quyết định dùng Image.network hay Image.asset
Widget buildRecipeImage(String imagePath, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (imagePath.startsWith('http')) {
    // Nếu link bắt đầu bằng http -> Dùng ảnh mạng
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
    );
  } else {
    // Ngược lại -> Dùng ảnh trong máy (Assets)
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          Container(width: width, height: height, color: Colors.grey[300], child: const Icon(Icons.image_not_supported)),
    );
  }
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Công thức Nấu ăn',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const RecipeListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- 4. HOME SCREEN ---

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Công thức Nấu ăn",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return RecipeItemWidget(recipe: recipes[index]);
        },
      ),
    );
  }
}

// --- 5. ITEM WIDGET ---

class RecipeItemWidget extends StatelessWidget {
  final Recipe recipe;

  const RecipeItemWidget({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              // Hình ảnh nhỏ (Đã sửa dùng hàm buildRecipeImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: buildRecipeImage(
                  recipe.imageUrl,
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recipe.description,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 6. DETAIL SCREEN ---

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh lớn (Đã sửa dùng hàm buildRecipeImage)
            SizedBox(
              width: double.infinity,
              height: 250,
              child: buildRecipeImage(recipe.imageUrl),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const Divider(height: 30, thickness: 1),

                  const Text(
                    "Nguyên Liệu:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.map((ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ingredient, style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      )),

                  const SizedBox(height: 20),

                  const Text(
                    "Cách Làm:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: recipe.steps.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.orange[50],
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            recipe.steps[index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}