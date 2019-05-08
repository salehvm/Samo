//
//  CoolTextView.swift
//  Samo
//
//  Created by Saleh Majıdov on 5/8/19.
//  Copyright © 2019 Saleh Majıdov. All rights reserved.
//

import Foundation
import UIKit
import PureLayout

extension CoolTextView {
    var placeholder: String? {
        get {
            return placeholderLabel.text
        }
        set {
            placeholderLabel.text = newValue
        }
    }
    var text: String? {
        get {
            return textView.text
        }
        set {
            textView.text = newValue
        }
    }
}

class CoolTextView: UIView {
    
    var onTextChange: (String) -> () = {_ in }
    var onEndEditing: (String) -> () = {_ in }
    
    var textView: UITextView!
    var placeholderLabel: UILabel!
    
    private var placeholderLabelWidthConstraint: NSLayoutConstraint!
    
    private static let kTopLabelHeight: CGFloat = 20
    static let kGapBetweenLabels: CGFloat = -5
    static let kBottomLabelHeight: CGFloat = 28
    private static let kEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    private static let kAnimationDuration: TimeInterval = 0.3
    
    fileprivate enum TextViewState {
        case noText(Bool)
        case enteredText(Bool)
    }
    
    private var state: TextViewState = .noText(false)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        seputAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupViews()
        seputAppearance()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updatePlaceholderWidth(for: state)
        updatePlaceholderTransform(for: state)
    }
    
    func setColors(text: UIColor, placeholder: UIColor) {
        setColors(text: text, placeholder: placeholder, cursor: text)
    }
    
    func setColors(text: UIColor, placeholder: UIColor, cursor: UIColor) {
        textView.textColor = text
        textView.tintColor = cursor
        placeholderLabel.textColor = placeholder
    }
    
    // MARK: - Private
    private var bottomLabelTopInset: CGFloat {
        return CoolTextView.kEdgeInsets.top + CoolTextView.kTopLabelHeight + CoolTextView.kGapBetweenLabels
    }
    
    private var constHeight: CGFloat {
        let insets = CoolTextView.kEdgeInsets
        return insets.top + CoolTextView.kTopLabelHeight + CoolTextView.kGapBetweenLabels + CoolTextView.kBottomLabelHeight + insets.bottom
    }
    
    private var bottomLabelEdgeInsets: UIEdgeInsets {
        let insets = CoolTextView.kEdgeInsets
        return UIEdgeInsets(top: bottomLabelTopInset,
                            left: insets.left,
                            bottom: insets.bottom,
                            right: insets.right)
    }
    
    private var bottomLabelFrame: CGRect {
        let insets = bottomLabelEdgeInsets
        let frame = bounds
        return CGRect(x: insets.left,
                      y: insets.top,
                      width: frame.size.width - (insets.left + insets.right),
                      height: frame.size.height - (insets.top + insets.bottom))
    }
    
    private var topLabelFrame: CGRect {
        let insets = CoolTextView.kEdgeInsets
        let labelWidth = frame.size.width - (insets.left + insets.right)
        return CGRect(x: insets.left,
                      y: insets.top,
                      width: labelWidth,
                      height: CoolTextView.kTopLabelHeight)
    }
    
    private func setupViews() {
        // correct height
        NSLayoutConstraint.autoSetPriority(UILayoutPriority(rawValue: 999)) {
            autoSetDimension(.height, toSize: constHeight)
        }
        let frame = bottomLabelFrame
        
        // setup placeholder label
        placeholderLabel = UILabel(frame: frame)
        
        // add without constraints to avoid transformation conflicts
        addSubview(placeholderLabel)
        let bottomInsets = bottomLabelEdgeInsets
        placeholderLabel.autoPinEdge(toSuperviewEdge: .top, withInset: bottomInsets.top)
        placeholderLabel.autoPinEdge(toSuperviewEdge: .left, withInset: bottomInsets.left)
        let width = bottomLabelFrame.size.width
        placeholderLabelWidthConstraint = placeholderLabel.autoSetDimension(.width, toSize: width)
        
        // setup text view
        textView = UITextView(frame: frame)
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        fill(with: textView, withEdgeInsets: bottomInsets)
        textView.delegate = self
    }
    
    private func seputAppearance() {
        placeholderLabel.textColor = UIColor.black
        placeholderLabel.font = UIFont.textField
        placeholderLabel.text = "Click here"
        backgroundColor = .clear
    }
    
    // MARK: - Animation
    fileprivate func setState(_ state: TextViewState) {
        var shouldAnimate: Bool
        var isWidthFirst: Bool = true
        switch state {
        case .noText(let animated):
            if case .noText = self.state {
                return
            }
            shouldAnimate = animated
            isWidthFirst = false
        case .enteredText(let animated):
            if case .enteredText = self.state {
                return
            }
            shouldAnimate = animated
            isWidthFirst = true
        }
        
        let widthBlock = { [unowned self] in
            UIView.animate(withDuration: 0) { [unowned self] in
                self.updatePlaceholderWidth(for: state)
            }
        }
        
        let transrormBlock = { [unowned self] in
            self.state = state
            self.updatePlaceholderTransform(for: state)
        }
        
        if isWidthFirst {
            widthBlock()
        }
        
        if !shouldAnimate {
            transrormBlock()
        } else {
            UIView.animate(withDuration: CoolTextView.kAnimationDuration,
                           animations: transrormBlock,
                           completion:
                { [unowned self] (succeeded) in
                    if !isWidthFirst {
                        widthBlock()
                    }
                    // mark that animation is completed
                    switch self.state {
                    case .noText:
                        self.state = .noText(false)
                    case .enteredText:
                        self.state = .enteredText(false)
                    }
            })
        }
    }
    
    private func updatePlaceholderTransform(for state: TextViewState) {
        placeholderLabel.transform = placeholderTransform(for: state)
    }
    
    private func updatePlaceholderWidth(for state: TextViewState) {
        placeholderLabelWidthConstraint.constant = placeholderWidth(for: state)
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
    }
    
    private func placeholderTransform(for state: TextViewState) -> CGAffineTransform {
        var transform: CGAffineTransform
        switch state {
        case .noText:
            transform = noTextPlaceholderTransform
        case .enteredText:
            transform = enteredTextPlaceholderTransform
        }
        return transform
    }
    
    private func placeholderWidth(for state: TextViewState) -> CGFloat {
        var width: CGFloat
        switch state {
        case .noText:
            width = noTextPlaceholderWidth
        case .enteredText:
            width = enteredPlaceholderWidth
        }
        return width
    }
    
    private var enteredPlaceholderWidth: CGFloat {
        let scale: CGFloat = CoolTextView.kTopLabelHeight / CoolTextView.kBottomLabelHeight
        let standardWidth = bottomLabelFrame.size.width
        return standardWidth / scale
    }
    
    private var noTextPlaceholderWidth: CGFloat {
        return bottomLabelFrame.size.width
    }
    
    private var enteredTextPlaceholderTransform: CGAffineTransform {
        let scale: CGFloat = CoolTextView.kTopLabelHeight / CoolTextView.kBottomLabelHeight
        let upShift: CGFloat = -(CoolTextView.kTopLabelHeight + CoolTextView.kGapBetweenLabels)
        let leftShift: CGFloat = (1 - 1 / scale) * bottomLabelFrame.size.width / 2
        
        return placeholderLabel.transformFromTransformWith(scale: scale,
                                                           verticalShift: upShift,
                                                           horizontalShift: leftShift)
    }
    
    private var noTextPlaceholderTransform: CGAffineTransform {
        return placeholderLabel.transformFromTransformWith(scale: 1, verticalShift: 0, horizontalShift: 0)
    }
}

