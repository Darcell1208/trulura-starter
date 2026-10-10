import 'package:flutter/material.dart';
import 'package:trulura/compat/provider_compat.dart';
import 'package:trulura/providers/app_provider.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/core/navigation/tru_navigation.dart';
import 'package:trulura/widgets/trulura_safe_avatar.dart';

/// Home's compact publishing entry; only actual account imagery is shown.
class HomeSocialComposer extends StatelessWidget {
  const HomeSocialComposer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFE7DEF5) : const Color(0xFF322345);
    void open(String format) => TruNavigation.pushWithReturnTo(
        context, '${AppRoutes.createPost}?format=$format');
    Widget action(String label, IconData icon, String format, Color color) =>
        TextButton.icon(
          onPressed: () => open(format),
          icon: Icon(icon, size: 21, color: color),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: ink,
            minimumSize: const Size(44, 44),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [
          Color(0xFFC591DD),
          Color(0xFF44487E),
          Color(0xFF7394C1),
        ]),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF181326), Color(0xFF080B16)]
                : const [Color(0xFFFAF5FF), Color(0xFFF2F4FC)],
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  Color(0xFFF1BD98),
                  Color(0xFFD78AE6),
                  Color(0xFF7BBBF7),
                  Color(0xFFF1BD98),
                ]),
              ),
              child: TruLuraSafeAvatar(
                radius: 22,
                image: profileImageProvider(user?.profileImage),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Material(
              color: dark ? const Color(0xFF090A14) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => open('Text'),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Text('Share what’s on your mind…',
                      style: TextStyle(
                          color: ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w400)),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 6),
          Divider(height: 1, color: ink.withValues(alpha: 0.10)),
          Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
            action(
                'Write', Icons.edit_outlined, 'Text', const Color(0xFFD6ACEF)),
            action('Photo', Icons.image_outlined, 'Image',
                const Color(0xFF8ABCEB)),
            action('Video', Icons.videocam_outlined, 'Video',
                const Color(0xFFF0ABD8)),
          ]),
        ]),
      ),
    );
  }
}
