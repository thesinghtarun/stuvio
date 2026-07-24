import 'package:flutter/material.dart';
import 'package:studyvault/core/const/constant.dart';
import 'package:studyvault/core/theme/app_style.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        children: [
          SizedBox(height: height * 0.14),
          Text(pg2t1, style: AppStyle.onboardingHeading),
          SizedBox(height: 30),
          Text(pg2st1, style: AppStyle.onboardingSubHeading),
          Text(pg2st2, style: AppStyle.onboardingSubHeading),
          SizedBox(height: 30),
          Image.asset(pg2),
        ],
      ),
    );
  }
}
