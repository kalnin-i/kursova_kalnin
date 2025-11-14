import Foundation

struct Movie: Identifiable, Codable {
    let id: Int
    let title: String
    let overview: String?
    let vote_average: Double?
    let release_date: String?
    let poster_path: String?
}

struct MovieDetail: Codable {
    let id: Int
    let title: String
    let overview: String?
    let vote_average: Double?
    let release_date: String?
    let poster_path: String?
}

struct MoviesResponse: Codable {
    let results: [Movie]
}
