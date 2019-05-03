//
//  FluidCardView.swift
//  FluidCard
//
//  Created by Anton Skopin on 03/05/2019.
//  Copyright © 2019 Cuberto. All rights reserved.
//

import UIKit

@IBDesignable
class FluidCardView: UIView {

    var expandDuration: TimeInterval = 0.6
    var collapseDuration: TimeInterval = 0.35

    private let cornerRadius: CGFloat = 20.0
    private var collapsedHeight: CGFloat {
        return topHeight + 51.0
    }
    private var expandedHeight: CGFloat {
        return topHeight + gap + bottomHeight
    }
    private var topHeight: CGFloat = 264
    private var gap: CGFloat = 47
    private var bottomHeight: CGFloat = 134
    private var contentWidth: CGFloat = 295
    private var topContentInset: CGFloat = 32
    private var bottomContentInset: CGFloat = 10

    private lazy var displayLink: CADisplayLink = CADisplayLink(target: self, selector: #selector(screenUpdate))

    private lazy var topView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.backgroundColor = #colorLiteral(red: 0.3725490196, green: 0.01568627451, blue: 1, alpha: 1)
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = cornerRadius
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.backgroundColor = #colorLiteral(red: 0.3725490196, green: 0.01568627451, blue: 1, alpha: 1)
        return view
    }()

