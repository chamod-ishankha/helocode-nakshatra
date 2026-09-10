import 'package:flutter/material.dart';

import '../../../core/purchases/purchase_controller.dart';
import '../../../core/purchases/purchase_gateway.dart';
import '../../../l10n/generated/app_localizations.dart';

/// What to say after a purchase or a restore (KAN-35).
///
/// Every outcome gets its own sentence. Collapsing them into "purchase failed"
/// is how somebody whose slow payment method is still settling concludes the
/// app took their money and gave them nothing — and then asks Google for a
/// refund and leaves a review saying so.
extension PurchaseMessages on PurchaseOutcome {
  /// The message to show, or null when there is nothing to say.
  ///
  /// Cancelling is a decision, not a failure. Telling somebody who just
  /// changed their mind that something went wrong is both untrue and annoying.
  String? message(L10n l) => switch (this) {
    PurchaseOutcome.purchased => l.purchaseThanks,
    PurchaseOutcome.pending => l.purchasePending,
    PurchaseOutcome.cancelled => null,
    PurchaseOutcome.alreadyOwned => l.purchaseAlreadyOwned,
    PurchaseOutcome.unavailable => l.purchaseProductUnavailable,
    PurchaseOutcome.notAllowed => l.purchaseNotAllowed,
    PurchaseOutcome.network => l.purchaseRestoreFailed,
    PurchaseOutcome.failed => l.purchaseFailed,
  };
}

extension RestoreMessages on RestoreOutcome {
  String message(L10n l) => switch (this) {
    RestoreOutcome.restored => l.purchaseRestored,
    RestoreOutcome.nothingFound => l.purchaseRestoreNothing,
    RestoreOutcome.failed => l.purchaseRestoreFailed,
    RestoreOutcome.unavailable => l.purchaseUnavailable,
  };
}

/// Shows [text] if there is any, on a context that is still mounted.
///
/// Both flows await the store, which takes as long as the user spends in
/// Google's payment sheet — easily long enough for them to leave the screen
/// first.
void showPurchaseMessage(BuildContext context, String? text) {
  if (text == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
