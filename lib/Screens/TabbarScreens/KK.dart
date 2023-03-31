import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_pro/Components/Functions.dart';
import 'package:google_maps_pro/Components/WorkerPathList.dart';
import 'package:google_maps_pro/Controller/LocationDataController.dart';
import 'package:intl/intl.dart';

import '../../Components/CustomColors.dart';

class Kk extends StatefulWidget {
  final DateTime date;
  const Kk({
    super.key,
    required this.date,
  });

  @override
  State<Kk> createState() => _KkState();
}

class _KkState extends State<Kk> {
  // final locDataController = Get.put(LocationDataController());
  final locDataController = Get.put(LocationDataController());
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      locDataController.getLocData(64706, '1', 1, widget.date);
    });
  }

  DateTime _selectedDate = DateTime.now();
  bool isDateSubmitted = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2015),
        lastDate: DateTime(2101),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: CustomColors.MAIN_BLUE, // <-- SEE HERE
                onPrimary: Colors.white,
                onSurface: CustomColors.MAIN_BLUE, // <-- SEE HERE
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: CustomColors.MAIN_BLUE, // button text color
                ),
              ),
            ),
            child: child!,
          );
        });
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        isDateSubmitted = true;
      });
      print('jjjjjjjj $_selectedDate');
      print('wwwwww ${DateTime.now()}');
      // locDataController.getLocData(64706, '1', 1, _selectedDate);
      locDataController.getLocData(
        64706,
        '1',
        1,
        DateFormat('yyyy-MM-dd')
            .parse(_selectedDate.toString().substring(0, 10)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          shadowColor: Colors.grey,
          elevation: 3, // set the elevation to create a shadow effect
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(
                  20), // set the bottom radius to create a rounded effect
            ),
          ),
          title: isDateSubmitted
              ? Text(
                  '${_selectedDate.toString().substring(0, 10)}-ны явсан зам',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : Text(
                  '${widget.date.toString().substring(0, 10)}-ны явсан зам',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                _selectDate(context);
              },
              child: const Text(
                'Өдрөөр хайх',
                style: TextStyle(color: CustomColors.MAIN_BLUE),
              ),
            ),
          ],
        ),
        body: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Obx(
              () => locDataController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : Obx(
                      () => locDataController.locData.isEmpty
                          ? const Expanded(
                              child: Center(
                                child:
                                    Text('Уг өдрийн явсан зам байхгүй байна.'),
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: 1,
                                itemBuilder: (context, index) {
                                  return WorkerPathList(
                                    date: locDataController.locData.first.date!,
                                    day: Functions().calculateDay().toString(),
                                    difference: Functions().calculateTime(),
                                    totalDistance:
                                        Functions().calculateDistance(),
                                  );
                                },
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
