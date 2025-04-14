//
//  Extensions.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入Foundation框架
import Foundation

// Date类的扩展
extension Date {
    /// 将日期格式化为可读字符串
    func formattedString() -> String {
        // 创建日期格式化器
        let formatter = DateFormatter()
        // 设置日期显示样式（中等长度）
        formatter.dateStyle = .medium
        // 设置时间显示样式（短格式）
        formatter.timeStyle = .short
        // 返回格式化后的字符串
        return formatter.string(from: self)
    }
}

extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else {
            return self
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        if let attributedString = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ) {
            return attributedString.string
        }
        return self
    }
}
