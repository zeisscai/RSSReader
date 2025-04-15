//
//  FeedListView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入SwiftUI框架，用于构建声明式UI
import SwiftUI

// 定义订阅源列表视图，遵循View协议
struct FeedListView: View {
    // 使用@StateObject创建并持有视图模型的生命周期
    // 该属性在视图生命周期中只初始化一次
    @StateObject private var viewModel = FeedListViewModel()
    
    // 使用@State管理本地视图状态，控制添加订阅源弹窗的显示状态
    @State private var showingAddFeed = false

    // 定义视图内容
    var body: some View {
        // 创建导航视图容器
        NavigationView {
            // 使用列表展示订阅源
            List {
                // 遍历视图模型中的订阅源数据
                ForEach(viewModel.feeds) { feed in
                    // 为每个订阅源创建导航链接，点击跳转到文章列表
                    NavigationLink(destination: ArticleListView(feed: feed)) {
                        HStack {
                            // 显示原文主页 favicon
                            if let link = feed.link,
                               let host = link.host {
                                let faviconURL = URL(string: "https://\(host)/favicon.ico")
                                AsyncImage(url: faviconURL) { image in
                                    image
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .cornerRadius(4)
                                } placeholder: {
                                    // 占位图标
                                    Image(systemName: "globe")
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                // 没有主页链接时显示默认图标
                                Image(systemName: "globe")
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.gray)
                            }
                            // 显示订阅源标题
                            Text(feed.title)
                        }
                    }
                }
                // 添加滑动删除功能，绑定删除方法
                .onDelete(perform: deleteFeed)
            }
            // 设置导航栏标题
            .navigationTitle("订阅源")
            // 添加工具栏按钮
            .toolbar {
                // 右侧工具栏按钮：添加订阅源
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 点击时切换弹窗显示状态
                        showingAddFeed = true
                    }) {
                        // 使用系统加号图标
                        Image(systemName: "plus")
                    }
                }
                
                // 左侧工具栏按钮：设置入口
                ToolbarItem(placement: .navigationBarLeading) {
                    // 导航链接到设置视图
                    NavigationLink(destination: SettingsView()) {
                        // 使用系统齿轮图标
                        Image(systemName: "gear")
                    }
                }
            }
            // 添加订阅源弹窗
            .sheet(isPresented: $showingAddFeed) {
                // 显示添加订阅源视图，传入关闭后的回调闭包
                AddFeedView { urlString, customTitle in
                    // 当用户完成添加操作时
                    if !urlString.isEmpty {
                        // 调用视图模型添加订阅源方法
                        viewModel.addFeed(
                            urlString: urlString,
                            customTitle: customTitle
                        )
                    }
                    // 关闭弹窗
                    showingAddFeed = false
                }
            }
        }
    }

    // MARK: - 数据操作方法
    /// 删除指定位置的订阅源
    /// - Parameter offsets: 包含要删除索引的集合
    private func deleteFeed(at offsets: IndexSet) {
        // 调用视图模型的删除方法
        viewModel.deleteFeed(at: offsets)
    }
}
