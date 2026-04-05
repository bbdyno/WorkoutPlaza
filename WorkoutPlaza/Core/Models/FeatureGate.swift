//
//  FeatureGate.swift
//  WorkoutPlaza
//
//  Created by bbdyno on 4/6/26.
//

import Foundation

/// 앱 기능별 유료/무료 여부를 중앙 관리
/// 개발자가 코드에서 즉시 유료↔무료 전환 가능
enum FeatureGate {

    // MARK: - GPX / Route

    /// GPX 파일 임포트
    static var gpxImport: Bool { true }

    /// 경로 위젯 (GPS 없을 때 GPX 임포트 유도)
    static var routeWidgetWithoutGPS: Bool { true }

    // MARK: - Fonts

    /// Pro 전용 폰트 (FontStyle.isProOnly에서 참조)
    static var proFonts: Bool { true }

    // MARK: - Speech Bubble

    /// Pro 전용 말풍선 스타일 (roundedBubble 제외 전부)
    static var proSpeechBubbleStyles: Bool { true }

    // MARK: - Watermark

    /// 무료 사용자 워터마크 표시
    static var watermark: Bool { true }

    // MARK: - Widget Limits

    /// 카드당 위젯 개수 제한 (Pro는 무제한)
    static var widgetCountLimit: Bool { false }

    // MARK: - Templates

    /// Pro 전용 템플릿 불러오기
    static var proTemplates: Bool { true }

    // MARK: - Export

    /// 고해상도 내보내기
    static var highResExport: Bool { false }

    /// 투명 배경 스티커 내보내기
    static var transparentExport: Bool { true }

    // MARK: - Helper

    /// 특정 기능이 유료인지 체크 + 현재 사용자가 접근 가능한지
    /// - Returns: true면 접근 가능, false면 Pro 구매 필요
    static func canAccess(_ isPurchasedFeature: Bool) -> Bool {
        if !isPurchasedFeature { return true }  // 무료 기능
        return PurchaseManager.shared.isEffectivelyPro
    }
}
