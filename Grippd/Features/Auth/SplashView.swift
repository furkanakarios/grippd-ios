import SwiftUI

// MARK: - Keyframe Values

private struct HeartbeatValues {
    var scale: CGFloat = 1.0
    var glowOpacity: CGFloat = 0.12
    var glowRadius: CGFloat = 24
}

// MARK: - SplashView

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

            VStack(spacing: 18) {
                // Logo + heartbeat
                KeyframeAnimator(
                    initialValue: HeartbeatValues(),
                    repeating: true
                ) { values in
                    ZStack {
                        Circle()
                            .fill(GrippdTheme.Colors.accent.opacity(values.glowOpacity))
                            .frame(width: 130, height: 130)
                            .blur(radius: values.glowRadius)

                        Image(systemName: "film.stack.fill")
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(GrippdTheme.Colors.accent)
                            .scaleEffect(values.scale)
                    }
                } keyframes: { _ in
                    // Heartbeat: lub (büyük atış) → dub (küçük atış) → sessizlik
                    KeyframeTrack(\.scale) {
                        // Başlangıç
                        LinearKeyframe(1.0, duration: 0.01)
                        // --- Lub (1. atış) ---
                        SpringKeyframe(1.18, duration: 0.12,
                                       spring: .init(duration: 0.12, bounce: 0.3))
                        SpringKeyframe(0.96, duration: 0.11,
                                       spring: .init(duration: 0.11, bounce: 0.1))
                        // Kısa nefes
                        LinearKeyframe(0.96, duration: 0.06)
                        // --- Dub (2. atış, biraz daha küçük) ---
                        SpringKeyframe(1.09, duration: 0.10,
                                       spring: .init(duration: 0.10, bounce: 0.2))
                        SpringKeyframe(1.0, duration: 0.11,
                                       spring: .init(duration: 0.11, bounce: 0.1))
                        // Sessizlik (sonraki atışa kadar)
                        LinearKeyframe(1.0, duration: 0.89)
                    }
                    KeyframeTrack(\.glowOpacity) {
                        LinearKeyframe(0.12, duration: 0.01)
                        LinearKeyframe(0.45, duration: 0.12)
                        LinearKeyframe(0.12, duration: 0.11)
                        LinearKeyframe(0.12, duration: 0.06)
                        LinearKeyframe(0.30, duration: 0.10)
                        LinearKeyframe(0.12, duration: 0.11)
                        LinearKeyframe(0.12, duration: 0.89)
                    }
                    KeyframeTrack(\.glowRadius) {
                        LinearKeyframe(24, duration: 0.01)
                        LinearKeyframe(38, duration: 0.12)
                        LinearKeyframe(24, duration: 0.11)
                        LinearKeyframe(24, duration: 0.06)
                        LinearKeyframe(30, duration: 0.10)
                        LinearKeyframe(24, duration: 0.11)
                        LinearKeyframe(24, duration: 0.89)
                    }
                }

                // App adı
                VStack(spacing: 6) {
                    Text("Grippd")
                        .font(GrippdTheme.Typography.appName)
                        .foregroundStyle(.white)

                    Text("Film, dizi ve kitap günlüğün")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.40))
                        .tracking(0.3)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
