import SwiftUI

// MARK: - Variant 1: FILM STRIP REVEAL
// Üst kenardan kayıp gelen film şeridinde frame'ler sırayla altın ışıkla
// yanar, son aşamada zoom + altın "G" monogramı reveal olur.
// Loop süresi ~3.6s. Kalp atışı animasyonunun yerine geçer.
// Sabit kalan: "Grippd" başlığı + "Film, dizi ve kitap günlüğün" alt yazısı.

struct SplashView: View {

    /// Toplam animasyon süresi. ContentView splash bekleme süresi bu değere
    /// eşit olmalı — animasyon bitmeden ContentView'a geçilmez.
    static let totalDuration: TimeInterval = 3.6

    var body: some View {
        ZStack {
            // Background — GrippdTheme ile uyumlu
            Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.91, green: 0.70, blue: 0.29).opacity(0.10),
                    .clear
                ],
                center: .init(x: 0.5, y: 0.30),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Animation slot — her .onAppear'da sıfırdan oynar
                FilmStripRevealAnimation()
                    .frame(width: 220, height: 200)

                // Sabit başlık + alt yazı (mevcut launch ile aynı)
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

private struct FilmStripRevealAnimation: View {
    /// Animasyon başlangıç zamanı — .onAppear'da set edilir, her uygulama
    /// açılışında sıfırdan başlatır. TimelineView her frame'de elapsed
    /// üzerinden t = 0..1 hesaplar; faz pencereleri ve easing'ler her
    /// frame'de doğru çalışır.
    @State private var startDate: Date = Date()

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
        let stripT = clamp01(t / 0.55)
        let stripX = (1 - easeOutCubic(stripT)) * -360

        let zoomT = clamp01((t - 0.55) / 0.23)
        let zoomScale = 1 + easeInOutCubic(zoomT) * 1.6
        let centerOpacity = 1 - easeInCubic(zoomT) * 0.85

        // Yan 4 frame: zoom başlar başlamaz (0.55) hızlıca 0'a iner
        let peerOpacity = 1 - clamp01((t - 0.55) / 0.15)

        let monoT = clamp01((t - 0.72) / 0.28)
        let monoScale = 0.6 + easeOutBack(monoT) * 0.4
        let monoOpacity = monoT

        ZStack {
            // Film strip — yan 4 frame yok olur, ortadaki solgun kalır
            HStack(spacing: 8) {
                FilmFrame(icon: .film, lit: liturn(t, start: 0.08))
                    .opacity(peerOpacity)
                FilmFrame(icon: .tv,   lit: liturn(t, start: 0.15))
                    .opacity(peerOpacity)
                FilmFrame(icon: .book, lit: liturn(t, start: 0.22))
                    .opacity(centerOpacity)
                FilmFrame(icon: .film, lit: liturn(t, start: 0.29))
                    .opacity(peerOpacity)
                FilmFrame(icon: .tv,   lit: liturn(t, start: 0.36))
                    .opacity(peerOpacity)
            }
            .scaleEffect(zoomScale)
            .offset(x: stripX)

            // G monogram
            GoldGMonogram()
                .frame(width: 110, height: 110)
                .scaleEffect(monoScale)
                .opacity(monoOpacity)
        }
    }

    private func liturn(_ t: CGFloat, start: CGFloat) -> CGFloat {
        clamp01((t - start) / 0.10)
    }
}

// MARK: - Single film frame (sprockets + lit content)

private struct FilmFrame: View {
    enum Icon { case film, tv, book }
    let icon: Icon
    let lit: CGFloat

    private let gold = Color(red: 0.91, green: 0.70, blue: 0.29)

    var body: some View {
        VStack(spacing: 0) {
            sprocketRow
            content
            sprocketRow
        }
        .frame(width: 56, height: 76)
    }

    private var sprocketRow: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(gold.opacity(0.15 + 0.4 * lit))
                    .frame(width: 6, height: 4)
                    .shadow(color: gold.opacity(lit > 0.3 ? 0.5 * lit : 0), radius: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 10)
        .background(Color.black.opacity(0.6))
    }

    private var content: some View {
        ZStack {
            if lit > 0 {
                RadialGradient(
                    colors: [
                        gold.opacity(0.55 * lit),
                        gold.opacity(0.05 * lit),
                        Color.black.opacity(0.85)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 32
                )
            } else {
                Color.white.opacity(0.04)
            }

            iconView
                .foregroundStyle(gold.opacity(0.4 + 0.6 * lit))
        }
        .frame(maxHeight: .infinity)
        .overlay(
            VStack(spacing: 0) {
                Rectangle().fill(gold.opacity(0.15 + 0.45 * lit)).frame(height: 1)
                Spacer()
                Rectangle().fill(gold.opacity(0.15 + 0.45 * lit)).frame(height: 1)
            }
        )
        .shadow(color: gold.opacity(lit > 0.1 ? 0.45 * lit : 0), radius: 12 * lit)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .film:
            Image(systemName: "film")
                .font(.system(size: 22, weight: .light))
        case .tv:
            Image(systemName: "tv")
                .font(.system(size: 22, weight: .light))
        case .book:
            Image(systemName: "book")
                .font(.system(size: 22, weight: .light))
        }
    }
}

// MARK: - Gold "G" monogram (shared across variants)

struct GoldGMonogram: View {
    var glow: CGFloat = 1
    var body: some View {
        let gold = Color(red: 0.91, green: 0.70, blue: 0.29)
        let goldLight = Color(red: 0.97, green: 0.84, blue: 0.48)
        let goldDeep  = Color(red: 0.71, green: 0.50, blue: 0.16)

        Canvas { ctx, size in
            // Sized to its frame; scale our 120-unit design into it.
            let scale = min(size.width, size.height) / 120.0
            ctx.scaleBy(x: scale, y: scale)

            // Outer G — thick gold gradient stroke
            // 12 saatten (üst) → 9 → 6 → 3 saatte (sağ) bitecek şekilde 270°
            // sweep. SwiftUI y-down koordinatta clockwise:true visual olarak
            // saat yönünün TERSİ — gap sağda kalır, stub için yer açar.
            var gPath = Path()
            gPath.addArc(
                center: CGPoint(x: 60, y: 60),
                radius: 48,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: true
            )
            // Inner stub (G's bar)
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

            // Dashed inner arc — film strip detail (G ile aynı yön)
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

// MARK: - Easing helpers

private func clamp01(_ v: CGFloat) -> CGFloat { max(0, min(1, v)) }
private func easeOutCubic(_ t: CGFloat) -> CGFloat { 1 - pow(1 - t, 3) }
private func easeInCubic(_ t: CGFloat) -> CGFloat { t * t * t }
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
