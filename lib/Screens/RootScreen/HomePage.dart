import 'package:flutter/material.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen>
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
        title: const Text('Таны явсан түүх'),
        bottom: TabBar(
          labelColor: const Color(0xffF9A529),
          indicatorColor: const Color(0xffF9A529),
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Өнөөдрийн явж буй',
            ),
            Tab(
              text: 'Өдрөөр хайх',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // MapScreen(),
          // Kk(),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
