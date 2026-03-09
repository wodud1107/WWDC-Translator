//
//  DeepLServiceTests.swift
//  WWDC-Translator
//
//  Created by 김재영 on 3/9/26.
//

import XCTest
@testable import WWDC_Translator

final class DeepLServiceTests: XCTestCase {
    var service: DeepLService!

    override func setUpWithError() throws {
        service = DeepLService()
    }

// malloc 충돌 발생
//    override func tearDownWithError() throws {
//        service = nil
//    }

    func test_영어를_한글로_번역() async throws {
        // Given
        let englishText = "I like an Apple."
        
        // When
        do {
            let koreanText = try await service.translate(englishText)
            
            // Then
            XCTAssertFalse(koreanText.isEmpty, "번역 내용이 비워져 있지 않아야 함")
            print("Translation result: \(englishText) -> \(koreanText)")
            let containsKorean = koreanText.range(of: "\\p{Hangul}", options: .regularExpression) != nil
            XCTAssertTrue(containsKorean, "한글로 잘 번역되어야 함")
        } catch {
            XCTFail("Translation failed with error: \(error)")
        }
    }
}
