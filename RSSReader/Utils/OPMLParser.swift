import Foundation

enum OPMLParserError: Error {
    case invalidFormat
}

class OPMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var feeds: [Feed] = []
    private var currentElementName: String = ""
    private var currentAttributes: [String: String] = [:]
    private var feedSet: Set<String> = [] // 用于去重

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> [Feed] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() {
            return feeds
        } else {
            throw OPMLParserError.invalidFormat
        }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElementName = elementName
        currentAttributes = attributeDict

        if elementName == "outline" {
            if let xmlUrl = attributeDict["xmlUrl"], !xmlUrl.isEmpty,
               let url = URL(string: xmlUrl), !feedSet.contains(xmlUrl) {
                let title = attributeDict["text"] ?? xmlUrl
                let htmlUrl = attributeDict["htmlUrl"]
                let link = htmlUrl.flatMap { URL(string: $0) }
                let feed = Feed(id: UUID(), title: title, url: url, link: link)
                feeds.append(feed)
                feedSet.insert(xmlUrl)
            }
        }
    }
}
