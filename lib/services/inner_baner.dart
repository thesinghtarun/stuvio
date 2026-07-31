import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/provider/inner_banner_provider.dart';


class InlineBannerAd extends StatefulWidget {
  const InlineBannerAd({super.key});

  @override
  State<InlineBannerAd> createState() => _InlineBannerAdState();
}

class _InlineBannerAdState extends State<InlineBannerAd> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InlineBannerProvider>().loadBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InlineBannerProvider>(
      builder: (context, provider, child) {
        if (!provider.isLoaded || provider.banner == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: provider.banner!.size.width.toDouble(),
              height: provider.banner!.size.height.toDouble(),
              child: AdWidget(ad: provider.banner!),
            ),
          ),
        );
      },
    );
  }
}