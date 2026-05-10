import 'package:sukientotapp/core/utils/import/global.dart';

class TermsActionGate extends StatelessWidget {
  final bool blocked;
  final VoidCallback onBlockedTap;
  final Widget child;

  const TermsActionGate({
    super.key,
    required this.blocked,
    required this.onBlockedTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!blocked) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onBlockedTap,
            ),
          ),
        ),
      ],
    );
  }
}
