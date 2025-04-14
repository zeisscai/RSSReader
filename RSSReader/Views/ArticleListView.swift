//
//  ArticleListView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import SwiftUI

struct ArticleListView: View {
    let feed: Feed
    @StateObject private var viewModel = ArticleListViewModel()

    var body: some View {
        List {
            ForEach(viewModel.articles) { article in
                NavigationLink(destination: ArticleDetailView(article: article)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .fontWeight(article.isRead ? .regular : .bold)
                            .foregroundColor(article.isRead ? .secondary : .primary)

                        //Text(article.summary)
                        //   .font(.subheadline)
                        //    .lineLimit(2)
                        //    .foregroundColor(.gray)
                        
                        Text(article.summary.isEmpty ? "无摘要" : article.summary)
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundColor(.gray)

                        HStack {
                            if article.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                            //Text(article.date, style: .date)
                            //    .font(.caption)
                            //    .foregroundColor(.gray)
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
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(feed.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button("全部") { viewModel.filter = .all }
                    Button("未读") { viewModel.filter = .unread }
                    Button("收藏") { viewModel.filter = .favorites }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }

                Button(action: { viewModel.refreshFromFeed(feed) }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.loadArticles(for: feed)
        }
    }
}
