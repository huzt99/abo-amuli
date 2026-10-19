import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({Key? key}) : super(key: key);

  @override
  _PosScreenState createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // قائمة تجريبية للعناصر المضافة في السلة
  final List<Map<String, dynamic>> cartItems = [
    {
      'code': '1/1/0001',
      'name': 'مادة بدون باركود',
      'qty': 1,
      'buy_price': 0,
      'sale_price': 0,
      'total': 0,
    }
  ];

  // التصنيفات الوهمية في أعلى لوحة اللمس
  final List<String> categories = [
    'المفضلة',
    'البقوليات',
    'الكرزات',
    'زيت ماء',
    'طحين + قمر الدين',
    'الطرشي',
    'اسماك + دجاج',
    'الطاحونة',
    'شاي',
    'الرصيد'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // ==========================================
          // القسم الأيسر: سلة المبيعات، الفاتورة، وأزرار التحكم
          // ==========================================
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // شريط معلومات الزبون والمخزن العلوي
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: const Color(0xFFE2E8F0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.store, size: 20),
                            SizedBox(width: 8),
                            Text('مخزن 1', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text('زبون نقدي', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // جدول أو قائمة المواد المضافة للفاتورة
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: ListTile(
                            leading: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  cartItems.removeAt(index);
                                });
                              },
                            ),
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('العدد: ${item['qty']} | سعر البيع: ${item['sale_price']}'),
                            trailing: Text('${item['total']} دينار', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                        );
                      },
                    ),
                  ),

                  // شريط إجمالي الفاتورة والرصيد السابق
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF0F172A),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('مجموع القائمة', style: TextStyle(color: Colors.white, fontSize: 16)),
                            Text('0 دينار', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // أزرار التحكم السفلية (إلغاء، طباعة، طريقة دفع، إرجاع بيع، بيع)
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        _buildBottomActionButton('إلغاء', const Color(0xFFEF4444), () {}),
                        _buildBottomActionButton('طباعة', const Color(0xFF475569), () {}),
                        _buildBottomActionButton('طريقة دفع', const Color(0xFF0284C7), () {}),
                        _buildBottomActionButton('إرجاع بيع', const Color(0xFF3B82F6), () {}),
                        _buildBottomActionButton('بيع', const Color(0xFF2563EB), () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // القسم الأيمن: التصنيفات وأزرار المواد السريعة (اللمس)
          // ==========================================
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // شريط الفئات الأفقي العلوي
                Container(
                  height: 55,
                  color: const Color(0xFF1E293B),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: index == 0 ? Colors.redAccent : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // شبكة أزرار المواد السريعة باللمس
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        return Card(
                          color: const Color(0xFF1E293B),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: InkWell(
                            onTap: () {},
                            child: Center(
                              child: Text(
                                'مادة رقم ${index + 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton(String title, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
