//
//  MainTabView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/15.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = FeedListViewModel()
    var body: some View {
        TabView {
            FeedListView()
                .tabItem {
                    Label("订阅源", systemImage: "list.bullet")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .environmentObject(viewModel)
    }
}
