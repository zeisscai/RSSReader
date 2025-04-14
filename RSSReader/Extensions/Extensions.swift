//
//  Extensions.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation

extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
