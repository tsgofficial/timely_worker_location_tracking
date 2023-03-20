import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Screens/DetailedMapScreen.dart';

class WorkerPathList extends StatefulWidget {
  const WorkerPathList({super.key});

  @override
  State<WorkerPathList> createState() => _WorkerPathListState();
}

class _WorkerPathListState extends State<WorkerPathList> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => const DetailedMapScreen());
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2023/03/05',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Garig: ',
                        style: TextStyle(
                          color: Colors.grey,
                          // fontSize: 12,
                        ),
                      ),
                      Text(
                        'Baasan',
                        style: TextStyle(
                          color: Colors.grey,
                          // fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Niit yvsan: ',
                    style: TextStyle(
                      color: Colors.grey,
                      // fontSize: 12,
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffF04262),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
                      child: Text('12.1 km'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffF9A529),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
                      child: Text('5h 3m'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
