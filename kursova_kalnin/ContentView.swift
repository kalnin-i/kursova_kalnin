import SwiftUI

struct ContentView: View {
    @StateObject private var vm = MovieViewModel()
    
    @State private var showSearch = false
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.yellow, .orange, .pink]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
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
                        
                        if !vm.searchResults.isEmpty {
                            sectionHeader("Результати пошуку")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(vm.searchResults) { movie in
                                    NavigationLink(destination: MovieDetailView(movieId: movie.id, viewModel: vm)) {
                                        MovieCardView(movie: movie)
                                    }
                                }
                            }
                        } else {
                            sectionHeader("Популярне")
                            movieSection(movies: vm.popular, loading: vm.isLoadingPopular)
                            
                            sectionHeader("В тренді")
                            movieSection(movies: vm.trending, loading: vm.isLoadingTrending)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Каталог фільмів")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                .task {
                    vm.loadWatchLater()
                    await vm.fetchPopular()
                    await vm.fetchTrending()
                }
                .sheet(isPresented: $showSearch) {
                    NavigationView {
                        VStack {
                            TextField("Введіть назву фільму...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .padding()
                                .onSubmit {
                                    Task {
                                        await vm.searchMovies(query: searchText)
                                    }
                                }

                            if vm.isSearching {
                                ProgressView().padding()
                            }

                            ScrollView {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(vm.searchResults) { movie in
                                        NavigationLink(destination: MovieDetailView(movieId: movie.id, viewModel: vm)) {
                                            MovieCardView(movie: movie)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .navigationTitle("Пошук")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Закрити і очистити") {
                                    searchText = ""
                                    vm.searchResults = []
                                    showSearch = false
                                }
                            }
                        }
                    }
                }
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
            AsyncImage(url: buildImageURL()) { phase in
                switch phase {
                case .empty:
                    Rectangle().foregroundColor(.gray.opacity(0.3))
                        .frame(height: 200)
                case .success(let img):
                    img.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                @unknown default:
                    Rectangle().foregroundColor(.gray.opacity(0.3))
                        .frame(height: 200)
                }
            }

            Text(movie.title)
                .font(.footnote)
                .bold()
                .lineLimit(2)
                .padding(8)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }

    private func buildImageURL() -> URL? {
        guard let path = movie.poster_path, !path.isEmpty else { return nil }
        return URL(string: MovieViewModel.imageBaseURL + path)
    }
}

struct MovieDetailView: View {
    let movieId: Int
    @ObservedObject var viewModel: MovieViewModel
    @State private var detail: MovieDetail?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showShare = false

    var body: some View {
        ZStack {
            LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange, .pink]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
            
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
                            
                            HStack {
                                Spacer()

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
                                                                        poster_path: detail.poster_path)) ?
                                         "Прибрати з ⭐️" : "Додати в ⭐️")
                                        .frame(maxWidth: 220)
                                }
                                .buttonStyle(.borderedProminent)

                                Spacer()
                            }
                            .padding(.top, 16)
                        }
                        .padding()
                    }
                } else {
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShare) {
                ActivityView(activityItems: [detail?.title ?? ""])
            }
            .navigationTitle("Деталі")
            .task { await loadDetail() }
        }
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
