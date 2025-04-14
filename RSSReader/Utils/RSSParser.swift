//
//  RSSParser.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation

class RSSParser: NSObject, XMLParserDelegate {
    private var articles: [Article] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentFeedTitle = ""
    private var isInChannel = false
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""

    private var feedID: UUID!

    func parse(data: Data, feedID: UUID) throws -> (String?, [Article]) {
        self.feedID = feedID
        self.articles = []
        self.currentFeedTitle = ""
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw parser.parserError ?? NSError(domain: "RSSParser", code: -1, userInfo: nil)
        }
        return (currentFeedTitle.trimmingCharacters(in: .whitespacesAndNewlines), articles)
    }


    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "channel" {
            isInChannel = true
        }

        if elementName == "item" {
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
        }
    }


    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            if isInChannel {
                currentFeedTitle += string
            } else {
                currentTitle += string
            }
        case "description":
            currentDescription += string
        case "link":
            currentLink += string
        case "pubDate":
            currentPubDate += string
        default:
            break
        }
    }


    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "channel" {
            isInChannel = false
        }

        if elementName == "item" {
            guard let url = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
            let article = Article(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                content: currentDescription,
                date: parseDate(currentPubDate),
                link: url,
                feedID: feedID // 保证每篇文章都与正确的 feedID 关联
            )
            articles.append(article)
        }
    }


    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let formats = [
            "E, d MMM yyyy HH:mm:ss Z", // Standard RSS
            "E, d MMM yyyy HH:mm:ss zzz"
        ]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return Date()
    }
}
