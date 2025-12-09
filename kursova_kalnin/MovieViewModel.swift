import Foundation

@MainActor
final class MovieViewModel: ObservableObject {
    private let api: MovieAPIServiceProtocol

    init(api: MovieAPIServiceProtocol = MovieAPIService()) {
        self.api = api
    }

    @Published var popular: [Movie] = []
    @Published var trending: [Movie] = []
    @Published var searchResults: [Movie] = []

    @Published var isLoadingPopular = false
    @Published var isLoadingTrending = false
    @Published var isSearching = false
    @Published var errorMessage: String?

    // MARK: - POPULAR
    func fetchPopular() async {
        isLoadingPopular = true
        defer { isLoadingPopular = false }

        do {
            popular = try await api.fetchPopular()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - TRENDING
    func fetchTrending() async {
        isLoadingTrending = true
        defer { isLoadingTrending = false }

        do {
            trending = try await api.fetchTrending()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - DETAIL
    func fetchMovieDetail(movieId: Int) async throws -> MovieDetail {
        try await api.fetchMovieDetail(id: movieId)
    }

    // MARK: - SEARCH
    func searchMovies(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await api.searchMovies(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Watch Later
    @Published var watchLater: [Movie] = []
    private let watchLaterKey = "watchLaterMovies"

    func loadWatchLater() {
        if let data = UserDefaults.standard.data(forKey: watchLaterKey),
           let movies = try? JSONDecoder().decode([Movie].self, from: data) {
            watchLater = movies
        }
    }

    func saveWatchLater() {
        if let data = try? JSONEncoder().encode(watchLater) {
            UserDefaults.standard.set(data, forKey: watchLaterKey)
        }
    }

    func addToWatchLater(_ movie: Movie) {
        guard !watchLater.contains(where: { $0.id == movie.id }) else { return }
        watchLater.append(movie)
        saveWatchLater()
    }

    func removeFromWatchLater(_ movie: Movie) {
        watchLater.removeAll { $0.id == movie.id }
        saveWatchLater()
    }

    func isInWatchLater(_ movie: Movie) -> Bool {
        watchLater.contains { $0.id == movie.id }
    }

    // MARK: - Image URL
    func fullImageURL(for path: String?) -> URL? {
        guard let path = path else { return nil }
        return URL(string: "\(MovieViewModel.imageBaseURL)\(path)")
    }

    static let imageBaseURL = "https://image.tmdb.org/t/p/w500"
}
