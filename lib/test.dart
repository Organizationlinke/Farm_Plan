import 'package:flutter/material.dart';

class AreaSelectionScreen extends StatefulWidget {
  const AreaSelectionScreen({super.key});

  @override
  State<AreaSelectionScreen> createState() => _AreaSelectionScreenState();
}

class _AreaSelectionScreenState extends State<AreaSelectionScreen> {
  final List<String> areas = []; // نتائج الاستعلام من قاعدة البيانات
  final List<String> selectedAreas = []; // العناصر اللي هيتم عرضها في row2

  @override
  void initState() {
    super.initState();
    fetchAreas();
  }

  Future<void> fetchAreas() async {
    // هنا استبدل هذه بالاستعلام الحقيقي
    final result = [
      'منطقة 1',
      'منطقة 2',
      'منطقة 3',
      'منطقة 4',
    ];
    setState(() {
      areas.addAll(result);
    });
  }

  void selectArea(String area) {
    if (!selectedAreas.contains(area)) {
      setState(() {
        selectedAreas.add(area);
      });
    }
  }

  void removeArea(String area) {
    setState(() {
      selectedAreas.remove(area);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار المناطق')),
      body: 
      Column(
        children: [
          const SizedBox(height: 10),
          // Row 1 - قائمة العناصر
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: areas.map((area) {
                return GestureDetector(
                  onTap: () => selectArea(area),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      area,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Row 2 - العناصر اللي تم اختيارها
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: selectedAreas.map((area) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        area,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => removeArea(area),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
