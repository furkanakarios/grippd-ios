import SwiftUI

// MARK: - Variant 3: TYPE CONSTELLATION
// Karanlık zeminde dağınık altın yıldız parçacıkları belirir, sonra orbit
// hareketiyle merkeze süzülüp bir "G" formuna kavuşur. Aralarına çizgilerle
// constellation çizilir, ardından twinkle ile hold eder.
// Loop süresi ~4.0s.
// Sabit kalan: "Grippd" başlığı + "Film, dizi ve kitap günlüğün" alt yazısı.

struct SplashView: View {

    /// Toplam animasyon süresi. ContentView splash bekleme süresi bu değere
    /// eşit olmalı — animasyon bitmeden ContentView'a geçilmez.
    static let totalDuration: TimeInterval = 4.0

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
                TypeConstellationAnimation()
                    .frame(width: 220, height: 220)

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

private struct TypeConstellationAnimation: View {
    /// Animasyon başlangıç zamanı — .onAppear'da set edilir, her uygulama
    /// açılışında sıfırdan başlatır.
    @State private var startDate: Date = Date()

    private let gold = Color(red: 0.91, green: 0.70, blue: 0.29)

    // Sample N points along a stylized "G" path (centered around 0,0)
    private static let targets: [CGPoint] = sampleGPoints(28)
    private static let starts: [CGPoint] = {
        targets.enumerated().map { i, _ in
            let a = CGFloat(i) * 137.5 * .pi / 180
            let r = 70 + CGFloat((i * 23) % 50)
            return CGPoint(x: cos(a) * r, y: sin(a) * r * 0.9)
        }
    }()

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
        let fadeIn = clamp01(t / 0.20)
        let moveT = clamp01((t - 0.18) / 0.50)
        let moveE = easeInOutCubic(moveT)

        let monoT = clamp01((t - 0.62) / 0.28)
        let monoOpacity = monoT * 0.82
        let monoScale = 0.85 + monoT * 0.15

        let lineT = clamp01((t - 0.50) / 0.25)
        let twinkleT = clamp01((t - 0.72) / 0.28)

        ZStack {
            // Background G monogram, fades in
            GoldGMonogram(glow: 0.6)
                .frame(width: 120, height: 120)
                .scaleEffect(monoScale)
                .opacity(monoOpacity)

            // Connecting lines
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                var path = Path()
                for i in 1..<Self.targets.count {
                    let prev = Self.targets[i - 1]
                    let tgt = Self.targets[i]
                    let sPrev = Self.starts[i - 1]
                    let s = Self.starts[i]
                    let x0 = sPrev.x + (prev.x - sPrev.x) * moveE + center.x
                    let y0 = sPrev.y + (prev.y - sPrev.y) * moveE + center.y
                    let x1 = s.x + (tgt.x - s.x) * moveE + center.x
                    let y1 = s.y + (tgt.y - s.y) * moveE + center.y
                    path.move(to: CGPoint(x: x0, y: y0))
                    path.addLine(to: CGPoint(x: x1, y: y1))
                }
                ctx.stroke(path,
                           with: .color(self.gold.opacity(lineT * 0.45)),
                           lineWidth: 0.6)
            }

            // Particles
            ZStack {
                ForEach(0..<Self.targets.count, id: \.self) { i in
                    let s = Self.starts[i]
                    let tgt = Self.targets[i]
                    let x = s.x + (tgt.x - s.x) * moveE
                    let y = s.y + (tgt.y - s.y) * moveE
                    let dotSize: CGFloat = CGFloat(3 + (i % 3))
                    let tw: CGFloat = twinkleT > 0
                        ? 0.5 + 0.5 * sin(t * .pi * 2 * (1.5 + CGFloat(i % 4) * 0.3) + CGFloat(i))
                        : 1
                    let baseOp = fadeIn * (twinkleT > 0 ? 0.5 + tw * 0.5 : 1)

                    Circle()
                        .fill(self.gold)
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: self.gold.opacity(0.85), radius: 4)
                        .shadow(color: self.gold.opacity(0.4), radius: 9)
                        .offset(x: x, y: y)
                        .opacity(baseOp)
                }

                // Ambient sparkles
                ForEach(0..<6, id: \.self) { i in
                    let a = (CGFloat(i) * 60 + 30) * .pi / 180
                    let r: CGFloat = 90
                    let x = cos(a) * r
                    let y = sin(a) * r * 0.95
                    let tw = 0.4 + 0.6 * abs(sin(t * .pi * 2 * (0.8 + CGFloat(i) * 0.2) + CGFloat(i)))
                    Circle()
                        .fill(self.gold.opacity(0.7))
                        .frame(width: 2, height: 2)
                        .shadow(color: self.gold.opacity(0.6), radius: 2)
                        .offset(x: x, y: y)
                        .opacity(fadeIn * tw * 0.6)
                }
            }
        }
    }
}

// MARK: - G-shape sample points

private func sampleGPoints(_ n: Int) -> [CGPoint] {
    var pts: [CGPoint] = []
    let radius: CGFloat = 56
    let arcCount = Int(Double(n) * 0.78)
    let startAngle: CGFloat = -20
    let sweep: CGFloat = -300
    for i in 0..<arcCount {
        let k = CGFloat(i) / CGFloat(max(1, arcCount - 1))
        let ang = (startAngle + sweep * k) * .pi / 180
        pts.append(CGPoint(x: cos(ang) * radius, y: sin(ang) * radius))
    }
    let stubCount = n - arcCount
    for i in 0..<stubCount {
        let k = CGFloat(i) / CGFloat(max(1, stubCount - 1))
        pts.append(CGPoint(x: 5 + k * 36, y: 6))
    }
    return pts
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

            // 12 saatten → 9 → 6 → 3 saatte bitecek 270° sweep.
            // SwiftUI y-down koordinatta clockwise:true visual olarak saat
            // yönünün tersi — gap sağda kalır, stub için yer açar.
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

#Preview {
    SplashView()
}
