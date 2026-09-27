import 'package:flutter/material.dart';

import '../../../core/services/subscription_service.dart';
import 'paywall_screen.dart';

/// Google girişi provider kapsamını/rotaları silerken sadece gezinme niyetini korur.
/// Hesap verisi veya abonelik hakkı burada saklanmaz.
class SubscriptionIntent {
  static bool pending = false;
}

class SubscriptionEntry extends StatefulWidget {
  const SubscriptionEntry({required this.child, super.key});
  final Widget child;

  @override
  State<SubscriptionEntry> createState() => _SubscriptionEntryState();
}

class _SubscriptionEntryState extends State<SubscriptionEntry> {
  @override
  void initState() {
    super.initState();
    if (SubscriptionIntent.pending && SubscriptionService.isEligible) {
      SubscriptionIntent.pending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
