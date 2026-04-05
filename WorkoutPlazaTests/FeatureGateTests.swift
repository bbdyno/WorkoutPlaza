//
//  FeatureGateTests.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/6/26.
//

import Testing
@testable import WorkoutPlaza

struct FeatureGateTests {

    @Test func gpxImportIsPurchasedFeature() {
        #expect(FeatureGate.gpxImport == true)
    }

    @Test func proFontsIsPurchasedFeature() {
        #expect(FeatureGate.proFonts == true)
    }

    @Test func proSpeechBubbleStylesIsPurchasedFeature() {
        #expect(FeatureGate.proSpeechBubbleStyles == true)
    }

    @Test func watermarkIsPurchasedFeature() {
        #expect(FeatureGate.watermark == true)
    }

    @Test func freeFeatureAlwaysAccessible() {
        #expect(FeatureGate.canAccess(false) == true)
    }

    @Test func widgetCountLimitIsFree() {
        #expect(FeatureGate.widgetCountLimit == false)
    }

    @Test func speechBubbleRoundedIsFree() {
        let style = SpeechBubbleStyle.roundedBubble
        #expect(style.isProRequired == false)
    }

    @Test func speechBubbleThoughtIsPro() {
        let style = SpeechBubbleStyle.thoughtBubble
        #expect(style.isProRequired == true)
    }

    @Test func fontSystemIsFree() {
        let font = FontStyle.system
        #expect(font.isProOnly == false)
    }

    @Test func fontExploraIsPro() {
        let font = FontStyle.explora
        #expect(font.isProOnly == true)
    }
}
