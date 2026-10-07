import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gta_app/src/commons/controller/locale_controller.dart';
import 'package:gta_app/src/features/seller/common/widgets/seller_app_bar.dart';
import 'package:gta_app/src/res/colors.dart';
import 'package:gta_app/src/utils/l10n_extensions.dart';

/// Language selection for the seller flow. The selected locale is shared by
/// the whole app and is persisted by [LocaleController].
class SellerLanguageScreen extends ConsumerWidget {
  const SellerLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeControllerProvider);

    return Scaffold(
      backgroundColor: SellerColors.background,
      appBar: SellerAppBar(
        title: context.l10n.languageMenuTitle,
        showLogo: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n.languagePickerSubtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CommonColors.greyText,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF0F0F4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: kAppLanguages.asMap().entries.map((entry) {
                final index = entry.key;
                final language = entry.value;
                final isSelected = currentLocale.languageCode == language.code;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => ref
                          .read(localeControllerProvider.notifier)
                          .setLocale(language.code),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.nativeName,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: CommonColors.black,
                                    ),
                                  ),
                                  if (language.nativeName !=
                                      language.englishName) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      language.englishName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: CommonColors.greyText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? SellerColors.primaryLight
                                  : Colors.grey.shade300,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index < kAppLanguages.length - 1)
                      const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF5F5F8),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
