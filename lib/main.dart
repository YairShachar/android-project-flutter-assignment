import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/rendering.dart';
import 'package:hello_me/favorites_page.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'globals.dart';
import 'login_page.dart';
import 'user.dart';
import 'globals.dart' as AppGlobals;

double bottomSnappingPositionHeight = 0.0;
double topSnappingPositionHeight = 130;
double blurAmount = 0;
final _grabbingKey = GlobalKey();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
              home: Scaffold(
                  body: Center(
                      child: Text(snapshot.error.toString(),
                          textDirection: TextDirection.ltr))));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => UserRepository.instance(), child: HomePage());
  }
}

class HomePage extends StatelessWidget {
  final RandomWords randomWords = RandomWords();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.red,
        ),
        home: Consumer(
          builder: (context, UserRepository user, _) {
            AppGlobals.user = user;
            return RandomWords();
          },
        ));
  }

  Widget getRandomWordsList() {
    if (randomWords != null) {
      return randomWords;
    } else {
      return RandomWords();
    }
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final TextStyle _biggerFont = const TextStyle(fontSize: 15);
  var _snappingController = SnappingSheetController();

  Widget _buildSuggestions() {
    // unfocus keyboard
    FocusScope.of(context).unfocus();

    return SnappingSheet(
        snappingSheetController: _snappingController,
        onSnapEnd: () {
          setState(() {});
        },
        onMove: (_) {
          if (_snappingController.currentSnapPosition != null) {
            var epsilon = 0.9;
            RenderBox renderBox =
                _grabbingKey.currentContext.findRenderObject();
            Offset position = renderBox.localToGlobal(Offset.zero);
            double screenSize = MediaQuery.of(context).size.height;
            double blurRatio = ((screenSize - position.dy) / 80) *
                ((screenSize - position.dy) / 80);

            if (position.dy >= screenSize * epsilon) {
              blurRatio = 0;
            }
            if (blurRatio == 0 && blurAmount == 0) {
              return;
            }
            if (blurRatio > 0 &&
                blurRatio < blurAmount + 2 &&
                blurRatio > blurAmount - 2) {
              // print("returning without set state");
              return;
            }
            setState(() {
              blurAmount = blurRatio;
            });
          } else {
            setState(() {
              blurAmount = 0;
            });
          }
        },
        child: blurAmount > 0
            ? Stack(
                children: [
                  ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemBuilder: (BuildContext _context, int i) {
                        if (i.isOdd) {
                          return Divider();
                        }
                        final int index = i ~/ 2;
                        if (index >= _suggestions.length) {
                          _suggestions.addAll(generateWordPairs().take(10));
                        }
                        return _buildRow(_suggestions[index]);
                      }),
                  Container(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: blurAmount, sigmaY: blurAmount),
                      child: Container(
                        color: Colors.white.withOpacity(0),
                      ),
                    ),
                  )
                ],
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemBuilder: (BuildContext _context, int i) {
                  if (i.isOdd) {
                    return Divider();
                  }
                  final int index = i ~/ 2;
                  if (index >= _suggestions.length) {
                    _suggestions.addAll(generateWordPairs().take(10));
                  }
                  return _buildRow(_suggestions[index]);
                }),
        sheetBelow: isUserAuthenticated()
            ? SnappingSheetContent(
                child: UserProfileContent(_snappingController))
            : null,
        grabbing: isUserAuthenticated()
            ? Container(
                key: _grabbingKey,
                color: Colors.blueGrey[100],
                padding: EdgeInsets.all(18),
                alignment: Alignment.center,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Expanded(
                    flex: 1,
                    child: Text('Welcome back, ' + AppGlobals.user.getEmail(),
                        style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 15.0)),
                  ),
                  InkWell(
                    child: getUpOrDownIcon(_snappingController),
                    onTap: () {
                      SnapPosition bottom =
                          _snappingController.snapPositions[0];
                      SnapPosition top = _snappingController.snapPositions[1];

                      // print(_snappingController.snapPositions);
                      setState(() {
                        if (_snappingController.currentSnapPosition == top) {
                          _snappingController.snapToPosition(bottom);
                        } else {
                          _snappingController.snapToPosition(top);
                        }
                      });
                    },
                  )
                ]),
              )
            : null,
        grabbingHeight: 55,
        snapPositions: [
          SnapPosition(
              positionPixel: bottomSnappingPositionHeight,
              snappingCurve: Curves.linearToEaseOut,
              snappingDuration: Duration(milliseconds: 750)),
          SnapPosition(
              positionPixel: topSnappingPositionHeight,
              snappingCurve: Curves.linearToEaseOut,
              snappingDuration: Duration(milliseconds: 750)),
        ]);
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = AppGlobals.user.isFavorite(pair.asPascalCase);

    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            AppGlobals.user.removeFavorite(pair.asPascalCase);
          } else {
            AppGlobals.user.addFavorite(pair.asPascalCase);
          }
        });
      },
    );
  }

  Widget build(BuildContext context) {
    return Consumer(builder: (context, UserRepository user, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Startup Name Generator'),
          actions: [
            IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
            isUserAuthenticated()
                ? IconButton(icon: Icon(Icons.exit_to_app), onPressed: _signOut)
                : IconButton(icon: Icon(Icons.login), onPressed: _loginScreen)
          ],
        ),
        body: _buildSuggestions(),
      );
    });
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return FavoritesPage();
        }, // ...to here.
      ),
    );
  }

  void _signOut() {
    AppGlobals.user.signOut();
  }

  void _loginScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Consumer(builder: (context, UserRepository user, _) {
            return LoginPage();
          });
        }, // ...to here.
      ),
    );
  }

  isUserAuthenticated() {
    if (AppGlobals.user != null) {
      if (AppGlobals.user.status == Status.Authenticated) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  getUpOrDownIcon(SnappingSheetController snappingController) {
    SnapPosition bottom = _snappingController.snapPositions[0];
    SnapPosition top = _snappingController.snapPositions[1];
    SnapPosition current = _snappingController.currentSnapPosition;
    if (current != null) {
      // print("crnt = " + current.positionPixel.toString());
    } else {
      // print("crnt = is null");
    }

    if (current == null || current.positionPixel == bottom.positionPixel) {
      return Icon(
        Icons.keyboard_arrow_up,
        color: Colors.black,
      );
    } else {
      return Icon(
        Icons.keyboard_arrow_down,
        color: Colors.black,
      );
    }
  }
}

class UserProfileContent extends StatefulWidget {
  final SnappingSheetController _snappingController;

  UserProfileContent(this._snappingController);

  @override
  _UserProfileContentState createState() => _UserProfileContentState();
}

class _UserProfileContentState extends State<UserProfileContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        height: 40,
        child: Row(children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Container(
                  alignment: Alignment.topCenter,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                          padding: new EdgeInsets.fromLTRB(8, 0, 12, 15),
                          child: CircleAvatar(
                              minRadius: 33,
                              maxRadius: 33,
                              backgroundColor: user.hasAvatar()
                                  ? Colors.transparent
                                  : Colors.red,
                              child: ClipOval(
                                child: user.hasAvatar()
                                    ? Image.network(user.getAvatarUrl(),
                                        fit: BoxFit.fill)
                                    : Text(createInitialsFromMail(user),
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 28)),
                              ))),
                    ],
                  )),
            ),
          ),
          Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Container(
                    color: Colors.white,
                    padding: new EdgeInsets.fromLTRB(0, 0, 15, 15),
                    alignment: Alignment.topLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          child: Container(
                            child: Text(AppGlobals.user.getEmail(),
                                style: TextStyle(
                                    fontFamily: 'Montserrat', fontSize: 20.0)),
                          ),
                        ),
                        SingleChildScrollView(
                          child: Container(
                              // color: Colors.blue,
                              child: ButtonTheme(
                                  minWidth: 50,
                                  height: 25,
                                  child: RaisedButton(
                                      color: Colors.teal[600],
                                      textTheme: ButtonTextTheme.normal,
                                      textColor: Colors.white,
                                      onPressed: () async {
                                        if (await AppGlobals.user
                                                .chooseNewAvatar() ==
                                            null) {

                                          Scaffold.of(context).showSnackBar(
                                              SnackBar(
                                                  content:
                                                      Text('No image selected'),
                                                  duration:
                                                      Duration(seconds: 3)));
                                        }
                                      },
                                      child: Text('Change avatar',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontFamily: 'Montserrat',
                                              fontSize: 15.0)),
                                      shape: BeveledRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(1.0),
                                        // side: BorderSide(color: Colors.red)
                                      )))),
                        )
                      ],
                    )),
              ))
        ]));
  }

  String createInitialsFromMail(UserRepository user) {
    String mail = user.getEmail();
    String initials = "" + mail[0];
    return initials.toUpperCase();
  }
}