extension CoolTextView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        onTextChange(textView.text)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        guard let text = textView.text else {
            setState(.enteredText(true))
            return
        }
        if text.count == 0 {
            setState(.enteredText(true))
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard let text = textView.text else {
            setState(.noText(true))
            return
        }
        onEndEditing(text)
        if text.count == 0 {
            setState(.noText(true))
        }
    }
}

extension UIView {
    func transformFromTransformWith(scale: CGFloat,
                                    verticalShift: CGFloat,
                                    horizontalShift: CGFloat) -> CGAffineTransform {
        return CGAffineTransform(a: scale,
                                 b: transform.b,
                                 c: transform.c,
                                 d: scale,
                                 tx: horizontalShift,
                                 ty: verticalShift)
    }
    
    public func fill(with view: UIView, withEdgeInsets insets: UIEdgeInsets = UIEdgeInsets.zero) {
        addSubview(view)
        var viewInsets = insets
        if self is UIScrollView {
            viewInsets.top += self.bounds.origin.y
            view.autoMatch(.width, to: .width, of: self)
            view.autoMatch(.height, to: .height, of: self)
        }
        view.autoPinEdgesToSuperviewEdges(with: viewInsets)
    }
    
    
}

extension UIFont {
    static var textField: UIFont {
        return UIFont.systemFont(ofSize: 14)
    }
}

