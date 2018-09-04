//
//  StackScrollView.swift
//  YouTubeScrollView
//
//  Created by 寺家 篤史 on 2018/08/31.
//  Copyright © 2018年 Yumemi Inc. All rights reserved.
//

import UIKit
import SnapKit

protocol StackScrollViewDelegate: class {
    func stackScrollViewDidSelectedPreviousContent(_ stackScrollView: StackScrollView)
    func stackScrollViewDidSelectedNextContent(_ stackScrollView: StackScrollView)
    func stackScrollView(_ stackScrollView: StackScrollView, willScrollFromIndex index: Int)
    func stackScrollView(_ stackScrollView: StackScrollView, didScrollToIndex index: Int)
}

final class StackScrollView: UIView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let leadingBlindView = StackScrollBlindView()
    private let trailingBlindView = StackScrollBlindView()
    weak var delegate: StackScrollViewDelegate?
    var pageIndex: Int = 0 {
        didSet {
            updateContentViews()
        }
    }
    var nextPageIndex: Int {
        return pageIndex < (contentViews.count - 1) ? pageIndex + 1 : contentViews.count - 1
    }
    var currentContentView: UIView {
        guard let arrangedSubview = stackView.arrangedSubviews[1] as? StackScrollArrangedSubview,
            let contentView = arrangedSubview.contentView else {
                fatalError()
        }
        return contentView
    }
    var currentIndex: Int {
        return contentViews.index(of: currentContentView) ?? NSNotFound
    }
    var isScrollEnabled: Bool {
        get {
            return scrollView.isScrollEnabled
        }
        set {
            scrollView.isScrollEnabled = newValue
        }
    }
    private var isAnimating: Bool = false
    // スクロール表示領域に表示されていないと前/次の動画内容がレンダリングされないため、左右に1pxはみ出すように配置する
    let arrangedInsets = UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
    var contentSize: CGSize = .zero {
        didSet {
            stackView.arrangedSubviews.forEach(stackView.removeArrangedSubview)
            (0..<3).forEach { _ in
                let subview = StackScrollArrangedSubview(frame: .zero)
                subview.contentSize = contentSize
                stackView.addArrangedSubview(subview)
            }
            
            scrollView.snp.updateConstraints { (make) in
                make.size.equalTo(contentSize)
            }
            updateContentViews()
        }
    }
    var contentViews: [UIView] = [] {
        didSet {
            updateContentViews()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = false
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        addSubview(scrollView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        scrollView.addSubview(stackView)
        
        leadingBlindView.translatesAutoresizingMaskIntoConstraints = false
        leadingBlindView.gradientColors = [UIColor.black, UIColor.black.withAlphaComponent(0.15)]
        leadingBlindView.addTarget(self, action: #selector(leadingBlindViewSelected(sender:)), for: .touchUpInside)
        addSubview(leadingBlindView)
        
        trailingBlindView.translatesAutoresizingMaskIntoConstraints = false
        trailingBlindView.gradientColors = [UIColor.black.withAlphaComponent(0.15), UIColor.black]
        trailingBlindView.addTarget(self, action: #selector(trailingBlindViewSelected(sender:)), for: .touchUpInside)
        addSubview(trailingBlindView)
        
        scrollView.snp.makeConstraints { (make) in
            make.size.equalTo(contentSize)
            make.center.equalToSuperview()
        }
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        leadingBlindView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(scrollView)
            make.leading.equalToSuperview().priority(.high)
            make.width.equalTo(200).priority(.low)
            make.trailing.equalTo(scrollView.snp.leading).inset(arrangedInsets.left)
        }
        trailingBlindView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(scrollView)
            make.trailing.equalToSuperview().priority(.high)
            make.width.equalTo(200).priority(.low)
            make.leading.equalTo(scrollView.snp.trailing).inset(arrangedInsets.right)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func scrollToPreviousPage(animated: Bool) {
        if isAnimating { return }
        
        isAnimating = true
        delegate?.stackScrollView(self, willScrollFromIndex: currentIndex)
        let scrollIndex = Int(scrollView.contentOffset.x / contentSize.width) - 1
        scrollView.scrollToPageIndex(scrollIndex, animated: animated)
    }

    func scrollToNextPage(animated: Bool) {
        if isAnimating { return }
        
        isAnimating = true
        delegate?.stackScrollView(self, willScrollFromIndex: currentIndex)
        let scrollIndex = Int(scrollView.contentOffset.x / contentSize.width) + 1
        scrollView.scrollToPageIndex(scrollIndex, animated: animated)
    }

    @objc private func leadingBlindViewSelected(sender: StackScrollBlindView) {
        delegate?.stackScrollViewDidSelectedPreviousContent(self)
    }

    @objc private func trailingBlindViewSelected(sender: StackScrollBlindView) {
        delegate?.stackScrollViewDidSelectedNextContent(self)
    }

    private func updateContentViews() {
        if contentViews.count == 0 { return }
        
        contentViews.forEach { $0.removeFromSuperview() }
        // stackView.arrangedSubviews に[index-1, index, index+1]が表示されるようにする
        stackView.arrangedSubviews.enumerated().forEach { (index, arrangedSubview) in
            guard let view = arrangedSubview as? StackScrollArrangedSubview else { return }
            
            var contentIndex: Int = 0
            switch index {
            case 0:
                contentIndex = pageIndex - 1
            case 1:
                contentIndex = pageIndex
            case 2:
                contentIndex = pageIndex + 1
            default:
                fatalError()
            }
            if contentIndex >= contentViews.count {
                contentIndex = contentIndex - contentViews.count
            }else if contentIndex <= -1 {
                contentIndex = contentViews.count + contentIndex
            }
            view.contentView = contentViews[contentIndex]
        }
        layoutIfNeeded()
        scrollView.contentOffset.x = contentSize.width
    }

    private func willBeginScroll() {
        delegate?.stackScrollView(self, willScrollFromIndex: currentIndex)
    }

    private func didEndScroll() {
        let contentOffset = scrollView.contentOffset
        if contentOffset.x > contentSize.width {
            pageIndex = (pageIndex + 1) < contentViews.count ? (pageIndex + 1) : 0
        } else if contentOffset.x < contentSize.width {
            pageIndex = (pageIndex - 1) >= 0 ? (pageIndex - 1) : (contentViews.count - 1)
        }
        delegate?.stackScrollView(self, didScrollToIndex: currentIndex)
    }
}

extension StackScrollView: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            isUserInteractionEnabled =  false
            return
        }
        
        didEndScroll()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserInteractionEnabled = true
        didEndScroll()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isAnimating = false
        didEndScroll()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        willBeginScroll()
    }
}

private class StackScrollArrangedSubview: UIView {
    var contentSize: CGSize = .zero
    var contentView: UIView? {
        didSet {
            if let contentView = contentView {
                addSubview(contentView)
                contentView.snp.makeConstraints({ (make) in
                    make.center.equalToSuperview()
                })
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return contentSize
    }
}

private class StackScrollBlindView: UIControl {
    private let gradientLayer = CAGradientLayer()
    var gradientColors: [UIColor] = [] {
        didSet {
            gradientLayer.colors = gradientColors.map { $0.cgColor }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.backgroundColor = UIColor.clear.cgColor
        gradientLayer.startPoint = .zero
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0)
        layer.addSublayer(gradientLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

extension UIScrollView {
    func scrollToPageIndex(_ index: Int, animated: Bool) {
        let offset = CGPoint(x: frame.width * CGFloat(index), y: 0)
        setContentOffset(offset, animated: animated)
    }
}

