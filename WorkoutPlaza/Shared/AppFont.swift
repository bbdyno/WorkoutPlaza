//
//  AppFont.swift
//  WorkoutPlaza
//
//  앱 UI 크롬용 커스텀 폰트 유틸리티
//  위젯/카드 편집기의 FontStyleManager와는 별개
//

import UIKit

enum AppFont {

    // MARK: - Body (Pretendard)

    static func body(_ size: CGFloat) -> UIFont {
        UIFont(name: "Pretendard-Regular", size: size)
            ?? .systemFont(ofSize: size, weight: .regular)
    }

    static func bodySemiBold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Pretendard-SemiBold", size: size)
            ?? .systemFont(ofSize: size, weight: .semibold)
    }

    static func bodyBold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Pretendard-Bold", size: size)
            ?? .systemFont(ofSize: size, weight: .bold)
    }

    // MARK: - Stats / Numbers (Montserrat)

    static func stat(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Bold", size: size)
            ?? .systemFont(ofSize: size, weight: .bold)
    }

    static func statSemiBold(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-SemiBold", size: size)
            ?? .systemFont(ofSize: size, weight: .semibold)
    }

    static func statRegular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Regular", size: size)
            ?? .systemFont(ofSize: size, weight: .regular)
    }

    // MARK: - Monospaced Digits (Montserrat)

    static func mono(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Bold", size: size)
            ?? .monospacedDigitSystemFont(ofSize: size, weight: .bold)
    }

    static func monoRegular(_ size: CGFloat) -> UIFont {
        UIFont(name: "Montserrat-Regular", size: size)
            ?? .monospacedDigitSystemFont(ofSize: size, weight: .regular)
    }
}
