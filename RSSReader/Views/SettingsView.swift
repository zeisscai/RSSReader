//  SettingsView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var viewModel: FeedListViewModel
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var isImporting = false
    @State private var importResultMessage: String?
    @State private var colorSchemeName: String = ""
    @State private var showingAddFeed = false

    // 彩蛋：快速点击版本号10次弹窗
    @State private var versionTapCount = 0
    @State private var lastTapTime = Date()
    @State private var showHelloAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("应用设置").font(.headline)) {
                    HStack {
                        Text("外观模式")
                            .font(.body)
                        Spacer()
                        Text(colorSchemeName)
                            .foregroundColor(.secondary)
                            .font(.body)
                    }
                    .padding(.vertical, 10)
                    Button(action: {
                        Persistence.shared.saveArticles([])
                    }) {
                        HStack {
                            Text("清除所有缓存")
                                .font(.body)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                }
                .onAppear {
                    colorSchemeName = UITraitCollection.current.userInterfaceStyle == .dark ? "深色" : "浅色"
                }

                Section(header: Text("订阅管理").font(.headline), footer: Text("支持OPML和JSON格式").font(.caption2)) {
                    Button(action: {
                        showingAddFeed = true
                    }) {
                        HStack {
                            Text("添加订阅")
                                .font(.body)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }

                    Button(action: {
                        exportURL = FeedService.shared.exportFeeds(feeds: viewModel.feeds)
                        if exportURL != nil {
                            isExporting = true
                        }
                    }) {
                        HStack {
                            Text("导出订阅")
                                .font(.body)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .fileExporter(isPresented: $isExporting, document: ExportDocument(fileURL: exportURL), contentType: UTType(filenameExtension: "opml") ?? .json) { result in
                        switch result {
                        case .success:
                            importResultMessage = "导出成功"
                        case .failure(let error):
                            importResultMessage = "导出失败: \(error.localizedDescription)"
                        }
                    }

                    Button(action: {
                        isImporting = true
                    }) {
                        HStack {
                            Text("导入订阅")
                                .font(.body)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    }
                    .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json, UTType(filenameExtension: "opml") ?? .json]) { result in
                        switch result {
                        case .success(let url):
                            do {
                                let _ = url.startAccessingSecurityScopedResource()
                                defer { url.stopAccessingSecurityScopedResource() }
                                let data = try Data(contentsOf: url, options: .alwaysMapped)
                                try importFeeds(from: data)
                                importResultMessage = "导入成功"
                            } catch {
                                importResultMessage = "导入失败: \(error.localizedDescription)"
                            }
                        case .failure(let error):
                            importResultMessage = "导入失败: \(error.localizedDescription)"
                        }
                    }
                }

                Section(footer: Text("简单的 RSS 阅读器\nBy Zwiss Cai").font(.caption2)) {
                    HStack {
                        Text("版本 1.0416")
                            .font(.body)
                            .onTapGesture {
                                let now = Date()
                                if now.timeIntervalSince(lastTapTime) < 1 {
                                    versionTapCount += 1
                                } else {
                                    versionTapCount = 1
                                }
                                lastTapTime = now
                                if versionTapCount >= 10 {
                                    versionTapCount = 0
                                    showHelloAlert = true
                                }
                            }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert(isPresented: Binding<Bool>(
            get: { importResultMessage != nil },
            set: { if !$0 { importResultMessage = nil } }
        )) {
            Alert(title: Text(importResultMessage ?? ""))
        }
        .alert(isPresented: $showHelloAlert) {
            Alert(title: Text("Love you SWQ!"))
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedView { urlString, customTitle in
                if !urlString.isEmpty {
                    viewModel.addFeed(urlString: urlString, customTitle: customTitle) { result in
                        switch result {
                        case .success:
                            importResultMessage = "添加订阅成功"
                        case .failure(let error):
                            importResultMessage = "添加订阅失败: \(error.localizedDescription)"
                        }
                        showingAddFeed = false
                    }
                } else {
                    showingAddFeed = false
                }
            }
        }
    }

    func importFeeds(from data: Data) throws {
        var importedFeeds: [Feed]? = nil
        if let feeds = try? FeedService.shared.importFeeds(from: data, fileExtension: "opml") {
            importedFeeds = feeds
        } else {
            let decoder = JSONDecoder()
            importedFeeds = try? decoder.decode([Feed].self, from: data)
        }
        guard let newFeeds = importedFeeds else { return }
        let existingFeeds = Persistence.shared.loadFeeds()
        let existingURLs = Set(existingFeeds.map { $0.url.absoluteString })
        let uniqueNewFeeds = newFeeds.filter { !existingURLs.contains($0.url.absoluteString) }
        let mergedFeeds = existingFeeds + uniqueNewFeeds
        Persistence.shared.saveFeeds(mergedFeeds)
        viewModel.feeds = Persistence.shared.loadFeeds()
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType(filenameExtension: "opml") ?? .json] }
    var fileURL: URL?

    var displayName: String { "feeds.opml" }

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    init(configuration: ReadConfiguration) throws {
        self.fileURL = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let fileURL = fileURL else {
            throw NSError(domain: "ExportDocument", code: -1, userInfo: nil)
        }
        let data = try Data(contentsOf: fileURL)
        return FileWrapper(regularFileWithContents: data)
    }
}
