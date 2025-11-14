import SwiftUI

struct ContentView: View {
    @StateObject private var vm = MovieViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Watch Later Section
                    if !vm.watchLater.isEmpty {
                        sectionHeader("Дивитись пізніше")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(vm.watchLater) { movie in
                                    NavigationLink(destination: MovieDetailView(movieId: movie.id, viewModel: vm)) {
                                        MovieCardView(movie: movie)
                                            .frame(width: 140)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }

                    sectionHeader("Популярне")
                    movieSection(movies: vm.popular, loading: vm.isLoadingPopular)

                    sectionHeader("В тренді")
                    movieSection(movies: vm.trending, loading: vm.isLoadingTrending)
                }
                .padding()
            }
            .navigationTitle("Каталог фільмів")
            .task {
                vm.loadWatchLater()
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

// MARK: - Movie Card View
struct MovieCardView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: MovieViewModel().fullImageURL(for: movie.poster_path)) { phase in
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
}

// MARK: - Movie Detail View
struct MovieDetailView: View {
    let movieId: Int
    @ObservedObject var viewModel: MovieViewModel
    @State private var detail: MovieDetail?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showShare = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Завантаження…")
                    .padding()
            } else if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if let detail = detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        AsyncImage(url: viewModel.fullImageURL(for: detail.poster_path)) { phase in
                            switch phase {
                            case .empty: Rectangle().foregroundColor(.gray.opacity(0.3))
                            case .success(let img): img.resizable().scaledToFill()
                            case .failure: Rectangle().foregroundColor(.red.opacity(0.3))
                            @unknown default: Rectangle().foregroundColor(.gray.opacity(0.3))
                            }
                        }
                        .frame(height: 360)
                        .clipped()

                        Text(detail.title).font(.title).bold()

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

                        HStack(spacing: 12) {
                            Button(action: {
                                let movie = Movie(id: detail.id,
                                                  title: detail.title,
                                                  overview: detail.overview,
                                                  vote_average: detail.vote_average,
                                                  release_date: detail.release_date,
                                                  poster_path: detail.poster_path)
                                if viewModel.isInWatchLater(movie) {
                                    viewModel.removeFromWatchLater(movie)
                                } else {
                                    viewModel.addToWatchLater(movie)
                                }
                            }) {
                                Text(viewModel.isInWatchLater(Movie(id: detail.id,
                                                                    title: detail.title,
                                                                    overview: detail.overview,
                                                                    vote_average: detail.vote_average,
                                                                    release_date: detail.release_date,
                                                                    poster_path: detail.poster_path)) ? "Прибрати з ⭐️" : "Додати в ⭐️")
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Поділитись") {
                                showShare = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 12)
                    }
                    .padding()
                }
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: [detail?.title ?? ""])
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
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