    private lazy var overlay: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.3725490196, green: 0.01568627451, blue: 1, alpha: 1)
        view.layer.cornerRadius = cornerRadius
        view.isHidden = true
        return view
    }()

    var topContentView: UIView = UIView() {
        didSet {
            oldValue.removeFromSuperview()
            configureTopContent()
        }
    }
    var bottomContentView: UIView  = UIView() {
        didSet {
            oldValue.removeFromSuperview()
            configureBottomContent()
        }
    }

    private lazy var btnExpand: ExpandButton = ExpandButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private(set) var isExpanded: Bool = false
    private var csBottomCollapsed: NSLayoutConstraint!
    private var csBottomExpanded: NSLayoutConstraint!

    private func configureTopContent() {
        topContentView.translatesAutoresizingMaskIntoConstraints = false
        let size = CGSize(width: max(topContentInset * 4, bounds.width), height: topContentInset * 2)
        topHeight = topContentView.systemLayoutSizeFitting(size,
                                                           withHorizontalFittingPriority: .required,
                                                           verticalFittingPriority: .defaultLow).height
        topHeight += 2 * topContentInset
        addSubview(topContentView)
        NSLayoutConstraint.activate([
            topContentView.topAnchor.constraint(equalTo: topView.topAnchor, constant: topContentInset),
            topContentView.leadingAnchor.constraint(equalTo: topView.leadingAnchor, constant: topContentInset),
            topContentView.trailingAnchor.constraint(equalTo: topView.trailingAnchor, constant: -topContentInset),
            topContentView.bottomAnchor.constraint(equalTo: topView.bottomAnchor, constant: -topContentInset),
            topContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: topContentInset * 4)
        ])
    }

    private func configureBottomContent() {
        bottomContentView.translatesAutoresizingMaskIntoConstraints = false
        let size = CGSize(width: max(bottomContentInset * 4, bounds.width), height: bottomContentInset * 2)
        bottomHeight = bottomContentView.systemLayoutSizeFitting(size,
                                                                 withHorizontalFittingPriority: .required,
                                                                 verticalFittingPriority: .defaultLow).height
        bottomHeight += 2 * bottomContentInset
        let csBottomExpanded = bottomView.heightAnchor.constraint(equalToConstant: bottomHeight)
        if self.csBottomExpanded.isActive {
            self.csBottomExpanded.isActive = false
        }
        self.csBottomExpanded = csBottomExpanded
        if isExpanded && !expanding {
            addSubview(bottomContentView)
            NSLayoutConstraint.activate([
                bottomContentView.topAnchor.constraint(equalTo: bottomView.topAnchor, constant: bottomContentInset),
                bottomContentView.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: bottomContentInset),
                bottomContentView.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -bottomContentInset),
                csBottomExpanded
            ])
        }
    }

    private func configure() {
        [bottomView, topView, btnExpand].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(bottomView)
        addSubview(topView)
        addSubview(overlay)
        addSubview(btnExpand)
        btnExpand.addTarget(self, action: #selector(bntExpandPressed), for: .touchUpInside)
        csBottomCollapsed = bottomView.topAnchor.constraint(equalTo: topView.bottomAnchor)
        csBottomExpanded = bottomView.heightAnchor.constraint(equalToConstant: bottomHeight)
        let csDefaultTopHeight = topView.heightAnchor.constraint(equalToConstant: topHeight)
        csDefaultTopHeight.priority = .defaultLow
        NSLayoutConstraint.activate([
            topView.topAnchor.constraint(equalTo: topAnchor),
            topView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: bottomAnchor),
            btnExpand.centerXAnchor.constraint(equalTo: centerXAnchor),
            btnExpand.centerYAnchor.constraint(equalTo: topView.bottomAnchor),
            csBottomCollapsed,
            csDefaultTopHeight
        ])
    }

    @objc private func bntExpandPressed() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: contentWidth, height: isExpanded ? expandedHeight : collapsedHeight)
    }

    private var layoutWidth: CGFloat = 0
    override func layoutSubviews() {
        guard !expanding, !collapsing else { return }
        super.layoutSubviews()
        guard abs(bounds.width - layoutWidth) > 0.001 else { return }
        layoutWidth = bounds.width
        configureBottomContent()
        configureTopContent()
    }

    private var progress: CGFloat = 0

    private var animationStart: TimeInterval = CACurrentMediaTime()
    private var expanding: Bool = false
    private var collapsing: Bool = false

    func collapse() {
        guard isExpanded, !expanding, !collapsing else { return }
        isExpanded = false
        collapsing = true
        animationStart = CACurrentMediaTime()
        displayLink.add(to: .current, forMode: .common)
        animateDirection(from: -CGFloat.pi, to: 0, duration: collapseDuration)
    }

    private var expandStartHeight: CGFloat = 0
    func expand() {
        guard !isExpanded, !expanding, !collapsing else { return }
        isExpanded = true
        expanding = true
        collapseOverlayShown = false
        expandStartHeight = bounds.height
        overlay.frame = CGRect(x: 0, y: topView.frame.minY, width: bounds.width, height: bottomView.frame.maxY)
        overlay.layer.mask = nil
        overlay.isHidden = false
        topView.layer.maskedCorners = .all
        bottomView.layer.maskedCorners = .all
        topView.isHidden = true
        bottomView.isHidden = true
        bottomContentView.alpha = 0.0
        overlay.addSubview(bottomContentView)
        animationStart = CACurrentMediaTime()
        displayLink.add(to: .current, forMode: .common)

        animateDirection(from: 0, to: -CGFloat.pi, duration: expandDuration * 0.7)
    }

    private func animateDirection(from: CGFloat, to: CGFloat, duration: TimeInterval) {
        let rotateAnim = CABasicAnimation(keyPath: "transform.rotation.z")
        rotateAnim.fromValue = from
        rotateAnim.toValue = to
        rotateAnim.fillMode = .forwards
        rotateAnim.isRemovedOnCompletion = false
        rotateAnim.duration = duration
        btnExpand.markView.layer.add(rotateAnim, forKey: "rotation")
    }

    @objc private func screenUpdate() {
        if expanding {
            expandUpdate()
        } else if collapsing {
            collapseUpdate()
        }
    }

    var collapseOverlayShown: Bool = false

    var bottomContentConstaints: [NSLayoutConstraint]?

    private func collapseUpdate() {
        let tf = TimingFunction(timingParameters: UICubicTimingParameters.init(animationCurve: .easeInOut))
        let timeProgress = min(1.0, max(0.0, CGFloat((CACurrentMediaTime() - animationStart) / collapseDuration)))
        progress = tf.progress(at: timeProgress)
        defer {
            if progress >= 1 {
                displayLink.remove(from: .current, forMode: .common)
                topView.isHidden = false
                bottomView.isHidden = false
                overlay.isHidden = true
                collapsing = false
                csBottomExpanded.isActive = false
                csBottomCollapsed.isActive = true
                invalidateIntrinsicContentSize()
                setNeedsLayout()
                superview?.layoutIfNeeded()
            }
        }
        let gapProgress = max(0, min(1, progress/0.7))
        let curveProgress = max(0, min(1, (progress - 0.4)/0.4))
        let shrinkProgress = max(0, min(1, (progress - 0.7)/0.3))
        let opacityProgress = max(0, min(1, progress/0.4))

        let gap = (expandedHeight - topHeight - bottomHeight) * (1 - gapProgress)
        var bottomHeight = self.bottomHeight
        if shrinkProgress > 0 {
            let diff = bottomHeight - (collapsedHeight - topHeight)
            bottomHeight -= diff * shrinkProgress
        }
        bottomView.frame = CGRect(x: 0,
                                  y: topHeight + gap,
                                  width: bounds.width,
                                  height: bottomHeight)
        bottomContentView.alpha = (1.0 - opacityProgress)

        if curveProgress > 0 {
            if !collapseOverlayShown {
                topView.isHidden = true
                bottomView.isHidden = true
                topView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                bottomView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                bottomContentView.removeFromSuperview()
                overlay.isHidden = false
            }
            overlay.frame = CGRect(x: 0, y: topView.frame.minY, width: bounds.width, height: bottomView.frame.maxY)

            let cornerRadius: CGFloat = 20
            let curveOffset: CGFloat = cornerRadius / 4.0 * (1 - curveProgress)

            let pt1 = CGPoint(x: bounds.width, y: topView.frame.maxY).offsetBy(dy: -cornerRadius)
            let pt2 = CGPoint(x: bounds.width - curveOffset, y: (topView.frame.maxY + bottomView.frame.minY) / 2.0)
            let pt3 = CGPoint(x: bounds.width, y: bottomView.frame.minY).offsetBy(dy: cornerRadius)
            let pt5 = CGPoint(x: 0, y: bottomView.frame.minY).offsetBy(dy: cornerRadius)
            let pt6 = CGPoint(x: curveOffset, y: (topView.frame.maxY + bottomView.frame.minY) / 2.0)
            let pt7 = CGPoint(x: 0, y: topView.frame.maxY).offsetBy(dy: -cornerRadius)

            let path = UIBezierPath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: bounds.width, y: 0))
            path.addLine(to: pt1)
            path.addCurve(to: pt2,
                          controlPoint1: pt1.offsetBy(dy: cornerRadius/2.0 + 1),
                          controlPoint2: pt2.offsetBy(dy: -gap * 1.5 * sin(CGFloat.pi/2.0 * curveProgress)))

            path.addCurve(to: pt3,
                          controlPoint1: pt2.offsetBy(dy: gap * 1.5 * sin(CGFloat.pi/2.0 * curveProgress)),
                          controlPoint2: pt3.offsetBy(dy:  -cornerRadius/2.0 - 1))
            path.addLine(to: CGPoint(x: bounds.width, y: bottomView.frame.maxY))
            path.addLine(to: CGPoint(x: 0, y: bottomView.frame.maxY))
            path.addLine(to: pt5)
            path.addCurve(to: pt6,
                          controlPoint1: pt5.offsetBy(dy: -cornerRadius/2.0 - 1),
                          controlPoint2: pt6.offsetBy(dy: gap * 1.5  * sin(CGFloat.pi/2.0 * curveProgress)))
            path.addCurve(to: pt7,
                          controlPoint1: pt6.offsetBy(dy: -gap * 1.5  * sin(CGFloat.pi/2.0 * curveProgress)),
                          controlPoint2: pt7.offsetBy(dy: cornerRadius/2.0 + 1))
            path.addLine(to: .zero)
            let maskLayer = CAShapeLayer()
            maskLayer.fillRule = .evenOdd
            maskLayer.path = path.cgPath
            overlay.layer.mask = maskLayer
        }
    }

    private func expandUpdate() {
        let tf = TimingFunction(timingParameters: UICubicTimingParameters.init(animationCurve: .easeInOut))
        let timeProgress = min(1.0, max(0.0, CGFloat((CACurrentMediaTime() - animationStart) / expandDuration)))
        progress = tf.progress(at: timeProgress)
        defer {
            if progress >= 1 {
                displayLink.remove(from: .current, forMode: .common)
                topView.isHidden = false
                bottomView.isHidden = false
                overlay.isHidden = true
                expanding = false
                csBottomCollapsed.isActive = false
                csBottomExpanded.isActive = true
                addSubview(bottomContentView)
                configureBottomContent()
                invalidateIntrinsicContentSize()
                setNeedsLayout()
                superview?.layoutIfNeeded()
            }
        }

        let easeIn = TimingFunction(timingParameters: UICubicTimingParameters.init(animationCurve: .easeIn))
        let easeOut = TimingFunction(timingParameters: UICubicTimingParameters.init(animationCurve: .easeOut))

        let holeProgress: CGFloat = easeIn.progress(at: max(0.0, min(1.0, (progress - 0.15)/0.5)))
        let borderProgress: CGFloat = easeOut.progress(at: max(0.0, min(1.0, (progress - 0.3)/0.5)))
        let collapseProgress = easeOut.progress(at: max(0, min(1.0, (progress - 0.65)/0.35)))
        let dCollapseProgress = min(1.0, 2 * collapseProgress)
        let gapProgress = pow((-abs(progress - 0.8) + 0.8)/0.6, 1.2)
        let topProgress = (progress < 0.7 ? progress / 0.7 : -(progress - 1) / 0.3)
        let opacityProgress = max(0.0, min(1.0, (progress - 0.3)/0.6))

        let gap = (expandedHeight - topHeight - bottomHeight) * gapProgress
        let topOffset = 10 * topProgress
        let bHeight = (expandStartHeight - topHeight) + (bottomHeight - (expandStartHeight - topHeight)) * progress
        bottomView.frame = CGRect(x: 0,
                                  y: topHeight + gap,
                                  width: bounds.width,
                                  height: bHeight)
        topView.frame = CGRect(x: 0,
                               y: topOffset,
                               width: bounds.width,
                               height: topHeight)

        if let css = bottomContentConstaints {
            NSLayoutConstraint.deactivate(css)
        }
        bottomContentView.alpha = opacityProgress
        let css: [NSLayoutConstraint] = [
            bottomContentView.widthAnchor.constraint(equalTo: widthAnchor, constant: -2 * bottomContentInset),
            bottomContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant:  bottomContentInset),
            bottomContentView.topAnchor.constraint(equalTo: topAnchor, constant: bottomView.frame.minY + bottomContentInset)
        ]
        NSLayoutConstraint.activate(css)
        bottomContentConstaints = css


        let cornerRadius: CGFloat = 20
        let rightCurveOffsetMultiplier: CGFloat = 1.0
        let leftCurveOffsetMultiplier: CGFloat = 1.8
        let curveOffset = (cornerRadius) * progress / 1.2

        let pt1 = CGPoint(x: bounds.width, y: topView.frame.maxY).offsetBy(dy: -cornerRadius)
        let pt2 = CGPoint(x: bounds.width - curveOffset, y: topView.frame.maxY)
        let pt3 = CGPoint(x: bounds.width - curveOffset, y: bottomView.frame.minY)
        let pt4 = CGPoint(x: bounds.width, y: bottomView.frame.minY).offsetBy(dy: cornerRadius)
        let pt5 = CGPoint(x: 0, y: bottomView.frame.minY).offsetBy(dy: cornerRadius)
        let pt6 = CGPoint(x: curveOffset, y: bottomView.frame.minY)
        let pt7 = CGPoint(x: curveOffset, y: topView.frame.maxY)
        let pt8 = CGPoint(x: 0, y: topView.frame.maxY).offsetBy(dy: -cornerRadius)

        let hole1CenterX = bounds.width - 38
        let maxX: CGFloat = 10.0
        let xOffset = 4 + maxX * holeProgress
        let tOffset: CGFloat = 8 * (1 - holeProgress)
        var h1tl = CGPoint(x: hole1CenterX - xOffset, y: pt2.y + tOffset)
        var h1tr = CGPoint(x: hole1CenterX + xOffset, y: pt2.y + tOffset)
        var h1br = CGPoint(x: hole1CenterX + xOffset, y: pt3.y - tOffset)
        var h1bl = CGPoint(x: hole1CenterX - xOffset, y: pt3.y - tOffset)

        let hole2XOffset = 16 * holeProgress
        let hole2CenterX: CGFloat = 44
        var h2tl = CGPoint(x: hole2CenterX - hole2XOffset, y: pt7.y + tOffset)
        var h2tr = CGPoint(x: hole2CenterX + hole2XOffset, y: pt7.y + tOffset)
        var h2br = CGPoint(x: hole2CenterX + hole2XOffset, y: pt6.y - tOffset)
        var h2bl = CGPoint(x: hole2CenterX - hole2XOffset, y: pt6.y - tOffset)

        let hole3CenterX: CGFloat = 59
        var h3tl = CGPoint(x: hole3CenterX - xOffset, y: pt7.y + tOffset)
        var h3tr = CGPoint(x: hole3CenterX + xOffset, y: pt7.y + tOffset)
        var h3br = CGPoint(x: hole3CenterX + xOffset, y: pt6.y - tOffset)
        var h3bl = CGPoint(x: hole3CenterX - xOffset, y: pt6.y - tOffset)

        let minOffset: CGFloat = 1.0
        let minDist: CGFloat = 4
        if h3tl.x - h2tr.x < minDist * 2 {
            let mid = (h2tr.x + h3tl.x) / 2.0
            h2tr.x = mid - minDist
            h3tl.x = mid + minDist
            h2br.x = mid - minDist
            h3bl.x = mid + minDist
        }

        let borderOffset = ((hole1CenterX - hole3CenterX) / 2.0 - minDist * 3) * borderProgress
        h1tl.x = min(h1tl.x, hole1CenterX - borderOffset)
        h1bl.x = min(h1bl.x, hole1CenterX - borderOffset)
        h3tr.x = max(h3tr.x, hole3CenterX + borderOffset)
        h3br.x = max(h3br.x, hole3CenterX + borderOffset)

        if collapseProgress > 0 {
            h1tl = h1tl.offsetBy(dy: -(h1tl.y - pt2.y) * collapseProgress)
            h1tr = h1tr.offsetBy(dy: -(h1tr.y - pt2.y) * collapseProgress)
            h1bl = h1bl.offsetBy(dy: (pt3.y - h1bl.y) * collapseProgress)
            h1br = h1br.offsetBy(dy: (pt3.y - h1br.y) * collapseProgress)

            h2tl = h2tl.offsetBy(dy: -(h2tl.y - pt7.y) * collapseProgress)
            h3tl = h3tl.offsetBy(dy: -(h3tl.y - pt7.y) * collapseProgress)

            h2tr = h2tr.offsetBy(dy: -(h2tr.y - pt7.y) * collapseProgress)
            h3tr = h3tr.offsetBy(dy: -(h3tr.y - pt7.y) * collapseProgress)

            h2bl = h2bl.offsetBy(dy: (pt6.y - h2bl.y) * collapseProgress)
            h3bl = h3bl.offsetBy(dy: (pt6.y - h3bl.y) * collapseProgress)

            h2br = h2br.offsetBy(dy: (pt6.y - h2br.y) * collapseProgress)
            h3br = h3br.offsetBy(dy: (pt6.y - h3br.y) * collapseProgress)
        }

        let ch1tl = CGPoint(x: 14, y: 11)
        let ch1tr = CGPoint(x: 10, y: 11)
        let ch1br = CGPoint(x: 12, y: 11)
        let ch1bl = CGPoint(x: 15, y: 11)

        let ch2tl = CGPoint(x: 10, y: 8)
        let ch2tr = CGPoint(x: 12, y: 8)
        let ch2br = CGPoint(x: 14, y: 8)
        let ch2bl = CGPoint(x: 12, y: 8)

        let ch3tl = CGPoint(x: 8, y: 10)
        let ch3tr = CGPoint(x: 12, y: 10)
        let ch3br = CGPoint(x: 9, y: 10)
        let ch3bl = CGPoint(x: 14, y: 10)

        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: bounds.width, y: 0))
        path.addLine(to: pt1)

        if borderProgress >= 1.0 {

            path.addCurve(to: pt2,
                          controlPoint1: pt1.offsetBy(dy: cornerRadius/2.0 + 1),
                          controlPoint2: pt2.offsetBy(dx: curveOffset/3.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: -curveOffset/3.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: h1tr,
                          controlPoint1: pt2.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: h1tr.offsetBy(dx: (minOffset + ch1tr.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                       dy: (minOffset + ch1tr.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: h1tl,
                          controlPoint1: h1tr.offsetBy(dx: -(minOffset + ch1tr.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                       dy: -(minOffset + ch1tr.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: h1tl.offsetBy(dx: (h1tl.x - h3tr.x)/2.0,
                                                       dy: -(minOffset + ch1tl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: h3tr,
                          controlPoint1: h1tl.offsetBy(dx: -(h1tl.x - h3tr.x)/2.0,
                                                       dy: (minOffset + ch1tl.y) * cos(CGFloat.pi/2.0 * collapseProgress)),
                          controlPoint2: h3tr.offsetBy(dx: (h1tl.x - h3tr.x)/2.0,
                                                       dy: (minOffset + ch3tr.y) * cos(CGFloat.pi/2.0 * collapseProgress)))
            path.addCurve(to: h3tl,
                          controlPoint1:  h3tr.offsetBy(dx: -(h1tl.x - h3tr.x)/2.0,
                                                        dy: -(minOffset + ch3tr.y) * cos(CGFloat.pi/2.0 * collapseProgress)),
                          controlPoint2: h3tl.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                       dy: 0))
            path.addCurve(to: h2tr,
                          controlPoint1:  h3tl.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                        dy: 0),
                          controlPoint2: h2tr.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                       dy: 0))
            path.addCurve(to: h2tl,
                          controlPoint1: h2tr.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                       dy: 0),
                          controlPoint2: h2tl.offsetBy(dx: (minOffset + ch2tl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                       dy: -(minOffset + ch2tl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: pt7,
                          controlPoint1: h2tl.offsetBy(dx: -(minOffset + ch2tl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                       dy: (minOffset + ch2tl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: pt7.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: pt8,
                          controlPoint1: pt7.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: pt8.offsetBy(dy: cornerRadius/2.0 + 1))
            path.addLine(to: .zero)

            path.move(to: pt4)
            path.addLine(to: CGPoint(x: bounds.width, y: bottomView.frame.maxY))
            path.addLine(to: CGPoint(x: 0, y: bottomView.frame.maxY))
            path.addLine(to: pt5)

            path.addCurve(to: pt6,
                          controlPoint1: pt5.offsetBy(dy: -cornerRadius/2.0 - 1),
                          controlPoint2: pt6.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: h2bl,
                          controlPoint1: pt6.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: h2bl.offsetBy(dx: -(minOffset + ch2bl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                       dy: -(minOffset + ch2bl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: h2br,
                          controlPoint1:  h2bl.offsetBy(dx: (minOffset + ch2bl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                        dy: (minOffset + ch2bl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: h2br.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                       dy: 0))
            path.addCurve(to: h3bl,
                          controlPoint1:  h2br.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                        dy: 0),
                          controlPoint2: h3bl.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                       dy: 0))
            path.addCurve(to: h3br,
                          controlPoint1:  h3bl.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                        dy: 0),
                          controlPoint2: h3br.offsetBy(dx: -(h1bl.x - h3br.x)/2.0,
                                                       dy: (minOffset + ch3br.y) * cos(CGFloat.pi/2.0 * collapseProgress)))
            path.addCurve(to: h1bl,
                          controlPoint1:  h3br.offsetBy(dx: (h1bl.x - h3br.x)/2.0,
                                                        dy: -(minOffset + ch3br.y) * cos(CGFloat.pi/2.0 * collapseProgress)),
                          controlPoint2: h1bl.offsetBy(dx: -(h1bl.x - h3br.x)/2.0,
                                                       dy: -(minOffset + ch1bl.y) * cos(CGFloat.pi/2.0 * collapseProgress)))
            path.addCurve(to: h1br,
                          controlPoint1: h1bl.offsetBy(dx: (h1bl.x - h3br.x)/2.0,
                                                       dy: (minOffset + ch1bl.y) * cos(CGFloat.pi/2.0 * collapseProgress)),
                          controlPoint2: h1br.offsetBy(dx: -(minOffset + ch1br.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                       dy: (minOffset + ch1br.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: pt3,
                          controlPoint1: h1br.offsetBy(dx: (minOffset + ch1br.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                       dy: -(minOffset + ch1br.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: pt3.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
            path.addCurve(to: pt4,
                          controlPoint1: pt3.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                      dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                          controlPoint2: pt4.offsetBy(dy: -cornerRadius/2.0 - 1))

        } else {
            if holeProgress < 1 {
                let rightOffset = curveOffset * rightCurveOffsetMultiplier
                path.addCurve(to: pt2,
                              controlPoint1: pt1.offsetBy(dy: cornerRadius/2.0 + 1),
                              controlPoint2: pt2.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 * holeProgress)))

                path.addCurve(to: pt3,
                              controlPoint1: pt2.offsetBy(dx: -rightOffset * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: rightOffset * cos(CGFloat.pi/4.0 * holeProgress)),
                              controlPoint2: pt3.offsetBy(dx: -rightOffset * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: -rightOffset * cos(CGFloat.pi/4.0 * holeProgress)))
                path.addCurve(to: pt4,
                              controlPoint1: pt3.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 * holeProgress)),
                              controlPoint2: pt4.offsetBy(dy: -cornerRadius/2.0 - 1))
            } else {

                path.addCurve(to: pt2,
                              controlPoint1: pt1.offsetBy(dy: cornerRadius/2.0 + 1),
                              controlPoint2: pt2.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: h1tr,
                              controlPoint1: pt2.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: h1tr.offsetBy(dx: (minOffset + ch1tr.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: (minOffset + ch1tr.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: h1tl,
                              controlPoint1: h1tr.offsetBy(dx: -(minOffset + ch1tr.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: -(minOffset + ch1tr.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: h1tl.offsetBy(dx: (minOffset + ch1tl.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: -(minOffset + ch1tl.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: h1bl,
                              controlPoint1: h1tl.offsetBy(dx: -(minOffset + ch1tl.x) * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: (minOffset + ch1tr.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: h1bl.offsetBy(dx: -(minOffset + ch1bl.x) * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: -(minOffset + ch1bl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: h1br,
                              controlPoint1: h1bl.offsetBy(dx: (minOffset + ch1bl.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: (minOffset + ch1bl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: h1br.offsetBy(dx: -(minOffset + ch1br.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: (minOffset + ch1br.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: pt3,
                              controlPoint1: h1br.offsetBy(dx: (minOffset + ch1br.x) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                           dy: -(minOffset + ch1br.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: pt3.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: pt4,
                              controlPoint1: pt3.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: pt4.offsetBy(dy: -cornerRadius/2.0 - 1))
            }

            path.addLine(to: CGPoint(x: bounds.width, y: bottomView.frame.maxY))
            path.addLine(to: CGPoint(x: 0, y: bottomView.frame.maxY))
            path.addLine(to: pt5)

            if holeProgress < 1.0 {
                path.addCurve(to: pt6,
                              controlPoint1: pt5.offsetBy(dy: -cornerRadius/2.0 - 1),
                              controlPoint2: pt6.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 * holeProgress)))
                let leftOffset = curveOffset * leftCurveOffsetMultiplier
                path.addCurve(to: pt7,
                              controlPoint1: pt6.offsetBy(dx: leftOffset * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: -leftOffset * cos(CGFloat.pi/4.0 * holeProgress)),
                              controlPoint2: pt7.offsetBy(dx: leftOffset * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: leftOffset * cos(CGFloat.pi/4.0 * holeProgress)))
                path.addCurve(to: pt8,
                              controlPoint1: pt7.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 * holeProgress),
                                                          dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 * holeProgress)),
                              controlPoint2: pt8.offsetBy(dy: cornerRadius/2.0 + 1))
                path.addLine(to: .zero)

                if holeProgress > 0 && holeProgress < 0.3 {
                    let hole2Path = UIBezierPath()
                    hole2Path.move(to: h2tl)
                    hole2Path.addCurve(to: h2tr,
                                       controlPoint1: h2tl.offsetBy(dx: minOffset + ch2tl.x * holeProgress,
                                                                    dy: -(minOffset + ch2tl.y * holeProgress)),
                                       controlPoint2: h2tr.offsetBy(dx: -(minOffset + ch2tr.x * holeProgress),
                                                                    dy: -(minOffset + ch2tr.y * holeProgress)))
                    hole2Path.addCurve(to: h2br,
                                       controlPoint1: h2tr.offsetBy(dx: minOffset + ch2tr.x * holeProgress,
                                                                    dy: minOffset + ch2tr.y * holeProgress),
                                       controlPoint2: h2br.offsetBy(dx: minOffset + ch2br.x * holeProgress,
                                                                    dy: -(minOffset + ch2br.y * holeProgress)))
                    hole2Path.addCurve(to: h2bl,
                                       controlPoint1: h2br.offsetBy(dx: -(minOffset + ch2br.x * holeProgress),
                                                                    dy: minOffset + ch2br.y * holeProgress),
                                       controlPoint2: h2bl.offsetBy(dx: minOffset + ch2bl.x * holeProgress,
                                                                    dy: minOffset + ch2bl.y * holeProgress))
                    hole2Path.addCurve(to: h2tl,
                                       controlPoint1: h2bl.offsetBy(dx: -(minOffset + ch2bl.x * holeProgress),
                                                                    dy: -(minOffset + ch2bl.y * holeProgress)),
                                       controlPoint2: h2tl.offsetBy(dx: -(minOffset + ch2tl.x * holeProgress),
                                                                    dy: minOffset + ch2tl.y * holeProgress))
                    hole2Path.close()
                    path.append(hole2Path)

                    let hole3Path = UIBezierPath()
                    hole3Path.move(to: h3tl)
                    hole3Path.addCurve(to: h3tr,
                                       controlPoint1: h3tl.offsetBy(dx: minOffset + ch3tl.x * holeProgress,
                                                                    dy: -(minOffset + ch3tl.y * holeProgress)),
                                       controlPoint2: h3tr.offsetBy(dx: -(minOffset + ch3tr.x * holeProgress),
                                                                    dy: -(minOffset + ch3tr.y * holeProgress)))
                    hole3Path.addCurve(to: h3br,
                                       controlPoint1: h3tr.offsetBy(dx: minOffset + ch3tr.x * holeProgress,
                                                                    dy: minOffset + ch3tr.y * holeProgress),
                                       controlPoint2: h3br.offsetBy(dx: minOffset + ch3br.x * holeProgress,
                                                                    dy: -(minOffset + ch3br.y * holeProgress)))
                    hole3Path.addCurve(to: h3bl,
                                       controlPoint1: h3br.offsetBy(dx: -(minOffset + ch3br.x * holeProgress),
                                                                    dy: minOffset + ch3br.y * holeProgress),
                                       controlPoint2: h3bl.offsetBy(dx: minOffset + ch3bl.x * holeProgress,
                                                                    dy: minOffset + ch3bl.y * holeProgress))
                    hole3Path.addCurve(to: h3tl,
                                       controlPoint1: h3bl.offsetBy(dx: -(minOffset + ch3bl.x * holeProgress),
                                                                    dy: -(minOffset + ch3bl.y * holeProgress)),
                                       controlPoint2: h3tl.offsetBy(dx: -(minOffset + ch3tl.x * holeProgress),
                                                                    dy: minOffset + ch3tl.y * holeProgress))
                    hole3Path.close()
                    path.append(hole3Path)

                } else if holeProgress > 0 {

                    let hole2Path = UIBezierPath()

                    hole2Path.move(to: h2tl)
                    hole2Path.addCurve(to: h2tr,
                                       controlPoint1: h2tl.offsetBy(dx: minOffset + ch2tl.x * holeProgress,
                                                                    dy: -(minOffset + ch2tl.y * holeProgress)),
                                       controlPoint2: h2tr.offsetBy(dx: -min(minDist, minOffset + ch2tr.x * holeProgress),
                                                                    dy: -(minOffset + ch2tr.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)))
                    hole2Path.addCurve(to: h3tl,
                                       controlPoint1: h2tr.offsetBy(dx: min(minDist, minOffset + ch2tr.x * holeProgress),
                                                                    dy: (minOffset + ch2tr.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)),
                                       controlPoint2: h3tl.offsetBy(dx: -min(minDist, minOffset + ch3tl.x * holeProgress),
                                                                    dy: (minOffset + ch3tl.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)))
                    hole2Path.addCurve(to: h3tr,
                                       controlPoint1: h3tl.offsetBy(dx: min(minDist, minOffset + ch3tl.x * holeProgress),
                                                                    dy: -(minOffset + ch3tl.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)),
                                       controlPoint2: h3tr.offsetBy(dx: -(minOffset + ch3tr.x * holeProgress),
                                                                    dy: -(minOffset + ch3tr.y * holeProgress)))
                    hole2Path.addCurve(to: h3br,
                                       controlPoint1: h3tr.offsetBy(dx: minOffset + ch3tr.x * holeProgress,
                                                                    dy: minOffset + ch3tr.y * holeProgress),
                                       controlPoint2: h3br.offsetBy(dx: minOffset + ch3br.x * holeProgress,
                                                                    dy: -(minOffset + ch3br.y * holeProgress)))
                    hole2Path.addCurve(to: h3bl,
                                       controlPoint1: h3br.offsetBy(dx: -(minOffset + ch3br.x * holeProgress),
                                                                    dy: minOffset + ch3br.y * holeProgress),
                                       controlPoint2: h3bl.offsetBy(dx: min(minDist, minOffset + ch3bl.x * holeProgress),
                                                                    dy: (minOffset + ch3bl.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)))

                    hole2Path.addCurve(to: h2br,
                                       controlPoint1: h3bl.offsetBy(dx: -min(minDist, (minOffset + ch3bl.x * holeProgress)),
                                                                    dy: -(minOffset + ch3bl.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)),
                                       controlPoint2: h2br.offsetBy(dx: min(minDist, minOffset + ch2br.x * holeProgress),
                                                                    dy: -(minOffset + ch2br.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)))
                    hole2Path.addCurve(to: h2bl,
                                       controlPoint1: h2br.offsetBy(dx: -min(minDist, (minOffset + ch2br.x * holeProgress)),
                                                                    dy: (minOffset + ch2br.y * holeProgress) * cos(CGFloat.pi/2.0 * holeProgress)),
                                       controlPoint2: h2bl.offsetBy(dx: minOffset + ch2bl.x * holeProgress,
                                                                    dy: minOffset + ch2bl.y * holeProgress))
                    hole2Path.addCurve(to: h2tl,
                                       controlPoint1: h2bl.offsetBy(dx: -(minOffset + ch2bl.x * holeProgress),
                                                                    dy: -(minOffset + ch2bl.y * holeProgress)),
                                       controlPoint2: h2tl.offsetBy(dx: -(minOffset + ch2tl.x * holeProgress),
                                                                    dy: minOffset + ch2tl.y * holeProgress))
                    hole2Path.close()
                    path.append(hole2Path)
                }
            } else {
                path.addCurve(to: pt6,
                              controlPoint1: pt5.offsetBy(dy: -cornerRadius/2.0 - 1),
                              controlPoint2: pt6.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))

                path.addCurve(to: h2bl,
                              controlPoint1: pt6.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: h2bl.offsetBy(dx: -(minOffset + ch2bl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                           dy: -(minOffset + ch2bl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: h2br,
                              controlPoint1:  h2bl.offsetBy(dx: (minOffset + ch2bl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                            dy: (minOffset + ch2bl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: h2br.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * collapseProgress),
                                                           dy: 0))
                path.addCurve(to: h3bl,
                              controlPoint1:  h2br.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * collapseProgress),
                                                            dy: 0),
                              controlPoint2: h3bl.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                           dy: 0))
                path.addCurve(to: h3br,
                              controlPoint1:  h3bl.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                            dy: 0),
                              controlPoint2: h3br.offsetBy(dx: -(minOffset + ch3br.x),
                                                           dy: (minOffset + ch3br.y)))
                path.addCurve(to: h3tr,
                              controlPoint1:  h3br.offsetBy(dx: (minOffset + ch3br.x),
                                                            dy: -(minOffset + ch3br.y)),
                              controlPoint2: h3tr.offsetBy(dx: (minOffset + ch3tr.x),
                                                           dy: (minOffset + ch3tr.y)))
                path.addCurve(to: h3tl,
                              controlPoint1:  h3tr.offsetBy(dx: -(minOffset + ch3tr.x),
                                                            dy: -(minOffset + ch3tr.y)),
                              controlPoint2: h3tl.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                           dy: 0))
                path.addCurve(to: h2tr,
                              controlPoint1:  h3tl.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                            dy:0),
                              controlPoint2: h2tr.offsetBy(dx: minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                           dy: 0))
                path.addCurve(to: h2tl,
                              controlPoint1: h2tr.offsetBy(dx: -minDist * cos(CGFloat.pi/2.0 * dCollapseProgress),
                                                           dy: 0),
                              controlPoint2: h2tl.offsetBy(dx: (minOffset + ch2tl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                           dy: -(minOffset + ch2tl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: pt7,
                              controlPoint1: h2tl.offsetBy(dx: -(minOffset + ch2tl.x) * cos(CGFloat.pi/2.0 * collapseProgress),
                                                           dy: (minOffset + ch2tl.y) * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: pt7.offsetBy(dx: curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)))
                path.addCurve(to: pt8,
                              controlPoint1: pt7.offsetBy(dx: -curveOffset/2.0 * sin(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress),
                                                          dy: -curveOffset/2.0 * cos(CGFloat.pi/4.0 + CGFloat.pi/4.0 * collapseProgress)),
                              controlPoint2: pt8.offsetBy(dy: cornerRadius/2.0 + 1))
                path.addLine(to: .zero)
            }

            if holeProgress > 0 && holeProgress < 1 {
                let holePath = UIBezierPath()
                holePath.move(to: h1tl)

                holePath.addCurve(to: h1tr,
                                  controlPoint1: h1tl.offsetBy(dx: minOffset + ch1tl.x * holeProgress,
                                                               dy: -(minOffset + ch1tl.y * holeProgress)),
                                  controlPoint2: h1tr.offsetBy(dx: -(minOffset + ch1tr.x * holeProgress),
                                                               dy: -(minOffset + ch1tr.y * holeProgress)))
                holePath.addCurve(to: h1br,
                                  controlPoint1: h1tr.offsetBy(dx: minOffset + ch1tr.x * holeProgress,
                                                               dy: minOffset + ch1tr.y * holeProgress),
                                  controlPoint2: h1br.offsetBy(dx: minOffset + ch1br.x * holeProgress,
                                                               dy: -(minOffset + ch1br.y * holeProgress)))
                holePath.addCurve(to: h1bl,
                                  controlPoint1: h1br.offsetBy(dx: -(minOffset + ch1br.x * holeProgress),
                                                               dy: minOffset + ch1br.y * holeProgress),
                                  controlPoint2: h1bl.offsetBy(dx: minOffset + ch1bl.x * holeProgress,
                                                               dy: minOffset + ch1bl.y * holeProgress))
                holePath.addCurve(to: h1tl,
                                  controlPoint1: h1bl.offsetBy(dx: -(minOffset + ch1bl.x * holeProgress),
                                                               dy: -(minOffset + ch1bl.y * holeProgress)),
                                  controlPoint2: h1tl.offsetBy(dx: -(minOffset + ch1tl.x * holeProgress),
                                                               dy: minOffset + ch1tl.y * holeProgress))
                holePath.close()
                path.append(holePath)
            }
        }
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path.cgPath
        overlay.layer.mask = maskLayer
        overlay.frame = CGRect(x: 0, y: topView.frame.minY, width: bounds.width, height: bottomView.frame.maxY)
    }

}
