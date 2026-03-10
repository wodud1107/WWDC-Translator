//
//  ContentView.swift
//  WWDC-Translator
//
//  Created by 김재영 on 3/9/26.
//

import SwiftUI
import WebKit
import Translation

struct ContentView: View {
    @State private var year: String = ""
    @State private var sessionNumber: String = ""
    
    @State private var page = WebPage()
    @State private var isExtracting: Bool = false
    @State private var translationProgress: Double = 0.0
    
    @State private var translationConfig: TranslationSession.Configuration?
    
    // 추출 및 번역된 데이터
    @State private var m3u8URL: String?
    @State private var subtitles: [Subtitle] = []
    
    @State private var isShowingPlayer: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        TextField("WWDC 연도", text: $year)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                        
                        TextField("세션 번호", text: $sessionNumber)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                        
                        Button("이동") {
                            goToSession()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(year.isEmpty || sessionNumber.isEmpty)
                    }
                    
                    // 번역 진행률 표시
                    if isExtracting && translationProgress > 0 {
                        ProgressView(value: translationProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                            .padding(.horizontal)
                    }
                }
                .padding()
                #if os(macOS)
                .background(Color(NSColor.windowBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
                .shadow(radius: 2)
                .zIndex(1)
                
                WebView(page)
                    .ignoresSafeArea(edges: .bottom)
            }
            
            if let currentURL = page.url, currentURL.absoluteString.contains("play") && !isShowingPlayer {
                Button {
                    prepareTranslation()
                } label: {
                    HStack {
                        if isExtracting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                                .padding(.trailing, 4)
                            Text(translationProgress > 0 ? "시스템 번역 중..." : "데이터 추출 중...")
                        } else {
                            Image(systemName: "captions.bubble.fill")
                            Text("한국어 자막으로 보기")
                        }
                    }
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(isExtracting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 4, x: 0, y: 2)
                }
                .padding(20)
                .buttonStyle(.plain)
                .disabled(isExtracting)
                .transition(.scale.combined(with: .opacity))
            }
            #if os(macOS)
            if isShowingPlayer {
                playerView
                    .background(Color.black)
                    .transition(.move(edge: .bottom))
                    .zIndex(10) // 최상단에 배치
            }
            #endif
        }
        .onAppear {
            if let initialURL = URL(string: "https://developer.apple.com/videos/") {
                page.load(initialURL)
            }
        }
        // 시스템 번역 태스크 등록 (translationConfig가 설정되면 자동으로 실행됨)
        .translationTask(translationConfig) { session in
            do {
                try await performSystemTranslation(with: session)
            } catch {
                print("❌ 시스템 번역 에러: \(error)")
                await MainActor.run { isExtracting = false }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $isShowingPlayer) {
            playerView
        }
        #endif
    }
    
    // 번역 완료 후 비디오 URL을 이용한 플레이어 실행
    @ViewBuilder
    private var playerView: some View {
        if let urlString = m3u8URL, let videoURL = URL(string: urlString) {
            VideoPlayerView(videoURL: videoURL, subtitles: subtitles)
        } else {
            ContentUnavailableView("비디오 주소를 찾을 수 없습니다.", systemImage: "video.slash")
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isShowingPlayer = false
                    }
                }
        }
    }
    
    private func goToSession() {
        let sessionURLString = "https://developer.apple.com/videos/play/wwdc\(year)/\(sessionNumber)/"
        if let newURL = URL(string: sessionURLString) {
            page.load(newURL)
            self.m3u8URL = nil
            self.subtitles = []
            self.translationProgress = 0
            self.translationConfig = nil
        }
    }
    
    // 1단계: 자막 데이터 추출 및 시스템 번역 트리거
    private func prepareTranslation() {
        isExtracting = true
        translationProgress = 0
        
        Task {
            let dataScript = """
            var metaVideo = document.querySelector('meta[property="og:video"]');
            var m3u8 = metaVideo ? metaVideo.content : "";
            
            var sentences = document.querySelectorAll('#transcript-content .sentence, .supplement.transcript .sentence, .sentence');
            var out = "";
            for (var i = 0; i < sentences.length; i++) {
                var s = sentences[i];
                var timeSpan = s.querySelector('[data-start]');
                var start = timeSpan ? timeSpan.getAttribute('data-start') : (s.getAttribute('data-start-time') || "0");
                out += start + "|" + s.textContent.trim() + "@@@";
            }
            return m3u8 + "###" + out;
            """
            
            do {
                let result = try await page.callJavaScript(dataScript)
                guard let rawString = result as? String, !rawString.isEmpty else { 
                    await MainActor.run { isExtracting = false }
                    return 
                }
                
                let components = rawString.components(separatedBy: "###")
                let videoURL = components.first == "" ? nil : components.first
                
                if components.count > 1 && !components[1].isEmpty {
                    let lines = components[1].components(separatedBy: "@@@")
                    var newSubtitles: [Subtitle] = []
                    
                    for line in lines where !line.isEmpty {
                        let parts = line.components(separatedBy: "|")
                        if parts.count == 2 {
                            newSubtitles.append(Subtitle(startTime: Double(parts[0]) ?? 0.0, endTime: 0.0, text: parts[1]))
                        }
                    }
                    
                    for i in 0..<newSubtitles.count {
                        newSubtitles[i].endTime = (i < newSubtitles.count - 1) ? newSubtitles[i+1].startTime : newSubtitles[i].startTime + 3.0
                    }
                    
                    await MainActor.run {
                        self.m3u8URL = videoURL
                        self.subtitles = newSubtitles
                        self.translationProgress = 0.1 // 번역 시작 신호
                        
                        // 시스템 번역 세션 구성
                        if self.translationConfig == nil {
                            self.translationConfig = .init(source: Locale.Language(identifier: "en"),
                                                         target: Locale.Language(identifier: "ko"))
                        } else {
                            // 이미 존재할 경우 무효화 후 재설정하여 task 재실행
                            let old = self.translationConfig
                            self.translationConfig = nil
                            self.translationConfig = old
                        }
                    }
                } else {
                    await MainActor.run { isExtracting = false }
                }
            } catch {
                print("❌ 스크립트 실행 에러: \(error)")
                await MainActor.run { isExtracting = false }
            }
        }
    }
    
    // 2단계: 시스템 번역 세션을 통한 실제 번역
    private func performSystemTranslation(with session: TranslationSession) async throws {
        let totalCount = subtitles.count
        guard totalCount > 0 else { return }
        
        // 시스템 번역은 배열 요청 시 순서와 싱크 일치를 완벽히 보장함
        let requests: [TranslationSession.Request] = subtitles.enumerated().map { (index, subtitle) in
            TranslationSession.Request(sourceText: subtitle.text, clientIdentifier: "\(index)")
        }
        
        let translatedResults = try await session.translations(from: requests)
        
        await MainActor.run {
            for result in translatedResults {
                if let indexString = result.clientIdentifier, let index = Int(indexString) {
                    subtitles[index].translatedText = result.targetText
                }
            }
            self.translationProgress = 1.0
            self.isExtracting = false
            self.isShowingPlayer = true
        }
    }
}

#Preview {
    ContentView()
}
