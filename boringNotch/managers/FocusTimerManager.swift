//
//  FocusTimerManager.swift
//  boringNotch
//
//  Pomodoro-style focus timer that keeps running while the notch is closed.
//

import AppKit
import Combine
import Defaults

@MainActor
final class FocusTimerManager: ObservableObject {
    static let shared = FocusTimerManager()

    enum Phase {
        case focus
        case rest

        var title: String {
            switch self {
            case .focus: return "Focus"
            case .rest: return "Break"
            }
        }
    }

    @Published private(set) var phase: Phase = .focus
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning = false
    @Published private(set) var completedSessions = 0

    private var endDate: Date?
    private var timer: Timer?
    /// True while the current phase has not been started or modified, so duration changes in settings apply.
    private var isPristine = true

    private init() {
        remaining = TimeInterval(Defaults[.focusDurationMinutes] * 60)
    }

    // MARK: - Derived values

    var totalDuration: TimeInterval {
        switch phase {
        case .focus: return TimeInterval(max(1, Defaults[.focusDurationMinutes]) * 60)
        case .rest: return TimeInterval(max(1, Defaults[.breakDurationMinutes]) * 60)
        }
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / totalDuration))
    }

    var formattedRemaining: String {
        let seconds = Int(remaining.rounded(.up))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Controls

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        isPristine = false
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        let newTimer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func pause() {
        guard isRunning else { return }
        if let endDate {
            remaining = max(0, endDate.timeIntervalSinceNow)
        }
        stopTimer()
    }

    func reset() {
        stopTimer()
        isPristine = true
        remaining = totalDuration
    }

    /// Jump to the next phase without counting the current one as completed.
    func skip() {
        stopTimer()
        advancePhase(countSession: false)
    }

    /// Call after the user changes durations in settings.
    func applyDurationChange() {
        guard !isRunning, isPristine else { return }
        remaining = totalDuration
    }

    // MARK: - Internals

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
    }

    private func tick() {
        guard isRunning, let endDate else { return }
        let left = max(0, endDate.timeIntervalSinceNow)
        // Only publish when the displayed second changes.
        if Int(left.rounded(.up)) != Int(remaining.rounded(.up)) || left == 0 {
            remaining = left
        }
        if left <= 0 {
            finishPhase()
        }
    }

    private func finishPhase() {
        stopTimer()
        if Defaults[.focusSoundEnabled] {
            NSSound(named: NSSound.Name("Glass"))?.play()
        }
        advancePhase(countSession: phase == .focus)
    }

    private func advancePhase(countSession: Bool) {
        if countSession { completedSessions += 1 }
        phase = (phase == .focus) ? .rest : .focus
        isPristine = true
        remaining = totalDuration
    }
}
