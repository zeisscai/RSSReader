//
//  ArticleDetailView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入SwiftUI框架和WebKit框架
import SwiftUI
import WebKit

/// 文章详情视图，展示单篇文章的完整内容
struct ArticleDetailView: View {
    //let article: Article
    // 使用@StateObject管理视图模型，确保生命周期与视图一致
    @StateObject private var viewModel: ArticleDetailViewModel
    @State private var webViewHeight: CGFloat = 100 // 初始高度
    // 自定义初始化方法，接收文章参数
    init(article: Article) {
        // 初始化视图模型并包装为StateObject
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }
    
    var body: some View {
        // 使用ScrollView支持内容滚动
        ScrollView {
            // 垂直布局文章内容
            VStack(alignment: .leading, spacing: 16) {
                // 文章标题
                Text(viewModel.article.title)
                    .font(.title2)
                    .bold()
                
                // 文章日期（使用相对日期样式）
                Text(viewModel.article.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // 分隔线
                Divider()
                
                // HTML内容展示视图
                DynamicHeightWebView(htmlContent: viewModel.article.content, webViewHeight: $webViewHeight)
                                    .frame(height: webViewHeight)
                                    .background(Color(.systemBackground))
                
                // 原文链接按钮
                Link("阅读原文", destination: viewModel.article.link)
                    .font(.footnote)
                    .padding(.top, 8)
            }
            .padding()  // 内边距
        }
        // 工具栏设置
        .toolbar {
            // 收藏按钮
            Button(action: viewModel.toggleFavorite) {
                Image(systemName: viewModel.article.isFavorite ? "star.fill" : "star")
                    .foregroundColor(viewModel.article.isFavorite ? .yellow : .primary)
            }
        }
    }
}

// MARK: - HTML内容展示组件
/// 封装WKWebView用于显示HTML内容的SwiftUI组件
struct DynamicHeightWebView: UIViewRepresentable {
    let htmlContent: String
    @Binding var webViewHeight: CGFloat
    @Environment(\.colorScheme) var colorScheme // 获取当前颜色模式
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        // 加载带有动态颜色适配的内容
        loadContent(in: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 颜色模式变化时重新加载
        if context.coordinator.lastColorScheme != colorScheme {
            loadContent(in: uiView)
            context.coordinator.lastColorScheme = colorScheme
        }
    }
    
    private func loadContent(in webView: WKWebView) {
        let textColor = colorScheme == .dark ? "white" : "#333"
        //let backgroundColor = colorScheme == .dark ? "black" : "white"
        
        let css = """
        <style>
            body {
                font-size: 18px;
                line-height: 1.6;
                color: \(textColor);
                padding: 16px;
                margin: 0;
                
            }
            img { max-width: 100% !important; height: auto !important; }
            a { color: \(colorScheme == .dark ? "#7FB3FF" : "#0066CC"); }
        </style>
        """
        
        let meta = "<meta name='viewport' content='width=device-width, initial-scale=1.0'>"
        webView.loadHTMLString(meta + css + htmlContent, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DynamicHeightWebView
        var lastColorScheme: ColorScheme?
        
        init(parent: DynamicHeightWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { (height, _) in
                if let height = height as? CGFloat {
                    DispatchQueue.main.async {
                        self.parent.webViewHeight = height
                    }
                }
            }
            lastColorScheme = parent.colorScheme
        }
    }
}
