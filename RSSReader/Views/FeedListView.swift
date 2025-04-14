//
//  FeedListView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import SwiftUI

struct FeedListView: View {
    @StateObject private var viewModel = FeedListViewModel()
    @State private var showingAddFeed = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.feeds) { feed in
                    NavigationLink(destination: ArticleListView(feed: feed)) {
                        Text(feed.title)
                    }
                }
                .onDelete(perform: deleteFeed)  // <-- 添加这一行代码来支持删除
            }
            .navigationTitle("订阅源")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFeed = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingAddFeed) {
                AddFeedView { urlString, customTitle in
                    if !urlString.isEmpty {
                        viewModel.addFeed(urlString: urlString, customTitle: customTitle)
                    }
                    showingAddFeed = false
                }
            }

        }
    }

    // 删除订阅源的方法
    private func deleteFeed(at offsets: IndexSet) {
        viewModel.deleteFeed(at: offsets)
    }
}
