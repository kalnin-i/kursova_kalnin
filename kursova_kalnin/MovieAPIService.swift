import Foundation

protocol MovieAPIServiceProtocol {
    func fetchPopular() async throws -> [Movie]
    func fetchTrending() async throws -> [Movie]
    func fetchMovieDetail(id: Int) async throws -> MovieDetail
    func searchMovies(query: String) async throws -> [Movie]
}

final class MovieAPIService: MovieAPIServiceProtocol {
    private let apiKey = "dcf9b82a9bdb545ae094b6318541b9a0"
    private let baseURL = "https://api.themoviedb.org/3"

    func fetchPopular() async throws -> [Movie] {
        let url = URL(string: "\(baseURL)/movie/popular?api_key=\(apiKey)&language=en-US&page=1")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MoviesResponse.self, from: data).results
    }

    func fetchTrending() async throws -> [Movie] {
        let url = URL(string: "\(baseURL)/trending/movie/day?api_key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MoviesResponse.self, from: data).results
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        let url = URL(string: "\(baseURL)/movie/\(id)?api_key=\(apiKey)&language=en-US")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MovieDetail.self, from: data)
    }

    func searchMovies(query: String) async throws -> [Movie] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "\(baseURL)/search/movie?api_key=\(apiKey)&language=en-US&query=\(encoded)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MoviesResponse.self, from: data).results
    }
}
