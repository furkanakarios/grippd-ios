import SwiftUI

struct GlowBorderButton: View {
    let title: String
    let action: () -> Void

    private let colors: [Color] = [
        Color(red: 0.91, green: 0.70, blue: 0.29),
        Color(red: 1.00, green: 0.88, blue: 0.45),
        Color(red: 0.95, green: 0.58, blue: 0.12),
        Color(red: 1.00, green: 0.78, blue: 0.20),
        Color(red: 0.80, green: 0.50, blue: 0.10),
        Color(red: 1.00, green: 0.92, blue: 0.55),
        Color(red: 0.91, green: 0.70, blue: 0.29),
    ]

    private let cycleDuration: Double = 3.5

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let rotation = (elapsed.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration) * 360

            Button(action: action) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        AngularGradient(colors: colors, center: .center, angle: .degrees(rotation))
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        ZStack {
                            AngularGradient(colors: colors, center: .center, angle: .degrees(rotation))
                                .blur(radius: 8)
                            RoundedRectangle(cornerRadius: GrippdTheme.Radius.md)
                                .fill(Color(red: 0.07, green: 0.07, blue: 0.07))
                                .padding(2.5)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: GrippdTheme.Radius.md))
            }
            .buttonStyle(.plain)
        }
    }
}
