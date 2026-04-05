//
//  AspectRatioTests.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/6/26.
//

import Testing
import Foundation
import CoreGraphics
@testable import WorkoutPlaza

struct AspectRatioTests {

    // MARK: - 3:4 고정 비율

    @Test func onlySingleRatioExists() {
        #expect(AspectRatio.allCases.count == 1)
        #expect(AspectRatio.allCases.first == .portrait3_4)
    }

    @Test func ratioIs4Over3() {
        let ratio = AspectRatio.portrait3_4.ratio
        #expect(abs(ratio - 4.0 / 3.0) < 0.001)
    }

    @Test func exportSizeIs1080x1440() {
        let size = AspectRatio.portrait3_4.exportSize
        #expect(size.width == 1080)
        #expect(size.height == 1440)
    }

    @Test func detectAlwaysReturns3_4() {
        #expect(AspectRatio.detect(from: CGSize(width: 414, height: 414)) == .portrait3_4)
        #expect(AspectRatio.detect(from: CGSize(width: 414, height: 700)) == .portrait3_4)
        #expect(AspectRatio.detect(from: CGSize(width: 1080, height: 1920)) == .portrait3_4)
    }

    // MARK: - 구버전 호환 디코딩

    @Test func decodesLegacySquare() throws {
        let json = #""square_1_1""#
        let decoded = try JSONDecoder().decode(AspectRatio.self, from: json.data(using: .utf8)!)
        #expect(decoded == .portrait3_4)
    }

    @Test func decodesLegacyPortrait4_5() throws {
        let json = #""portrait_4_5""#
        let decoded = try JSONDecoder().decode(AspectRatio.self, from: json.data(using: .utf8)!)
        #expect(decoded == .portrait3_4)
    }

    @Test func decodesLegacyPortrait9_16() throws {
        let json = #""portrait_9_16""#
        let decoded = try JSONDecoder().decode(AspectRatio.self, from: json.data(using: .utf8)!)
        #expect(decoded == .portrait3_4)
    }

    @Test func decodesCurrentPortrait3_4() throws {
        let json = #""portrait_3_4""#
        let decoded = try JSONDecoder().decode(AspectRatio.self, from: json.data(using: .utf8)!)
        #expect(decoded == .portrait3_4)
    }
}
