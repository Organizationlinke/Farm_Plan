import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubProcessScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String processName;

  const SubProcessScreen({
    super.key,
    required this.selectedDate,
    required this.processName,
  });

  @override
  State<SubProcessScreen> createState() => _SubProcessScreenState();
}

class _SubProcessScreenState extends State<SubProcessScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final response = await supabase
        .from('data_table_full_view2')
        .select()
        .eq('process_name', widget.processName).
        like('farm_code', '$New_user_area%')
        .gte('date_to', widget.selectedDate.toIso8601String())
        .lte('date_from', widget.selectedDate.toIso8601String());

    return response as List<Map<String, dynamic>>;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubProcessScreen(
              selectedDate: picked,
              processName: widget.processName,
            ),
          ),
        );
      });
    }
  }

  // عشان نحفظ حالة كل عنصر في القائمة
  final Map<int, String?> _itemStatuses = {};

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
         
          title: GestureDetector(
            onTap: () => _selectDate(context),
            child: Text(
              '${widget.processName} : ${widget.selectedDate.toLocal().toString().split(' ')[0]}',
            ),
          ),
        ),
        body: FutureBuilder(
          future: fetchItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data as List<Map<String, dynamic>>;

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                _itemStatuses.putIfAbsent(index, () => null); // تأكد أنه كل عنصر له حالة

                return Card(
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['items']} : ${item['qty']} ${item['unit']}',style: TextStyle(color: const Color.fromARGB(255, 23, 1, 119))),
                        Text(item['shoet_farm_code'],style: TextStyle(fontSize: 12,color: const Color.fromARGB(255, 0, 108, 197)),),
                      ],
                    ),
                    
                    subtitle: Column(
                      children: [
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                           
                            Row(
                              children: [
                                const Text('تحت التشغيل'),
                                 Radio<String>(
                              activeColor: Colors.amber,
                              value: 'under_progress',
                              groupValue: _itemStatuses[index],
                              onChanged: (value) {
                                setState(() {
                                  _itemStatuses[index] = value;
                                });
                              },
                            ),
                              ],
                            ),
                           
                       
                            Row(
                              children: [
                                const Text('منتهي'),
                                 Radio<String>(
                                  activeColor: const Color.fromARGB(255, 2, 209, 9),
                              value: 'finished',
                              groupValue: _itemStatuses[index],
                              onChanged: (value) {
                                setState(() {
                                  _itemStatuses[index] = value;
                                });
                              },
                            ),
                              ],
                              
                            ),
                           
                            Row(
                              children: [
                                const Text('ملغي'),
                                 Radio<String>(
                              activeColor: Colors.red,
                              value: 'cancel',
                              groupValue: _itemStatuses[index],
                              onChanged: (value) {
                                setState(() {
                                  _itemStatuses[index] = value;
                                });
                              },
                            ),
                              ],
                            ),
                            
                           
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class SubProcessScreen extends StatefulWidget {
//   final DateTime selectedDate;
//   final String processName;

//   const SubProcessScreen({
//     super.key,
//     required this.selectedDate,
//     required this.processName,
//   });

//   @override
//   State<SubProcessScreen> createState() => _SubProcessScreenState();
// }

// class _SubProcessScreenState extends State<SubProcessScreen> {
//   final supabase = Supabase.instance.client;

//   Future<List<Map<String, dynamic>>> fetchItems() async {
//     final response = await supabase
//         .from('data_table_full_view')
//         .select()
//         .eq('process_name', widget.processName)
//         .gte('date_to', widget.selectedDate.toIso8601String())
//         .lte('date_from', widget.selectedDate.toIso8601String());

//     return response as List<Map<String, dynamic>>;
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: widget.selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );

//     if (picked != null) {
//       setState(() {
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => SubProcessScreen(
//               selectedDate: picked,
//               processName: widget.processName,
//             ),
//           ),
//         );
//       });
//     }
//   }

//   String? selectedStatus;

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: GestureDetector(
//             onTap: () => _selectDate(context),
//             child: Text(
//               'التاريخ: ${widget.selectedDate.toLocal().toString().split(' ')[0]}',
//             ),
//           ),
//         ),
//         body: FutureBuilder(
//           future: fetchItems(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return const Center(child: CircularProgressIndicator());
//             }
      
//             final items = snapshot.data as List<Map<String, dynamic>>;
      
//             return ListView.builder(
//               itemCount: items.length,
//               itemBuilder: (context, index) {
//                 final item = items[index];
      
//                 return Card(
//                   child: ListTile(
//                     title: Text('${item['items']} ${item['qty']} ${item['unit']}'),
//                     // subtitle: Text('الكمية: ${item['qty']} ${item['unit']} '),
//                     subtitle: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Text('انتظار'),
//                             Radio(
//                               value: 'pending',
//                               groupValue: selectedStatus,
//                               onChanged: (value) {
//                                 setState(() {
//                                   selectedStatus = value as String?;
//                                 });
//                               },
//                             ),
//                              Text('تحت التشغيل'),
//                             Radio(
//                               value: 'under_progress',
//                               groupValue: selectedStatus,
//                               onChanged: (value) {
//                                 setState(() {
//                                   selectedStatus = value as String?;
//                                 });
//                               },
//                             ),
                         
//                           ],
//                         ),
//                          Row(
//                           children: [
                           
//                              Text('منتهي'),
//                             Radio(
//                               value: 'finished',
//                               groupValue: selectedStatus,
//                               onChanged: (value) {
//                                 setState(() {
//                                   selectedStatus = value as String?;
//                                 });
//                               },
//                             ),
//                              Text('ملغي'),
//                             Radio(
//                               value: 'cancel',
//                               groupValue: selectedStatus,
//                               onChanged: (value) {
//                                 setState(() {
//                                   selectedStatus = value as String?;
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
