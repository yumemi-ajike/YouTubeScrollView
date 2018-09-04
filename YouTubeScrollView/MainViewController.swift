//
//  MainViewController.swift
//  YouTubeScrollView
//
//  Created by 寺家 篤史 on 2018/08/31.
//  Copyright © 2018年 Yumemi Inc. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    lazy private var videoIDs: [String] = {
        return NSArray(contentsOf: Bundle.main.url(forResource: "VideoIDs", withExtension: "plist")!) as! [String]
    }()
    private let stackScrollView = StackScrollView()
    let initialPageIndex: Int = 0
    var videoViews: [VideoView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        let contentSize = CGSize(width: 800, height: 600)
        stackScrollView.contentSize = contentSize
        stackScrollView.delegate = self
        view.addSubview(stackScrollView)
        
        stackScrollView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(stackScrollView.contentSize.height).priority(.low)
            make.centerY.equalToSuperview()
        }

        let arrangedInsets = stackScrollView.arrangedInsets
        videoIDs.enumerated().forEach { (index, videoID) in
            // スクロール表示領域に表示されていないと前/次の動画内容がレンダリングされないため、左右に1pxはみ出すように配置する
            let contentSize = CGSize(width: contentSize.width + arrangedInsets.left + arrangedInsets.right, height: contentSize.height)
            let videoView = VideoView(videoID: videoID, contentSize: contentSize)
            videoViews.append(videoView)
        }
        stackScrollView.pageIndex = initialPageIndex
        stackScrollView.contentViews = videoViews
    }
}

extension MainViewController: StackScrollViewDelegate {
    func stackScrollViewDidSelectedPreviousContent(_ stackScrollView: StackScrollView) {
        stackScrollView.scrollToPreviousPage(animated: true)
    }
    
    func stackScrollViewDidSelectedNextContent(_ stackScrollView: StackScrollView) {
        stackScrollView.scrollToNextPage(animated: true)
    }
    
    func stackScrollView(_ stackScrollView: StackScrollView, willScrollFromIndex index: Int) {
        let videoView = videoViews[index]
        videoView.pause()
        videoView.seekToBegining()
    }
    
    func stackScrollView(_ stackScrollView: StackScrollView, didScrollToIndex index: Int) {
        let videoView = videoViews[index]
        videoView.play()
    }
}
