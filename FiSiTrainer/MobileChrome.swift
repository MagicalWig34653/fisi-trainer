// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import SwiftUI

/// The one primary "check" or "continue" action of the current exercise. Touch devices pin it above
/// the tab bar so it never scrolls out of reach; the Mac keeps the button inline with its Return key.
struct PinnedAction {
    let title: String
    let isDisabled: Bool
    let action: () -> Void
}

struct PinnedActionKey: PreferenceKey {
    static var defaultValue: PinnedAction? { nil }

    static func reduce(value: inout PinnedAction?, nextValue: () -> PinnedAction?) {
        if let next = nextValue() { value = next }
    }
}

/// Inline button on the Mac, pinned bottom action on iPhone and iPad (see `PinnedActionBar`).
struct FlowButton<Style: ButtonStyle>: View {
    let title: String
    var isDisabled = false
    let style: Style
    let action: () -> Void

    var body: some View {
        #if os(macOS)
        Button(title, action: action)
            .buttonStyle(style)
            .keyboardShortcut(.return, modifiers: [])
            .disabled(isDisabled)
        #else
        Color.clear
            .frame(height: 0)
            .preference(key: PinnedActionKey.self,
                        value: PinnedAction(title: title, isDisabled: isDisabled, action: action))
        #endif
    }
}

extension View {
    /// Liquid Glass on iOS 26 and newer; a material or solid tint everywhere else.
    @ViewBuilder
    func glassSurface<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            glassEffect(Self.makeGlass(tint: tint, interactive: interactive), in: shape)
        } else if let tint {
            background(tint, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
        #else
        if let tint {
            background(tint, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
        #endif
    }

    /// Lets the iOS 26 tab bar shrink while scrolling down; earlier systems keep the standard bar.
    @ViewBuilder
    func minimizesTabBarOnScroll() -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Success or error haptic when an answer is revealed. Touch devices only; the Mac stays silent.
    func answerFeedback<T: Equatable>(trigger: T, outcome: @escaping (T) -> Bool?) -> some View {
        #if os(iOS)
        sensoryFeedback(trigger: trigger) { _, new in
            guard let correct = outcome(new) else { return nil }
            return correct ? SensoryFeedback.success : SensoryFeedback.error
        }
        #else
        self
        #endif
    }

    #if os(iOS)
    @available(iOS 26.0, *)
    private static func makeGlass(tint: Color?, interactive: Bool) -> Glass {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return glass
    }
    #endif
}
