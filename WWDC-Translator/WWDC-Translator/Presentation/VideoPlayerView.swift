//
//  VideoPlayerView.swift
//  WWDC-Translator
//
//  Created by 김재영 on 3/10/26.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    let subtitles: [Subtitle]
    @Environment(\.dismiss) var dismiss
    
    @State private var player = AVPlayer()
    @State private var currentTime: Double = 0.0
    
    // 현재 시간에 맞는 자막 찾기
    private var currentSubtitle: String? {
        subtitles.first(where: { currentTime >= $0.startTime && currentTime < $0.endTime })?.translatedText
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VideoPlayer(player: player)
                .onAppear {
                    player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                    player.play()
                    
                    // 재생 시간 트래킹 (0.1초 단위)
                    player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
                        self.currentTime = time.seconds
                    }
                }
            
            // 자막 오버레이
            if let text = currentSubtitle {
                VStack {
                    Spacer()
                    Text(text)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.bottom, 50)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 30)
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .edgesIgnoringSafeArea(.all)
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        #endif
        .overlay(alignment: .topLeading) {
            Button {
                player.pause()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VideoPlayerView(videoURL: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2016/416k7f0xkmz28rvlvwb/416/hls_vod_mvp.m3u8")!, subtitles: [])
}
