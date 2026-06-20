import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/home_header.dart';
import 'widgets/growth_drop_card.dart';
import 'widgets/social_drops_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(),
          SizedBox(height: 28),
          GrowthDropCard(),
          SizedBox(height: 24),
          SocialDropsCard(),
        ],
      ),
    );
  }
}
