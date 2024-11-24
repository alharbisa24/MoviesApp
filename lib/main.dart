import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}
String searchQuery = "";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {



    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: Text("MoviesApp"),

            ),

        body: MovieListScreen(),





      )
    );
  }

}

class MovieListScreen extends StatefulWidget {
  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final String apiKey = "YOUR_API_KEY"; // Replace with your TMDb API key
  final String apiUrl = "https://api.themoviedb.org/3";


  List movies = [];
  List filteredMovies = [];
  List genres = [];
  bool isLoading = true;
  int _currentIndex = 0; // To track the selected navigation bar item


  @override
  void initState() {
    super.initState();
    fetchMovies(_currentIndex);
    fetchGenres();
  }
  Future<void> fetchGenres() async {
    final url = Uri.parse("${apiUrl}/genre/movie/list?api_key=$apiKey");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          genres = data['genres'];
        });
      } else {
        throw Exception("Failed to fetch genres");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
  Future<void> fetchMovies(int index) async {
    String endpoint = index == 0 ? "now_playing" : "top_rated";
    final url = Uri.parse("${apiUrl}/movie/$endpoint?api_key=$apiKey");
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          movies = data['results'];
          filteredMovies = movies;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch movies");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
  void filterMovies(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredMovies = movies;
      } else {
        final genre = genres.firstWhere(
                (g) => g['name'].toLowerCase() == query.toLowerCase(),
            orElse: () => null);
        if (genre != null) {
          final genreId = genre['id'];
          filteredMovies = movies.where((movie) {
            return movie['genre_ids'].contains(genreId);
          }).toList();
        } else {
          // Search by keyword (movie title)
          filteredMovies = movies.where((movie) {
            final title = movie['title']?.toLowerCase() ?? "";
            return title.contains(query.toLowerCase());
          }).toList();
        }
      }
    });
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      fetchMovies(index);
      fetchGenres(); // Fetch movies for the selected tab
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
    child: Column(
    children: [
    Center(
    child: Text(
    "Welcome to MoviesApp",
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    textAlign: TextAlign.center,
    ),

    ),
      SizedBox(height: 30),
      Center(
        child: Text(_currentIndex == 0 ? "Recent 20 Movies" : "Highly Rated Movies",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),

      ),
    SizedBox(height: 20),
    TextField(
    decoration: InputDecoration(
    labelText: "Search by Keyword, Genre, or Actor",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.search),
    ),
    onChanged: filterMovies,
    ),
    SizedBox(height: 20),
    Expanded(
    child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ),
            )
                : filteredMovies.isEmpty
                ? Center(
              child: Text(
                "No Movies Found",
                style: TextStyle(fontSize: 18),
              ),
            )

                : ListView.builder(
              itemCount: filteredMovies.length,
              itemBuilder: (context, index) {
                final movie = filteredMovies[index];
                return ListTile(
                  leading: movie['poster_path'] != null
                      ? Image.network(
                    'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                    width: 50,
                  )
                      : Icon(Icons.movie, size: 50),
                  title: Text(movie['title']),
                  subtitle: Text("Rating: ${movie['vote_average']}"),
                  onTap: () {
                    print("Selected Movie: ${movie['title']}");
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,  // To make the row fit in the available space
                    children: [
                      // First button (Favorite)

                    ],
                  ),
                );
              },
            ),
          ),
        ],

      ),

    ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,

          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.new_releases),
              label: "Recent",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.thumb_up),
              label: "Highly rated",
            ),
          ],
        ),
    );
  }
}
