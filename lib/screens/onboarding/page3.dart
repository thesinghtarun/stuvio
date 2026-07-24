import 'package:flutter/material.dart';
import 'package:studyvault/core/const/constant.dart';
import 'package:studyvault/core/theme/app_style.dart';

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Center(
      child: Column(
        children: [
          SizedBox(height: height * 0.14),
          Text(pg3t1, style: AppStyle.onboardingHeading),
          SizedBox(height: 30),
          Text(pg3st1, style: AppStyle.onboardingSubHeading),
          Text(pg3st2, style: AppStyle.onboardingSubHeading),
          SizedBox(height: 30),
          Image.asset(pg3),
        ],
      ),
    );
  }
}
