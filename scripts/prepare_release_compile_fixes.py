from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# The AppState action extension must be imported by each library that calls its
# extension methods. Keep this as a build-time safety net for the current
# source layout without changing any runtime behavior.
for path in (ROOT / 'lib').rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    if "import 'state/app_state.dart';" in text and "import 'state/app_state_actions.dart';" not in text:
        text = text.replace(
            "import 'state/app_state.dart';",
            "import 'state/app_state.dart';\nimport 'state/app_state_actions.dart';",
            1,
        )
    if "import '../state/app_state.dart';" in text and "import '../state/app_state_actions.dart';" not in text:
        text = text.replace(
            "import '../state/app_state.dart';",
            "import '../state/app_state.dart';\nimport '../state/app_state_actions.dart';",
            1,
        )
    path.write_text(text, encoding='utf-8')

main = ROOT / 'lib/main.dart'
text = main.read_text(encoding='utf-8')
if "package:provider/provider.dart" not in text:
    text = text.replace(
        "import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;",
        "import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;\nimport 'package:provider/provider.dart';",
        1,
    )
main.write_text(text, encoding='utf-8')

ad = ROOT / 'lib/ads/app_interstitial_ad.dart'
text = ad.read_text(encoding='utf-8')
if 'static void showThen(' not in text:
    marker = "  static void showIfEligible() {"
    method = """  /// Shows the preloaded ad when available and runs [onComplete] after\n  /// dismissal. If no ad is ready, continues immediately.\n  static void showThen(void Function() onComplete) {\n    final ad = _ad;\n    if (ad == null) {\n      preload();\n      onComplete();\n      return;\n    }\n\n    _ad = null;\n    var completed = false;\n    void complete() {\n      if (completed) return;\n      completed = true;\n      onComplete();\n    }\n\n    ad.fullScreenContentCallback = FullScreenContentCallback(\n      onAdDismissedFullScreenContent: (ad) {\n        ad.dispose();\n        preload();\n        complete();\n      },\n      onAdFailedToShowFullScreenContent: (ad, error) {\n        debugPrint('Interstitial failed to show: $error');\n        ad.dispose();\n        preload();\n        complete();\n      },\n    );\n    ad.show();\n  }\n\n"""
    text = text.replace(marker, method + marker, 1)
ad.write_text(text, encoding='utf-8')

print('Release compile fixes prepared successfully.')
