//
//  Subtitle.swift
//  WWDC-Translator
//
//  Created by 김재영 on 3/10/26.
//

import Foundation

struct Subtitle: Identifiable, Codable {
    var id = UUID()
    let startTime: Double
    var endTime: Double
    let text: String
    var translatedText: String? = nil
}
