import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Screens/OtherScreens/DetailedMapScreen.dart';
import 'CustomColors.dart';

class WorkerPathList extends StatefulWidget {
  final DateTime date;
  final double totalDistance;
  final Duration difference;
  final String day;
  const WorkerPathList({
    super.key,
    required this.date,
    required this.totalDistance,
    required this.difference,
    required this.day,
  });

  @override
  State<WorkerPathList> createState() => _WorkerPathListState();
}

class _WorkerPathListState extends State<WorkerPathList> {
  DateTime selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(
          () => DetailedMapScreen(
            date: widget.date,
            totalDistance: widget.totalDistance,
            totalTime: widget.difference.toString(),
          ),
        );
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
                  Text(
                    widget.date.toString().substring(0, 10),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'Гариг: ',
                        style: TextStyle(
                          color: Colors.grey,
                          // fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.day,
                        style: const TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold,
                          // fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Нийт явсан: ',
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
                      color: CustomColors.MAIN_BLUE,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 15),
                      child: Text(
                        '${widget.totalDistance.toString().substring(0, 5)} км',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: CustomColors.MAIN_BLUE,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 15),
                      child: Text(
                        '${widget.difference.toString().substring(0, 1)} ц'
                        ' ${widget.difference.toString().substring(2, 4)} м',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
