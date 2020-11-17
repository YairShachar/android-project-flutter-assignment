import 'package:english_words/english_words.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/user.dart';
import 'package:provider/provider.dart';
import 'globals.dart' as AppGlobals;

class FavoritesPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _FavoritesPage();
}

class _FavoritesPage extends State<FavoritesPage> {
  final TextStyle _biggerFont = const TextStyle(fontSize: 15);

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, UserRepository user, _) {
      final Set<String> favorites = AppGlobals.user.getFavorites();
      final tiles = favorites.map((String pair) {
        return Builder(builder: (BuildContext context) {
          return ListTile(
            trailing: Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            onTap: () {
              print("removing pair " + pair.toString());
              AppGlobals.user.removeFavorite(pair);
            },
            title: Text(
              pair,
              style: _biggerFont,
            ),
          );
        });
      });

      final divided = ListTile.divideTiles(
        context: context,
        tiles: tiles,
      ).toList();

      return Scaffold(
        // key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Saved Suggestions'),
        ),
        body: ListView(children: divided),
      );
    });
  }
}
