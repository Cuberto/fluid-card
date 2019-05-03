/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
//  UnitBezier.swift
//
//  Created by tcldr on 04/11/2018.
//  https://github.com/tcldr
//
//  Ported from Apple's WebKit code base:
//  http://svn.webkit.org/repository/webkit/trunk/Source/WebCore/platform/graphics/UnitBezier.h
//

import CoreGraphics

public struct UnitBezier {

    // MARK: - Properties

    private let ax: CGFloat
    private let bx: CGFloat
    private let cx: CGFloat

    private let ay: CGFloat
    private let by: CGFloat
    private let cy: CGFloat

    // MARK: - Initialiser

    public init(controlPoint1: CGPoint, controlPoint2: CGPoint) {

        // Calculate the polynomial coefficients, implicit first
        // and last control points are (0,0) and (1,1).

        cx = 3.0 * controlPoint1.x
        bx = 3.0 * (controlPoint2.x - controlPoint1.x) - cx
        ax = 1.0 - cx - bx

        cy = 3.0 * controlPoint1.y
        by = 3.0 * (controlPoint2.y - controlPoint1.y) - cy
        ay = 1.0 - cy - by
    }

    // MARK: - Methods

    func value(for x: CGFloat, epsilon: CGFloat) -> CGFloat {
        return sampleCurveY(solveCurveX(x, epsilon: epsilon))
    }

    func sampleCurveX(_ t: CGFloat) -> CGFloat {
        // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
        return ((ax * t + bx) * t + cx) * t
    }

    func sampleCurveY(_ t: CGFloat) -> CGFloat {
        return ((ay * t + by) * t + cy) * t
    }

    func sampleCurveDerivativeX(_ t: CGFloat) -> CGFloat {
        return (3.0 * ax * t + 2.0 * bx) * t + cx
    }

    // Given an x value, find a parametric value it came from.
    func solveCurveX(_ x: CGFloat, epsilon: CGFloat) -> CGFloat {
        var t0, t1, t2, x2, d2: CGFloat

        // First try a few iterations of Newton's method -- normally very fast.

        t2 = x
        for _ in (0..<8) {
            x2 = sampleCurveX(t2) - x
            guard abs(x2) >= epsilon else { return t2 }
            d2 = sampleCurveDerivativeX(t2)
            guard abs(d2) >= 1e-6 else { break }
            t2 = t2 - x2 / d2
        }

        // Fall back to the bisection method for reliability.

        t0 = 0.0
        t1 = 1.0
        t2 = x

        guard t2 >= t0 else { return t0 }
        guard t2 <= t1 else { return t1 }

        while t0 < t1 {

            x2 = sampleCurveX(t2)

            guard abs(x2 - x) >= epsilon else { return t2 }

            if x > x2 {
                t0 = t2
            } else {
                t1 = t2
            }

            t2 = (t1 - t0) * 0.5 + t0
        }

        // Failure

        return t2
    }
}
