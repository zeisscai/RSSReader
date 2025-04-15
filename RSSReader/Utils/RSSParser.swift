//
//  RSSParser.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//
// 导入Foundation框架
import Foundation

/// RSS解析器类，继承NSObject并遵循XMLParserDelegate协议
class RSSParser: NSObject, XMLParserDelegate {
    // MARK: - 私有属性
    private var articles: [Article] = [] // 存储解析后的文章数组
    private var currentElement = "" // 当前解析的XML元素名
    private var currentTitle = "" // 当前解析的文章标题
    private var currentFeedTitle = "" // 当前解析的Feed标题
    private var currentFeedLink = "" // 当前解析的Feed主页链接
    private var isInChannel = false // 是否在channel标签内的标志
    private var currentDescription = "" // 当前解析的文章描述
    private var currentLink = "" // 当前解析的文章链接
    private var currentPubDate = "" // 当前解析的发布日期字符串
    
    private var feedID: UUID! // 当前Feed的唯一标识符

    // MARK: - 公开方法
    
    /// 解析RSS数据
    /// - Parameters:
    ///   - data: 要解析的XML数据
    ///   - feedID: 关联的Feed ID
    /// - Returns: 元组(Feed标题, Feed主页链接, 文章数组)
    /// - Throws: 解析错误时抛出异常
    func parse(data: Data, feed: Feed) throws -> (String?, String?, [Article]) {
        // 初始化解析状态
        self.feedID = feed.id
        print("[解析器] 使用的Feed ID: \(feedID ?? UUID())")
        self.articles = []
        self.currentFeedTitle = ""
        self.currentFeedLink = ""
        // 创建XML解析器
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        // 开始解析，失败时抛出错误
        guard parser.parse() else {
            throw parser.parserError ?? NSError(domain: "RSSParser", code: -1, userInfo: nil)
        }
        
        // 返回解析结果（去除空白字符的Feed标题、主页链接和文章数组）
        return (
            currentFeedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            currentFeedLink.trimmingCharacters(in: .whitespacesAndNewlines),
            articles
        )
    }

    // MARK: - XMLParserDelegate方法
    
    /// 开始解析XML元素时调用
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        // 处理channel开始标签
        if elementName == "channel" {
            isInChannel = true
            currentFeedTitle = "" // 重置 channel 标题
        }

        // 处理item开始标签，初始化临时变量
        if elementName == "item" {
            // 进入item时明确标记不在channel中
            isInChannel = false
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
        }
    }
    
    /// 解析到元素内容时调用
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // 根据当前元素类型累加内容

        switch currentElement {
        case "title":
            if isInChannel {
                // 改为累加而不是直接赋值，防止标题分段
                currentFeedTitle += string
            } else {
                currentTitle += string // 累加文章标题
            }
        case "description":
            currentDescription += string // 累加描述
        case "link":
            if isInChannel {
                currentFeedLink += string // channel 的 link
            } else {
                currentLink += string // item 的 link
            }
        case "pubDate":
            currentPubDate += string // 累加发布日期
        default:
            break
        }
    }
    
    /// 结束解析XML元素时调用
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        // 处理channel结束标签
        if elementName == "channel" {
            currentFeedTitle = currentFeedTitle
                        .trimmingCharacters(in: .whitespacesAndNewlines)
            isInChannel = false
            
        }

        // 处理item结束标签，创建文章对象
        if elementName == "item" {
            // 验证并处理链接
            guard let url = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
            // 新增：处理HTML标签和特殊字符
            let cleanSummary = currentDescription.strippingHTML()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            // 创建文章对象
            let article = Article(
                feedID: self.feedID,// 关联Feed ID,
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: cleanSummary,
                content: currentDescription,
                date: parseDate(currentPubDate), // 解析日期字符串
                link: url
                
                
            )
            
            articles.append(article) // 添加到文章数组
        }
    }

    // MARK: - 私有辅助方法
    
    /// 解析日期字符串
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX") // 设置固定locale
        
        // 尝试多种日期格式
        let formats = [
            "E, d MMM yyyy HH:mm:ss Z", // 标准RSS格式
            "E, d MMM yyyy HH:mm:ss zzz" // 备选格式
        ]
        
        // 遍历所有格式尝试解析
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // 所有格式都失败时返回当前日期
        return Date()
    }
}
