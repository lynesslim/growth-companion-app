import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/home_header.dart';
import 'widgets/companion_container.dart';
import 'widgets/growth_drop_card.dart';
import 'widgets/quest_log_card.dart';

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
          CompanionContainer(),
          SizedBox(height: 24),
          GrowthDropCard(),
          SizedBox(height: 16),
          QuestLogCard(),
        ],
      ),
    );
  }
}
