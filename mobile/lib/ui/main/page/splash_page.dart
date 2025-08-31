import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/providers/providers.dart';

@RoutePage()
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        authenticated: () =>
            context.router.replaceAll([const NavigationRoute()]),
        unauthenticated: () => context.router.replaceAll([const LoginRoute()]),
        error: (message) => context.router.replaceAll([const LoginRoute()]),
      );
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FC), Color(0xFFEBEEF5)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.05,
              right: -MediaQuery.of(context).size.width * 0.25,
              child: Transform.rotate(
                angle: 0.6,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.width * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4285F4).withOpacity(0.07),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -MediaQuery.of(context).size.height * 0.12,
              left: -MediaQuery.of(context).size.width * 0.2,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.65,
                  height: MediaQuery.of(context).size.width * 0.65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4285F4).withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -MediaQuery.of(context).size.height * 0.05,
              left: -MediaQuery.of(context).size.width * 0.1,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.width * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF34A853).withOpacity(0.12),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF34A853).withOpacity(0.15),
                      width: 0.2,
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4285F4).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          size: const Size(60, 60),
                          painter: _GalleryIconPainter(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _drawPhotoCard(
      canvas,
      Rect.fromLTRB(
        size.width * 0.1,
        size.height * 0.4,
        size.width * 0.7,
        size.height * 0.95,
      ),
      Colors.white.withOpacity(0.90),
      0.0,
    );

    _drawPhotoCard(
      canvas,
      Rect.fromLTRB(
        size.width * 0.3,
        size.height * 0.1,
        size.width * 0.85,
        size.height * 0.65,
      ),
      Colors.white.withOpacity(0.60),
      0.03,
    );

    _drawPhotoCard(
      canvas,
      Rect.fromLTRB(
        size.width * 0.5,
        size.height * 0.2,
        size.width * 1.0,
        size.height * 0.85,
      ),
      Colors.white.withOpacity(0.30),
      0.06,
    );
  }

  void _drawPhotoCard(
    Canvas canvas,
    Rect rect,
    Color color,
    double shadowIntensity,
  ) {
    final cardPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1 * shadowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      shadowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      cardPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
