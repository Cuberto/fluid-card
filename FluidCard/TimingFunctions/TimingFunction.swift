//
//  TimingFunction.swift
//
//  Created by tcldr on 04/11/2018.
//  https://github.com/tcldr
//  Copyright © 2018 tcldr.
//
//  Permission is hereby granted, free of charge,
//  to any person obtaining a copy of this software and
//  associated documentation files (the "Software"), to
//  deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify,
//  merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom
//  the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice
//  shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

/// A cubic Bézier timing curve consists of a line whose starting point is (0, 0),
/// whose end point is (1, 1), and whose shape is defined by two control points.
/// The slope of the line at each point in time defines the speed of progress
/// at that time.
///
/// Usage:
/// ```
///
/// let params = UICubicTimingParameters(animationCurve: .easeIn)
/// let tf = TimingFunction(timingParameters: params)
/// tf.progress(at: 0.00) // returns 0.0
/// tf.progress(at: 0.25) // returns ~0.093
/// tf.progress(at: 0.50) // returns ~0.315
/// tf.progress(at: 0.75) // returns ~0.621
/// tf.progress(at: 1.00) // returns 1.0
///
/// ```
public struct TimingFunction {

    // MARK: - Properties

    var controlPoint1: CGPoint {
        didSet { updateUnitBezier() }
    }

    var controlPoint2: CGPoint {
        didSet { updateUnitBezier() }
    }

    var duration: CGFloat {
        didSet { updateEpsilon() }
    }

    // MARK: - Private Properties

    private var unitBezier: UnitBezier
    private var epsilon: CGFloat

    // MARK: - Initialiser

    public init(controlPoint1: CGPoint, controlPoint2: CGPoint, duration: CGFloat = 1.0) {
        self.controlPoint1 = controlPoint1
        self.controlPoint2 = controlPoint2
        self.duration = duration
        self.unitBezier = .init(controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        self.epsilon = TimingFunction.epsilon(for: duration)
    }

    // MARK: - Public API

    /// Returns the progress along the timing function for the given time (`fractionComplete`)
    /// with `0.0` equal to the start of the curve, and `1.0` equal to the end of the curve
    func progress(at fractionComplete: CGFloat) -> CGFloat {
        return unitBezier.value(for: fractionComplete, epsilon: epsilon)
    }

    // MARK: - Private helpers

    mutating private func updateUnitBezier() {
        unitBezier = UnitBezier(controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }

    mutating private func updateEpsilon() {
        epsilon = TimingFunction.epsilon(for: duration)
    }
}

// MARK: - Static methods

private extension TimingFunction {
    static func epsilon(for duration: CGFloat) -> CGFloat {
        return CGFloat(1.0 / (200.0 * duration))
    }
}

// MARK: - Platform specific extensions

#if canImport(UIKit)

import UIKit

public extension TimingFunction {
    init(timingParameters: UICubicTimingParameters, duration: CGFloat = 1.0) {
        self.init(
            controlPoint1: timingParameters.controlPoint1,
            controlPoint2: timingParameters.controlPoint2,
            duration: duration
        )
    }
}

#endif
