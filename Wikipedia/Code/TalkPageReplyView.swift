//
//  TalkPageUpdateView.swift
//  Wikipedia
//
//  Created by Toni Sevener on 5/15/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import UIKit

protocol TalkPageReplyViewDelegate: class {
     func textDidChange()
     var collectionViewFrame: CGRect { get }
}

class TalkPageReplyView: UIView {
    
    lazy private var composeTextView: ThemeableTextView = ThemeableTextView.init()
    lazy private var finePrintTextView: UITextView = UITextView.init()
    
    weak var delegate: TalkPageReplyViewDelegate?
    
    private var theme: Theme?
    
    private var licenseTitleTextViewAttributedString: NSAttributedString {
        
        //since this is just colors it shouldn't affect sizing
        let colorTheme = theme ?? Theme.light
        
        let localizedString = WMFLocalizedString("talk-page-publish-terms-and-licenses", value: "By saving changes, you agree to the %1$@Terms of Use%2$@, and agree to release your contribution under the %3$@CC BY-SA 3.0%4$@ and the %5$@GFDL%6$@ licenses.", comment: "Text for information about the Terms of Use and edit licenses on talk pages. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting, %5$@ - app-specific non-text formatting,  %6$@ - app-specific non-text formatting.") //todo: gfd or gfdl?
        
        let substitutedString = String.localizedStringWithFormat(
            localizedString,
            "<a href=\"\(Licenses.saveTermsURL?.absoluteString ?? "")\">",
            "</a>",
            "<a href=\"\(Licenses.CCBYSA3URL?.absoluteString ?? "")\">",
            "</a>" ,
            "<a href=\"\(Licenses.GFDLURL?.absoluteString ?? "")\">",
            "</a>"
        )
        
        let attributedString = substitutedString.byAttributingHTML(with: .caption1, boldWeight: .regular, matching: traitCollection, withBoldedString: nil, color: colorTheme.colors.secondaryText, linkColor: colorTheme.colors.link, tagMapping: nil, additionalTagAttributes: nil)
        
        return attributedString
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(composeTextView)
        composeTextView.isUnderlined = false
        composeTextView.isScrollEnabled = false
        composeTextView.placeholderDelegate = self
        composeTextView.placeholder = WMFLocalizedString("talk-page-new-reply-body-placeholder-text", value: "Compose response", comment: "Placeholder text which appears initially in the new reply field for talk pages.")
        addSubview(finePrintTextView)
        finePrintTextView.isScrollEnabled = false
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString
    }
    
    func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left + 7, bottom: layoutMargins.bottom, right: layoutMargins.right + 7)
        let composeTextViewOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let composeTextViewWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let finePrintTextViewOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let finePrintTextViewWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let finePrintFrame = finePrintTextView.wmf_preferredFrame(at: finePrintTextViewOrigin, maximumWidth: finePrintTextViewWidth, minimumWidth: finePrintTextViewWidth, alignedBy: semanticContentAttribute, apply: false) //will apply below
        
        let forcedComposeHeight = (delegate?.collectionViewFrame.size ?? size).height * 0.5 - finePrintFrame.height
        
        let composeTextViewFrame = CGRect(x: composeTextViewOrigin.x, y: composeTextViewOrigin.y, width: composeTextViewWidth, height: forcedComposeHeight)
        
        if (apply) {
            composeTextView.frame = composeTextViewFrame
            finePrintTextView.frame = CGRect(x: adjustedMargins.left, y: composeTextViewFrame.minY + composeTextViewFrame.height, width: finePrintTextViewWidth, height: finePrintFrame.height)
        }
        
        let finalHeight = adjustedMargins.top + composeTextViewFrame.size.height + finePrintFrame.height + adjustedMargins.bottom
        return CGSize(width: size.width, height: finalHeight)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size, apply: false)
    }
    
    // MARK - Dynamic Type
    // Only applies new fonts if the content size category changes
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        maybeUpdateFonts(with: traitCollection)
    }
    
    var contentSizeCategory: UIContentSizeCategory?
    fileprivate func maybeUpdateFonts(with traitCollection: UITraitCollection) {
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.wmf_preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        composeTextView.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        finePrintTextView.attributedText = licenseTitleTextViewAttributedString
    }
}

extension TalkPageReplyView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        composeTextView.apply(theme: theme)
        backgroundColor = theme.colors.paperBackground
        finePrintTextView.backgroundColor = theme.colors.paperBackground
        finePrintTextView.textColor = theme.colors.secondaryText
    }
}

extension TalkPageReplyView: ThemeableTextViewPlaceholderDelegate {
    func themeableTextViewPlaceholderDidHide(_ themeableTextView: UITextView, isPlaceholderHidden: Bool) {
        //no-op
    }
    
    func themeableTextViewDidChange(_ themeableTextView: UITextView) {
        delegate?.textDidChange()
    }
}
