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
    
    // MARK: - 视图主体
    var body: some View {
        // 使用列表展示文章集合
        List {
            // 遍历视图模型中的文章数据
            ForEach(viewModel.articles) { article in
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
            }
        }
        .listStyle(.insetGrouped)  // 设置列表样式为分组插入样式
        .navigationTitle(feed.title)  // 设置导航栏标题为订阅源名称
        .toolbar {
            // 工具栏按钮组（位于导航栏右侧）
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 过滤菜单
                Menu {
                    Button("全部") { viewModel.filter = .all }
                    Button("未读") { viewModel.filter = .unread }
                    Button("收藏") { viewModel.filter = .favorites }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                
                // 刷新按钮
                Button(action: { viewModel.refreshFromFeed(feed) }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        // 视图出现时加载文章数据
        .onAppear {
            viewModel.loadArticles(for: feed)
        }
    }
}


