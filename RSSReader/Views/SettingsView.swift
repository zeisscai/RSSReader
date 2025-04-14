//
//  SettingsView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("应用设置")) {
                HStack {
                    Text("外观模式")
                    Spacer()
                    Text(ColorScheme.currentName)
                        .foregroundColor(.secondary)
                }

                Button("清除所有缓存") {
                    Persistence.shared.saveArticles([])
                }
                .foregroundColor(.red)
            }

            Section(footer: Text("现代 RSS 阅读器\n适配 iOS 14 及以上版本")) {
                Text("版本 1.0")
            }
        }
        .navigationTitle("设置")
    }
}

extension ColorScheme {
    static var currentName: String {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            return "深色"
        } else {
            return "浅色"
        }
    }
}
