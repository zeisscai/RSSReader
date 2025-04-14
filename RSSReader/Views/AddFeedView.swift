//
//  AddFeedView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import SwiftUI
struct AddFeedView: View {
    @State private var urlString = ""
    @State private var customTitle = ""
    var onAdd: (String, String?) -> Void  // 第二个参数是用户输入的标题

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("自定义名称（可选）")) {
                    TextField("填写名称", text: $customTitle)
                }
                
                Section(header: Text("RSS 链接")) {
                    TextField("输入 RSS 地址", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

            }
            .navigationTitle("添加订阅源")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        onAdd(urlString, customTitle.isEmpty ? nil : customTitle)
                    }
                    .disabled(urlString.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onAdd("", nil) // 取消
                    }
                }
            }
        }
    }
}

