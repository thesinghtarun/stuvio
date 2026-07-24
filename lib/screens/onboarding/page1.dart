import 'package:flutter/material.dart';
import 'package:studyvault/core/const/constant.dart';
import 'package:studyvault/core/theme/app_style.dart';

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        children: [
          SizedBox(height: height * 0.14),
          Text(pg1t1, style: AppStyle.onboardingHeading),
          Text(pg1t2, style: AppStyle.onboardingHeading),
          SizedBox(height: 10),
          Text(pg1st1, style: AppStyle.onboardingSubHeading),
          Text(pg1st2, style: AppStyle.onboardingSubHeading),
          SizedBox(height: 30),
          Image.asset(pg1),
        ],
      ),
    );
  }
}
