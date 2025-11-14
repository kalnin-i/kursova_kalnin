import Foundation

@MainActor
final class MovieViewModel: ObservableObject {
    private let apiKey: String = "dcf9b82a9bdb545ae094b6318541b9a0"
    private let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p/w500"

    @Published var popular: [Movie] = []
    @Published var trending: [Movie] = []
    @Published var isLoadingPopular = false
    @Published var isLoadingTrending = false
    @Published var errorMessage: String? = nil

    func fetchPopular() async {
        isLoadingPopular = true
        errorMessage = nil
        defer { isLoadingPopular = false }

        guard let url = URL(string: "\(baseURL)/movie/popular?api_key=\(apiKey)&&language=en-US&page=1") else {
            errorMessage = "Невірний URL для popular"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            popular = try JSONDecoder().decode(MoviesResponse.self, from: data).results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchTrending() async {
        isLoadingTrending = true
        errorMessage = nil
        defer { isLoadingTrending = false }

        guard let url = URL(string: "\(baseURL)/trending/movie/day?api_key=\(apiKey)") else {
            errorMessage = "Невірний URL для trending"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            trending = try JSONDecoder().decode(MoviesResponse.self, from: data).results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMovieDetail(movieId: Int) async throws -> MovieDetail {
        guard let url = URL(string: "\(baseURL)/movie/\(movieId)?api_key=\(apiKey)&language=en-US") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MovieDetail.self, from: data)
    }
}
