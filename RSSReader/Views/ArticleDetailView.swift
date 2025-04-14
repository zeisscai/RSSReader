//
//  📄 ArticleDetailView.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
//import SwiftUI
//
//struct ArticleDetailView: View {
//    @StateObject private var viewModel: ArticleDetailViewModel
//
//    init(article: Article) {
//        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
//    }
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                Text(viewModel.article.title)
//                    .font(.title2)
//                    .bold()
//
//                Text(viewModel.article.date, style: .date)
//                    .font(.caption)
//                    .foregroundColor(.gray)
//
//                Divider()
//
//                Text(viewModel.article.content)
//                    .font(.body)
//                    .foregroundColor(.primary)
//
//                Link("阅读原文", destination: viewModel.article.link)
//                    .font(.footnote)
//                    .padding(.top, 8)
//            }
//            .padding()
//        }
//        .navigationTitle("文章详情")
//        .toolbar {
//            Button(action: viewModel.toggleFavorite) {
//                Image(systemName: viewModel.article.isFavorite ? "star.fill" : "star")
//                    .foregroundColor(viewModel.article.isFavorite ? .yellow : .primary)
//            }
//        }
//    }
//}
//
//import SwiftUI
//
//struct ArticleDetailView: View {
//    let article: Article
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                Text(article.title)
//                    .font(.title)
//                    .bold()
//                
//                if let attributed = htmlToAttributedString(html: article.summary) {
//                    Text(attributed)
//                } else {
//                    Text(article.summary)
//                        .foregroundColor(.gray)
//                }
//                
//                Link("阅读原文", destination: viewModel.article.link)
//                                    .font(.footnote)
//                                    .padding(.top, 8)
//                }
//                
//                    .padding()
//            }
//            .navigationTitle("详情")
//        }
//        
//        // HTML 转富文本函数
//        func htmlToAttributedString(html: String) -> AttributedString? {
//            guard let data = html.data(using: .utf8) else { return nil }
//            do {
//                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
//                    .documentType: NSAttributedString.DocumentType.html,
//                    .characterEncoding: String.Encoding.utf8.rawValue
//                ]
//                let nsAttrStr = try NSAttributedString(data: data, options: options, documentAttributes: nil)
//                return AttributedString(nsAttrStr)
//            } catch {
//                print("HTML parse error:", error)
//                return nil
//            }
//        }
//    }
//}
//        
import SwiftUI
import WebKit

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel

    init(article: Article) {
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.article.title)
                    .font(.title2)
                    .bold()

                Text(viewModel.article.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                HTMLView(htmlContent: viewModel.article.content)
                    .frame(minHeight: 300)

                Link("阅读原文", destination: viewModel.article.link)
                    .font(.footnote)
                    .padding(.top, 8)
            }
            .padding()
        }
        //.navigationTitle("文章详情")
        .toolbar {
            Button(action: viewModel.toggleFavorite) {
                Image(systemName: viewModel.article.isFavorite ? "star.fill" : "star")
                    .foregroundColor(viewModel.article.isFavorite ? .yellow : .primary)
            }
        }
    }
}

// ✅ 添加一个 SwiftUI WebView 封装视图
struct HTMLView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false // 可选：不允许内部滚动
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

