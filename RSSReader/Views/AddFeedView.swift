//
//  AddFeedView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入SwiftUI框架
import SwiftUI

/// 添加订阅源的视图组件
struct AddFeedView: View {
    // MARK: - 状态属性
    @State private var urlString = ""      // 存储用户输入的URL
    @State private var customTitle = ""    // 存储用户自定义的标题
    
    // MARK: - 回调闭包
    /// 添加订阅源的回调方法
    /// - 参数1: 用户输入的URL字符串
    /// - 参数2: 用户自定义的标题（可选）
    var onAdd: (String, String?) -> Void
    
    // MARK: - 视图主体
    var body: some View {
        // 使用导航视图包裹表单
        NavigationView {
            // 表单布局
            Form {
                // 自定义标题输入区
                Section(header: Text("订阅标题")) {
                    TextField("填写名称", text: $customTitle)
                }
                
                // RSS链接输入区
                Section(header: Text("RSS 链接")) {
                    TextField("输入 RSS 地址", text: $urlString)
                        .keyboardType(.URL)          // 设置URL键盘类型
                        .autocapitalization(.none)   // 禁用自动大写
                }
            }
            // 导航栏设置
            .navigationTitle("添加订阅源")
            // 工具栏按钮
            .toolbar {
                // 确认按钮（添加操作）
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        // 调用回调，如果customTitle为空则传nil
                        onAdd(urlString, customTitle.isEmpty ? nil : customTitle)
                    }
                    .disabled(urlString.isEmpty)  // URL为空时禁用按钮
                }
                
                // 取消按钮
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        // 传递空字符串和nil表示取消操作
                        onAdd("", nil)
                    }
                }
            }
        }
    }
}

