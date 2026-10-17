//
//  FocusTimerView.swift
//  boringNotch
//

import Defaults
import SwiftUI

struct FocusTimerView: View {
    @ObservedObject private var timer = FocusTimerManager.shared

    private var tint: Color {
        timer.phase == .focus ? Color.effectiveAccent : .green
    }

    var body: some View {
        HStack(spacing: 24) {
            ring
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timer.phase.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(sessionsText)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                HStack(spacing: 10) {
                    controlButton(
                        systemImage: timer.isRunning ? "pause.fill" : "play.fill",
                        prominent: true
                    ) { timer.toggle() }
                    controlButton(systemImage: "arrow.counterclockwise") { timer.reset() }
                    controlButton(systemImage: "forward.end.fill") { timer.skip() }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { timer.applyDurationChange() }
    }

    private var sessionsText: String {
        let count = timer.completedSessions
        return count == 1 ? "1 session completed" : "\(count) sessions completed"
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 7)
            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: timer.progress)
            Text(timer.formattedRemaining)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .frame(width: 104, height: 104)
    }

    private func controlButton(
        systemImage: String,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(prominent ? Color.black : Color.white)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(prominent ? Color.white : Color.white.opacity(0.14))
                )
                .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
