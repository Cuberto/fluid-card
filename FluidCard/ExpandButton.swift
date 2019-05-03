//
//  ExpandButton.swift
//  FluidCard
//
//  Created by Anton Skopin on 03/05/2019.
//  Copyright © 2019 Cuberto. All rights reserved.
//

import UIKit

class ExpandButton: UIButton {

    let size: CGFloat = 52.0

    override var intrinsicContentSize: CGSize {
        return CGSize(width: size, height: size)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    let markView = UIView()

    private func configure() {
        layer.cornerRadius = 19.0
        backgroundColor = .white
        layer.shadowColor = UIColor.black.withAlphaComponent(0.14) .cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 17
        translatesAutoresizingMaskIntoConstraints = false

        let markSize = CGSize(width: 12, height: 6)
        let cLayer = CAShapeLayer()
        let path = UIBezierPath()
        cLayer.frame = CGRect(origin: .zero, size: markSize)
        path.move(to:.zero)
        path.addLine(to: CGPoint(x: markSize.width/2.0, y: markSize.height))
        path.addLine(to: CGPoint(x: markSize.width, y: 0))
        cLayer.lineWidth = 2.0
        cLayer.fillColor = nil
        cLayer.strokeColor = UIColor.black.cgColor
        cLayer.path = path.cgPath
        markView.translatesAutoresizingMaskIntoConstraints = false
        markView.isUserInteractionEnabled = false
        markView.backgroundColor = .clear
        addSubview(markView)
        markView.layer.addSublayer(cLayer)
        NSLayoutConstraint.activate([
            markView.widthAnchor.constraint(equalToConstant: markSize.width),
            markView.heightAnchor.constraint(equalToConstant: markSize.height),
            markView.centerXAnchor.constraint(equalTo: centerXAnchor),
            markView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

