

import 'package:farmplanning/global.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'dart:html' as html; // ملاحظة: هذا الكود سيعمل فقط على الويب

class ReportTableScreen extends StatefulWidget {
  const ReportTableScreen({super.key});

  @override
  State<ReportTableScreen> createState() => _ReportTableScreenState();
}

class _ReportTableScreenState extends State<ReportTableScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _filteredData = [];
  bool _isLoading = true;

  // Controllers and filter variables
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  String? _selectedArea;
  String? _selectedSector;
  String? _selectedReservoir;
  String? _selectedproccess;

  List<String> _areas = [];
  List<String> _sectors = [];
  List<String> _reservoirs = [];
  List<String> _proccess = [];

  @override
  void initState() {
    super.initState();
    _initialLoad();
    _fetchProccess();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  /// Performs the initial data load for both filters and table data concurrently.
  Future<void> _initialLoad() async {
    setState(() => _isLoading = true);
    try {
      // Fetch initial dropdown data and table data in parallel to speed up loading
      await Future.wait([
        _fetchData(),
        _fetchAreas(),
      ]);
    } catch (e) {
      // Handle any potential errors during initial load
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل البيانات الأولية: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Fetches data from the Supabase view based on the current filters.
  Future<void> _fetchData() async {
    try {
      var query = supabase.from('data_table_full_view2').select().gte('date_from', _fromDateController.text).lte('date_from', _toDateController.text).eq('user_id', user_id);

      // Apply date filters only if they are not empty
      // if (_fromDateController.text.isNotEmpty) {
      //   query = query.gte('date_from', _fromDateController.text);
      // }
      // if (_toDateController.text.isNotEmpty) {
      //   query = query.lte('date_from', _toDateController.text);
      // }

      // Apply dropdown filters
      if (_selectedArea != null) {
        query = query.eq('area', _selectedArea!);
      }
      if (_selectedSector != null) {
        query = query.eq('sector', _selectedSector!);
      }
      if (_selectedReservoir != null) {
        query = query.eq('reservoir', _selectedReservoir!);
      }
      if (_selectedproccess != null) {
        query = query.eq('process_name', _selectedproccess!);
      }

      final response = await query.order('date_from', ascending: false);

      if (mounted) {
        setState(() {
          _filteredData = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب البيانات: $e')),
        );
      }
    }
  }

  /// Fetches the list of areas for the filter dropdown.
  Future<void> _fetchAreas() async {
    final result = await supabase
        .from('farm')
        .select('area')
        .neq('area', '')
        .order('area', ascending: true);
    if (mounted) {
      setState(() {
        _areas = result.map<String>((e) => e['area'] as String).toSet().toList();
      });
    }
  }

  /// Fetches the list of sectors based on the selected area.
  Future<void> _fetchSectors(String area) async {
    final result = await supabase
        .from('farm')
        .select('sector')
        .eq('area', area)
        .neq('sector', '')
        .order('sector');
    if (mounted) {
      setState(() {
        _sectors =
            result.map<String>((e) => e['sector'] as String).toSet().toList();
      });
    }
  }

  /// Fetches the list of reservoirs based on the selected sector.
  Future<void> _fetchReservoirs(String sector) async {
    final result = await supabase
        .from('farm')
        .select('reservoir')
        .eq('sector', sector)
        .neq('reservoir', '')
        .order('reservoir');
    if (mounted) {
      setState(() {
        _reservoirs = result
            .map<String>((e) => e['reservoir'] as String)
            .toSet()
            .toList();
      });
    }
  }
  Future<void> _fetchProccess() async {
    final result = await supabase
        .from('process')
        .select('process_name')
       
        .neq('process_name', '')
        .order('process_name');
    if (mounted) {
      setState(() {
        _proccess = result
            .map<String>((e) => e['process_name'] as String)
            .toSet()
            .toList();
      });
    }
  }

  /// Applies all selected filters and refreshes the data table.
  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    try {
      await _fetchData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Clears all filters and reloads the data.
  void _clearFilters() {
    setState(() {
      _fromDateController.clear();
      _toDateController.clear();
      _selectedArea = null;
      _selectedSector = null;
      _selectedReservoir = null;
      _selectedproccess = null;
    
      _sectors = [];
      _reservoirs = [];
    });
    // Reload data after clearing filters
    _applyFilters();
  }

  /// Exports the currently filtered data to an Excel file.
  void _exportToExcel() {
    if (_filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات لتصديرها.')),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    // Add header row
    final headers = [
        'التاريخ', 'المزرعه', 'الصنف', 'الوحدة', 'العملية', 'الكمية',
        'انتظار', 'تحت التشغيل', 'انتهى', 'ملغي', 'السبب', 'عمالة خارجية',
        'الكمية الفعلية', 'ملاحظات', 'تقييم المهندس', 'سبب تقييم المهندس',
        'تقييم القطاع', 'سبب تقييم القطاع', 'تقييم المنطقة',
        'سبب تقييم المنطقة', 'تقييم المتابعة', 'سبب تقييم المتابعة'
    ].map((header) => TextCellValue(header)).toList();
    sheet.appendRow(headers);

    // Add data rows
    for (var row in _filteredData) {
      // Helper to safely get string values from map
      String R(String key) => row[key]?.toString() ?? '';

      sheet.appendRow([
        TextCellValue(R('date_from')), TextCellValue(R('farm_code')),
        TextCellValue(R('items')), TextCellValue(R('unit')),
        TextCellValue(R('process_name')), TextCellValue(R('qty')),
        TextCellValue(R('pending')), TextCellValue(R('under_progress')),
        TextCellValue(R('finished')), TextCellValue(R('cancel')),
        TextCellValue(R('cancel_reason')), TextCellValue(R('out_source')),
        TextCellValue(R('actual_qty')), TextCellValue(R('note')),
        TextCellValue(R('user_kpi')), TextCellValue(R('user_kpi_reason')),
        TextCellValue(R('sector_kpi')), TextCellValue(R('sector_kpi_reason')),
        TextCellValue(R('area_kpi')), TextCellValue(R('area_kpi_reason')),
        TextCellValue(R('quality_kpi')), TextCellValue(R('quality_kpi_reason')),
      ]);
    }

    // Save the file (Web-specific)
    try {
      final bytes = excel.encode();
      if (bytes != null) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch(e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير الملف: $e')),
      );
    }
  }

  /// Date picker utility.
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تقرير العمليات')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Filter controls
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_download_outlined),
                    onPressed: _exportToExcel,
                    label: const Text('تصدير إلى Excel'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    onPressed: _applyFilters,
                    label: const Text('تطبيق الفلاتر'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
                    onPressed: _clearFilters,
                    label: const Text('مسح الفلاتر', style: TextStyle(color: Colors.red),),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _fromDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'من تاريخ',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _fromDateController),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _toDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'إلى تاريخ',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _toDateController),
                    ),
                  ),
                  DropdownButton<String>(
                    hint: const Text('اختر المنطقة'),
                    value: _selectedArea,
                    items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedArea = val;
                        _selectedSector = null;
                        _selectedReservoir = null;
                        _sectors.clear();
                        _reservoirs.clear();
                        _fetchSectors(val);
                      });
                    },
                  ),
                  DropdownButton<String>(
                    hint: const Text('اختر القطاع'),
                    value: _selectedSector,
                    items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedSector = val;
                        _selectedReservoir = null;
                        _reservoirs.clear();
                        _fetchReservoirs(val);
                      });
                    },
                  ),
                  DropdownButton<String>(
                    hint: const Text('اختر الجهيرة'),
                    value: _selectedReservoir,
                    items: _reservoirs.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      setState(() {
                      _selectedReservoir = val;
                    });
                    },
                  ),
                  DropdownButton<String>(
                    hint: const Text('اختر العملية'),
                    value: _selectedproccess,
                    items: _proccess.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedproccess = val;
                        });
                    },
                  ),
               
                ],
              ),
              const SizedBox(height: 15),
              // Data table area
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
                            columns: const [
                               'التاريخ', 'المزرعه', 'الصنف', 'الوحدة', 'العملية', 'الكمية',
                               'انتظار', 'تحت التشغيل', 'انتهى', 'ملغي', 'السبب', 'عمالة خارجية',
                               'الكمية الفعلية', 'ملاحظات', 'تقييم المهندس', 'سبب تقييم المهندس',
                               'تقييم القطاع', 'سبب تقييم القطاع', 'تقييم المنطقة',
                               'سبب تقييم المنطقة', 'تقييم المتابعة', 'سبب تقييم المتابعة'
                            ].map((c) => DataColumn(label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold),))).toList(),
                            rows: _filteredData.map((row) {
                              String R(String key) => row[key]?.toString() ?? '';
                              return DataRow(
                                cells: [
                                  DataCell(Text(R('date_from'))), DataCell(Text(R('farm_code'))),
                                  DataCell(Text(R('items'))), DataCell(Text(R('unit'))),
                                  DataCell(Text(R('process_name'))), DataCell(Text(R('qty'))),
                                  DataCell(Text(R('pending'))), DataCell(Text(R('under_progress'))),
                                  DataCell(Text(R('finished'))), DataCell(Text(R('cancel'))),
                                  DataCell(Text(R('cancel_reason'))), DataCell(Text(R('out_source'))),
                                  DataCell(Text(R('actual_qty'))), DataCell(Text(R('note'))),
                                  DataCell(Text(R('user_kpi'))), DataCell(Text(R('user_kpi_reason'))),
                                  DataCell(Text(R('sector_kpi'))), DataCell(Text(R('sector_kpi_reason'))),
                                  DataCell(Text(R('area_kpi'))), DataCell(Text(R('area_kpi_reason'))),
                                  DataCell(Text(R('quality_kpi'))), DataCell(Text(R('quality_kpi_reason'))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}