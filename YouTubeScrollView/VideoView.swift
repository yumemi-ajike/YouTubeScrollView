//
//  VideoView.swift
//  YouTubeScrollView
//
//  Created by 寺家 篤史 on 2018/08/31.
//  Copyright © 2018年 Yumemi Inc. All rights reserved.
//

import UIKit
import YoutubeKit

protocol VideoViewDelegate: class {
    func videoViewDidEndPlaying(_ videoView: VideoView)
}

enum VideoViewState {
    case playing, paused
}

final class VideoView: UIView {
    private let videoID: String
    private var player: YTSwiftyPlayer!
    weak var delegate: VideoViewDelegate?
    var contentSize: CGSize = .zero {
        didSet {
            snp.updateConstraints { (make) in
                make.size.equalTo(contentSize)
            }
            player.snp.updateConstraints { (make) in
                make.size.equalTo(contentSize)
            }
        }
    }
    var isPlaying: Bool {
        return player.playerState == .playing
    }
    private let actionView = UIControl()

    init(videoID: String, contentSize: CGSize) {
        self.videoID = videoID
        self.contentSize = contentSize
        super.init(frame: .zero)
        backgroundColor = .white
        
        let parameters: [VideoEmbedParameter] = [.videoID(videoID),
                                                 .showControls(.hidden),
                                                 .showRelatedVideo(false),
                                                 .showInfo(false)]
        player = YTSwiftyPlayer(frame: .zero, playerVars: parameters)
        player.isUserInteractionEnabled = false
        player.delegate = self
        addSubview(player)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(actionViewTapped(sender:)))
        actionView.addGestureRecognizer(tapGestureRecognizer)
        addSubview(actionView)

        snp.makeConstraints { (make) in
            make.size.equalTo(contentSize)
        }
        player.snp.makeConstraints { (make) in
            make.size.equalTo(contentSize)
            make.center.equalToSuperview()
        }
        actionView.snp.makeConstraints { (make) in
            make.size.equalTo(contentSize)
            make.center.equalToSuperview()
        }
        player.loadPlayer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        if player.playerState == .playing { return }
        
        player.playVideo()
    }

    func pause() {
        player.pauseVideo()
    }

    func seekToBegining() {
        player.seek(to: 0, allowSeekAhead: true)
    }

    @objc private func actionViewTapped(sender: UITapGestureRecognizer) {
        if player.playerState == .playing {
            pause()
        } else {
            play()
        }
    }
}

extension VideoView: YTSwiftyPlayerDelegate {
    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState) {
        if state == .ended {
            delegate?.videoViewDidEndPlaying(self)
            pause()
            seekToBegining()
        }
    }
    
    func player(_ player: YTSwiftyPlayer, didChangeQuality quality: YTSwiftyVideoQuality) {
        
    }
    
    func player(_ player: YTSwiftyPlayer, didReceiveError error: YTSwiftyPlayerError) {
        
    }
    
    func player(_ player: YTSwiftyPlayer, didUpdateCurrentTime currentTime: Double) {
        
    }
    
    func player(_ player: YTSwiftyPlayer, didChangePlaybackRate playbackRate: Double) {
        
    }
    
    func playerReady(_ player: YTSwiftyPlayer) {
        
    }
    
    func apiDidChange(_ player: YTSwiftyPlayer) {
        
    }
    
    func youtubeIframeAPIReady(_ player: YTSwiftyPlayer) {
        
    }
    
    func youtubeIframeAPIFailedToLoad(_ player: YTSwiftyPlayer) {
        
    }
}
