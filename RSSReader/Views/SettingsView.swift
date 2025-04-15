//
//  SettingsView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
//
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: FeedListViewModel
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var isImporting = false
    @State private var importResultMessage: String?
    @State private var colorSchemeName: String = ""

    var body: some View {
        Form {
            Section(header: Text("应用设置")) {
                HStack {
                    Text("外观模式")
                    Spacer()
                    Text(colorSchemeName)
                        .foregroundColor(.secondary)
                }
                Button("清除所有缓存") {
                    Persistence.shared.saveArticles([])
                }
                .foregroundColor(.red)
            }
            .onAppear {
                colorSchemeName = UITraitCollection.current.userInterfaceStyle == .dark ? "深色" : "浅色"
            }

            Section(header: Text("订阅管理"),footer: Text("支持OPML和JSON格式")) {
                Button("导出订阅") {
                    exportURL = FeedService.shared.exportFeeds(feeds: viewModel.feeds)
                    if exportURL != nil {
                        isExporting = true
                    }
                }
                .fileExporter(isPresented: $isExporting, document: ExportDocument(fileURL: exportURL), contentType: UTType(filenameExtension: "opml") ?? .json) { result in
                    switch result {
                    case .success:
                        print("导出成功")
                    case .failure(let error):
                        print("导出失败: \(error.localizedDescription)")
                    }
                }

                Button("导入订阅") {
                    isImporting = true
                }
                .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json, UTType(filenameExtension: "opml") ?? .json]) { result in
                    switch result {
                    case .success(let url):
                        do {
                            // 解决权限问题，使用安全访问权限
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

            Section(footer: Text("简单 RSS 阅读器\nBy Zwiss Cai")) {
                Text("版本 1.0415")
            }
        }
        .navigationTitle("设置")
        .alert(isPresented: Binding<Bool>(
            get: { importResultMessage != nil },
            set: { if !$0 { importResultMessage = nil } }
        )) {
            Alert(title: Text(importResultMessage ?? ""))
        }
    }

    func importFeeds(from data: Data) throws {
        // 先尝试用OPML解析
        var importedFeeds: [Feed]? = nil
        if let feeds = try? FeedService.shared.importFeeds(from: data, fileExtension: "opml") {
            importedFeeds = feeds
        } else {
            // 再尝试用JSON解析
            let decoder = JSONDecoder()
            importedFeeds = try? decoder.decode([Feed].self, from: data)
        }
        guard let newFeeds = importedFeeds else { return }
        // 合并已有订阅，按 url 去重
        var existingFeeds = Persistence.shared.loadFeeds()
        let existingURLs = Set(existingFeeds.map { $0.url.absoluteString })
        let uniqueNewFeeds = newFeeds.filter { !existingURLs.contains($0.url.absoluteString) }
        let mergedFeeds = existingFeeds + uniqueNewFeeds
        Persistence.shared.saveFeeds(mergedFeeds)
        // 导入后刷新订阅列表
        viewModel.feeds = Persistence.shared.loadFeeds()
    }
}

/* 删除重复的 ColorScheme extension，避免 Invalid redeclaration 错误 */

// 需要定义ExportDocument以支持fileExporter
import UniformTypeIdentifiers
import SwiftUI

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType(filenameExtension: "opml") ?? .json] }
    var fileURL: URL?

    // 建议的导出文件名
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

/* 删除重复的 ColorScheme extension，避免 Invalid redeclaration 错误 */
