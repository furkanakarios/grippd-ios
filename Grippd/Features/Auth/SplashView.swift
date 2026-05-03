import SwiftUI

// MARK: - Variant 2: APERTURE BLOOM
// 6 yapraklı altın kamera diyaframı kapalıdan açığa rotate + scale yapar,
// açıldığı an merkezden altın bir bloom yayılır ve "G" monogramı reveal olur.
// Loop süresi ~3.8s.
// Sabit kalan: "Grippd" başlığı + "Film, dizi ve kitap günlüğün" alt yazısı.

struct SplashView: View {

    /// Toplam animasyon süresi. ContentView splash bekleme süresi bu değere
    /// eşit olmalı — animasyon bitmeden ContentView'a geçilmez.
    static let totalDuration: TimeInterval = 3.8

    private let gold = Color(red: 0.91, green: 0.70, blue: 0.29)

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

            RadialGradient(
                colors: [gold.opacity(0.10), .clear],
                center: .init(x: 0.5, y: 0.30),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                ApertureBloomAnimation()
                    .frame(width: 200, height: 200)

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

// MARK: - Animation

private struct ApertureBloomAnimation: View {
    /// Animasyon başlangıç zamanı — .onAppear'da set edilir, her uygulama
    /// açılışında sıfırdan başlatır.
    @State private var startDate: Date = Date()

    private let gold = Color(red: 0.91, green: 0.70, blue: 0.29)

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = ctx.date.timeIntervalSince(startDate)
            let t = clamp01(CGFloat(elapsed / SplashView.totalDuration))
            animationContent(t: t)
        }
        .onAppear { startDate = Date() }
    }

    @ViewBuilder
    private func animationContent(t: CGFloat) -> some View {
        let openT = clamp01(t / 0.55)
        let openE = easeInOutCubic(openT)

        let bloomT = clamp01((t - 0.40) / 0.18)
        let bloomFade = 1 - clamp01((t - 0.58) / 0.20)
        let bloomIntensity = sin(bloomT * .pi) * bloomFade

        let monoT = clamp01((t - 0.55) / 0.30)
        let monoScale = 0.5 + easeOutBack(monoT) * 0.5
        let monoOpacity = monoT

        let apertureFade = 1 - clamp01((t - 0.70) / 0.25) * 0.55

        let hold = clamp01((t - 0.85) / 0.15)
        let pulse = 1 + sin(t * .pi * 2) * 0.015 * hold

        ZStack {
            // Center bloom flash
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            gold.opacity(0.55 * bloomIntensity),
                            gold.opacity(0.15 * bloomIntensity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(0.6 + bloomIntensity * 1.2)
                .opacity(bloomIntensity)
                .blur(radius: 4)

            // Aperture blades
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    ApertureBlade(index: i, openT: openE)
                }

                // Outer thin ring
                Circle()
                    .stroke(
                        gold.opacity(0.45 + 0.35 * (1 - openE)),
                        lineWidth: 1.5
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: gold.opacity(0.25), radius: 20)
            }
            .frame(width: 180, height: 180)
            .rotationEffect(.degrees(Double(openE) * 60))
            .scaleEffect(pulse)
            .opacity(apertureFade)

            // G monogram
            GoldGMonogram(glow: 0.6 + 0.4 * monoT)
                .frame(width: 100, height: 100)
                .scaleEffect(monoScale)
                .opacity(monoOpacity)
        }
    }
}

private struct ApertureBlade: View {
    let index: Int
    let openT: CGFloat
    private let gold = Color(red: 0.91, green: 0.70, blue: 0.29)

    var body: some View {
        let inset = 20 + openT * 50
        let tilt = -28 + openT * 26

        Triangle()
            .fill(gold.opacity(0.55 - openT * 0.25))
            .frame(width: 76, height: 78)
            .rotationEffect(.degrees(Double(tilt)), anchor: .top)
            .offset(y: inset - 90)
            .rotationEffect(.degrees(Double(index) * 60))
            .shadow(color: gold.opacity(0.4), radius: 4)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Gold "G" monogram

struct GoldGMonogram: View {
    var glow: CGFloat = 1
    var body: some View {
        let gold = Color(red: 0.91, green: 0.70, blue: 0.29)
        let goldLight = Color(red: 0.97, green: 0.84, blue: 0.48)
        let goldDeep  = Color(red: 0.71, green: 0.50, blue: 0.16)

        Canvas { ctx, size in
            let scale = min(size.width, size.height) / 120.0
            ctx.scaleBy(x: scale, y: scale)

            // 12 saatten (üst) → 9 → 6 → 3 saatte (sağ) bitecek 270° sweep.
            // SwiftUI y-down koordinatta clockwise:true visual olarak
            // saat yönünün tersi — gap sağda kalır, stub için yer açar.
            var gPath = Path()
            gPath.addArc(
                center: CGPoint(x: 60, y: 60),
                radius: 48,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: true
            )
            var stub = Path()
            stub.move(to: CGPoint(x: 108, y: 60))
            stub.addLine(to: CGPoint(x: 72, y: 60))
            stub.addLine(to: CGPoint(x: 72, y: 72))
            stub.addLine(to: CGPoint(x: 96, y: 72))

            let goldGradient = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [goldLight, gold, goldDeep]),
                startPoint: .zero,
                endPoint: CGPoint(x: 120, y: 120)
            )

            ctx.stroke(gPath, with: goldGradient,
                       style: StrokeStyle(lineWidth: 14, lineCap: .round))
            ctx.stroke(stub, with: goldGradient,
                       style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))

            // Dashed inner arc — G ile aynı yön
            var dash = Path()
            dash.addArc(
                center: CGPoint(x: 60, y: 60),
                radius: 36,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: true
            )
            ctx.stroke(dash, with: .color(Color(red: 0.10, green: 0.08, blue: 0.13)),
                       style: StrokeStyle(lineWidth: 3, dash: [3, 4]))
        }
        .shadow(color: gold.opacity(0.55 * glow), radius: 18 * glow)
    }
}

// MARK: - Helpers

private func clamp01(_ v: CGFloat) -> CGFloat { max(0, min(1, v)) }
private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
    t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
}
private func easeOutBack(_ t: CGFloat) -> CGFloat {
    let c1: CGFloat = 1.70158
    let c3 = c1 + 1
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
}

#Preview {
    SplashView()
}
