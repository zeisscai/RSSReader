//
//  FeedService.swift
//  RSSReader
//
//  Created by Zwiss Cai on 2025/4/14.
//

import Foundation

class FeedService {
    static let shared = FeedService()

    private init() {}

    func fetchArticles(from feedURL: URL, completion: @escaping (Result<[Article], Error>) -> Void) {
        URLSession.shared.dataTask(with: feedURL) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(URLError(.badServerResponse)))
                }
                return
            }

            let parser = RSSParser()
            do {
                let (_, articles) = try parser.parse(data: data, feedID: UUID())
                DispatchQueue.main.async {
                    completion(.success(articles))
                }

            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
