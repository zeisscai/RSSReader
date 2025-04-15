//
//  ArticleListView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入SwiftUI框架，用于构建声明式UI
import SwiftUI

// 文章列表视图，展示单个订阅源的文章集合
struct ArticleListView: View {
    // MARK: - 数据依赖
    let feed: Feed                     // 当前显示的订阅源数据
    @StateObject private var viewModel = ArticleListViewModel()  // 文章列表视图模型
    @State private var filter: ArticleListViewModel.ArticleFilter = .all

    // 过滤后的文章
    private var filteredArticles: [Article] {
        switch filter {
        case .all:
            return viewModel.articles
        case .unread:
            return viewModel.articles.filter { !$0.isRead }
        case .favorites:
            return viewModel.articles.filter { $0.isFavorite }
        }
    }
    
    // MARK: - 视图主体
    var body: some View {
        // 使用列表展示文章集合
        List {
            // 遍历视图模型中的文章数据
            ForEach(filteredArticles) { article in
                // 创建导航链接到文章详情页
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    // 文章信息垂直布局
                    VStack(alignment: .leading, spacing: 4) {
                        // 文章标题（根据阅读状态改变样式）
                        Text(article.title)
                            .fontWeight(article.isRead ? .regular : .bold)
                            .foregroundColor(article.isRead ? .secondary : .primary)
                        
                        // 文章摘要（处理空摘要情况）
                        Text(article.summary.isEmpty ? "无摘要" : article.summary)
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundColor(.gray)
                        
                        // 底部信息水平布局
                        HStack {
                            // 收藏状态指示器
                            if article.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                            
                            // 日期显示（处理无效日期情况）
                            if article.date > Date(timeIntervalSince1970: 0) {
                                Text(article.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Text("无日期")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 4)  // 垂直方向内边距
                }
                // 支持滑动手势：标记已读/未读、收藏
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        withAnimation {
                            if article.isRead {
                                // 标记为未读
                                var updated = article
                                updated.isRead = false
                                viewModel.markAsRead(updated) // 这里需要实现 markAsUnread
                            } else {
                                viewModel.markAsRead(article)
                            }
                        }
                    } label: {
                        Label(article.isRead ? "标为未读" : "标为已读", systemImage: article.isRead ? "envelope.badge" : "envelope.open")
                    }
                    .tint(article.isRead ? .blue : .green)
                    
                    Button {
                        withAnimation {
                            viewModel.toggleFavorite(article)
                        }
                    } label: {
                        Label(article.isFavorite ? "取消收藏" : "收藏", systemImage: article.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
            }
        }
        .listStyle(.insetGrouped)  // 设置列表样式为分组插入样式
        .navigationTitle(feed.title)  // 设置导航栏标题为订阅源名称
        .toolbar {
            // 工具栏按钮组（位于导航栏右侧）
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 过滤菜单
                Menu {
                    Button("全部") { filter = .all }
                    Button("未读") { filter = .unread }
                    Button("收藏") { filter = .favorites }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        // 下拉刷新当前订阅源
        .refreshable {
            await withCheckedContinuation { cont in
                viewModel.refreshFromFeed(feed) {
                    cont.resume()
                }
            }
        }
        // 视图出现时加载文章数据
        .onAppear {
            viewModel.loadArticles(for: feed)
        }
    }
}
