import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_pro/Components/WorkerPathList.dart';
import 'package:intl/intl.dart';

class Kk extends StatefulWidget {
  const Kk({super.key});

  @override
  State<Kk> createState() => _KkState();
}

class _KkState extends State<Kk> {
  late DateTime _selectedDate1 = DateTime.now();
  late DateTime _selectedDate2 = DateTime.now();

  Future<void> _selectDate1(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate1) {
      setState(() {
        _selectedDate1 = picked;
      });
    }
  }

  Future<void> _selectDate2(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate2) {
      setState(() {
        _selectedDate2 = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: InkWell(
                    onTap: () {
                      _selectDate1(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: _selectedDate1 != null
                          ? Text(DateFormat('yyyy-MM-dd')
                              .format(_selectedDate1)
                              .toString())
                          : Text(DateFormat('yyyy-MM-dd')
                              .format(DateTime.now())
                              .toString()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('-',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: InkWell(
                    onTap: () {
                      _selectDate2(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: _selectedDate2 != null
                          ? Text(DateFormat('yyyy-MM-dd')
                              .format(_selectedDate2)
                              .toString())
                          : Text(DateFormat('yyyy-MM-dd')
                              .format(DateTime.now())
                              .toString()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                return const WorkerPathList();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 5,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff73BEB2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Niit yvj bui zam: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '10 km',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Text(
                          'Niit yvj bui hugatsaa: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '4h 6m',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
