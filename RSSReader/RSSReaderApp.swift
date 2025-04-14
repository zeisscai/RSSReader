//
//  RSSReaderApp.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

// 导入SwiftUI框架，用于构建用户界面和声明式编程
import SwiftUI

// 使用@main属性标记这是应用程序的入口点
// 自动生成应用程序的主入口，负责启动应用
@main
// 主应用结构体，遵循App协议
// App协议要求必须实现一个计算属性body来定义应用内容
struct RSSReaderApp: App {
    // 定义应用的主体内容，返回一个Scene对象
    // Scene代表应用程序中的一个功能模块或界面层级
    var body: some Scene {
        // 创建窗口组场景，这是最常用的基础场景类型
        // 在iOS上表现为单个窗口，在macOS/iPadOS支持多窗口
        WindowGroup {
            // 设置应用启动时的初始视图
            // FeedListView作为根视图，将填充整个窗口
            FeedListView()
        }
    }
}
