//
//  UIUtil.swift
//  realm-cloud-functions-demo
//
//  Created by David Okun IBM on 8/20/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit

public extension String {
    var hexColor: UIColor {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

public extension UIFont {
    class IBMFonts {
        static func bold(size: CGFloat) -> UIFont {
            guard let font = UIFont(name: "IBMPlexSans-Bold", size: size) else {
                return UIFont.systemFont(ofSize: size)
            }
            return font
        }
        
        static func medium(size: CGFloat) -> UIFont {
            guard let font = UIFont(name: "IBMPlexSans-Medium", size: size) else {
                return UIFont.systemFont(ofSize: size)
            }
            return font
        }
        
        static func regular(size: CGFloat) -> UIFont {
            guard let font = UIFont(name: "IBMPlexSans-Regular", size: size) else {
                return UIFont.systemFont(ofSize: size)
            }
            return font
        }
    }
}
