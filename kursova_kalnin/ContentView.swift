import SwiftUI

struct ContentView: View {
    @StateObject private var vm = MovieViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Популярне")
                    movieSection(movies: vm.popular, loading: vm.isLoadingPopular)

                    sectionHeader("В тренді")
                    movieSection(movies: vm.trending, loading: vm.isLoadingTrending)
                }
                .padding()
            }
            .navigationTitle("Каталог фільмів")
            .task {
                await vm.fetchPopular()
                await vm.fetchTrending()
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.title2).bold()
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func movieSection(movies: [Movie], loading: Bool) -> some View {
        if loading {
            ProgressView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movieId: movie.id, viewModel: vm)) {
                            MovieCardView(movie: movie)
                                .frame(width: 140)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct MovieCardView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: imageURL(path: movie.poster_path)) { phase in
                switch phase {
                case .empty: Rectangle().foregroundColor(.gray.opacity(0.3))
                case .success(let img): img.resizable().scaledToFill()
                case .failure: Rectangle().foregroundColor(.red.opacity(0.3))
                @unknown default: Rectangle().foregroundColor(.gray.opacity(0.3))
                }
            }
            .frame(height: 200)
            .clipped()

            Text(movie.title)
                .font(.footnote).bold()
                .lineLimit(2)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }

    private func imageURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        return URL(string: "\(MovieViewModel.imageBaseURL)\(path)")
    }
}

struct MovieDetailView: View {
    let movieId: Int
    @ObservedObject var viewModel: MovieViewModel
    @State private var detail: MovieDetail?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Завантаження…")
                    .padding()
            }
            else if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            else if let detail = detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {

                        AsyncImage(url: imageURL(path: detail.poster_path)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle().foregroundColor(.gray.opacity(0.3))
                            case .success(let img):
                                img.resizable().scaledToFill()
                            case .failure:
                                Rectangle().foregroundColor(.red.opacity(0.3))
                            @unknown default:
                                Rectangle().foregroundColor(.gray.opacity(0.3))
                            }
                        }
                        .frame(height: 360)
                        .clipped()

                        Text(detail.title)
                            .font(.title)
                            .bold()

                        HStack {
                            if let vote = detail.vote_average {
                                Text(String(format: "%.1f ⭐️", vote))
                            }
                            Spacer()
                            if let date = detail.release_date {
                                Text(date)
                            }
                        }

                        Text(detail.overview ?? "Без опису")
                            .padding(.top, 8)
                    }
                    .padding()
                }
            } else {
                EmptyView()
            }
        }
        .navigationTitle("Деталі")
        .task { await loadDetail() }
    }

    private func loadDetail() async {
        isLoading = true
        error = nil
        detail = nil
        defer { isLoading = false }

        do {
            detail = try await viewModel.fetchMovieDetail(movieId: movieId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func imageURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        return URL(string: "\(MovieViewModel.imageBaseURL)\(path)")
    }
}


#Preview {
    ContentView()
}
