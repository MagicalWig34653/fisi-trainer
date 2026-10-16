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

// MARK: - Transitions

/// Fade-and-lift used when a page, question or result replaces another. Reduce Motion keeps only the fade.
private struct ContentSwap<ID: Hashable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let id: ID

    func body(content: Content) -> some View {
        content
            .id(id)
            .transition(reduceMotion
                        ? AnyTransition.opacity
                        : AnyTransition.asymmetric(
                            insertion: AnyTransition.opacity.combined(with: AnyTransition.offset(x: 0, y: 14)),
                            removal: AnyTransition.opacity))
    }
}

/// Animates the swap announced by `contentSwap` when `value` changes; off with Reduce Motion.
private struct SwapAnimation<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: value)
    }
}

extension View {
    /// Gives the view a new identity (and a fade-and-lift transition) whenever `id` changes.
    func contentSwap<ID: Hashable>(_ id: ID) -> some View {
        modifier(ContentSwap(id: id))
    }

    /// Put on the container of `contentSwap` views, with the value that triggers the swap.
    func swapAnimation<Value: Equatable>(_ value: Value) -> some View {
        modifier(SwapAnimation(value: value))
    }

    /// Light tap haptic on touch devices only.
    func tapFeedback<T: Equatable>(trigger: T) -> some View {
        #if os(iOS)
        sensoryFeedback(.impact(weight: .light), trigger: trigger)
        #else
        self
        #endif
    }
}

// MARK: - Pet buttons

private enum PetButtonColors {
    static let accent = Color(red: 0.76, green: 0.97, blue: 0.32)
    static let dark = Color(red: 0.035, green: 0.063, blue: 0.095)
    static let primary = Color(red: 0.94, green: 0.97, blue: 0.96)
}

/// Capsule button for pet actions: tinted when `prominent`, glass on iOS 26, springy press feedback.
struct PetPillStyle: ButtonStyle {
    var prominent = false
    var small = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: small ? 12 : 14, weight: .semibold))
            .foregroundStyle(prominent ? PetButtonColors.dark : PetButtonColors.primary)
            .padding(.horizontal, small ? 12 : 18)
            .frame(minHeight: isTouchDevice ? 44 : (small ? 32 : 38))
            .background(Capsule().fill(Color.white.opacity(prominent ? 0 : 0.06)))
            .glassSurface(in: Capsule(), tint: prominent ? PetButtonColors.accent : nil, interactive: true)
            .overlay(Capsule().strokeBorder(Color.white.opacity(prominent ? 0 : 0.10)))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Square-ish tile with an icon above its label, used for petting, feeding and playing.
struct PetTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(PetButtonColors.primary)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(shape.fill(Color.white.opacity(0.06)))
            .glassSurface(in: shape, interactive: true)
            .overlay(shape.strokeBorder(Color.white.opacity(0.10)))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
