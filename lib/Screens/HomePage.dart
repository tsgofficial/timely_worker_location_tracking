import 'package:flutter/material.dart';
import 'package:google_maps_pro/Screens/KK.dart';
import 'package:google_maps_pro/Screens/MapScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    // _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hiiiiiiiiiiiiiiiiiii'),
        bottom: TabBar(
          labelColor: const Color(0xffF9A529),
          indicatorColor: const Color(0xffF9A529),
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Onoodriin yvj bui zam',
            ),
            Tab(
              text: 'Niit yvsan',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MapScreen(
              // googleMapsController: _controller,
              ),
          Kk(),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
