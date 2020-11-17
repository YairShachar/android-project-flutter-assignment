import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'user.dart';

const double buttonWidth = 340;
const double padding = 15;
String passwordConfirmErrorMessage;
TextEditingController _email;
TextEditingController _password;
TextEditingController _passwordConfirm;
final _formKey = GlobalKey<FormState>();
final _key = GlobalKey<ScaffoldState>();

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);

  bool validationError = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: "");
    _password = TextEditingController(text: "");
    _passwordConfirm = TextEditingController(text: "");
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserRepository>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text('Login Screen'),
        ),
        key: _key,
        body: Form(
            key: _formKey,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: new EdgeInsets.fromLTRB(0, padding, 0, padding),
                    width: buttonWidth,
                    child: Text(
                        'Welcome to Startup Names Generator, please log in below'),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: new EdgeInsets.fromLTRB(0, padding, 0, padding),
                    width: buttonWidth,
                    child: TextFormField(
                        controller: _email,
                        obscureText: false,
                        decoration: InputDecoration(
                          //   border: OutlineInputBorder(),
                          labelText: 'Email',
                        )),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: new EdgeInsets.fromLTRB(0, 0, 0, padding),
                    width: buttonWidth,
                    child: TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          //   border: OutlineInputBorder(),
                          labelText: 'Password',
                        )),
                  ),
                  Builder(builder: (BuildContext context) {
                    return Container(
                        alignment: Alignment.center,
                        padding: new EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: ButtonTheme(
                            minWidth: buttonWidth,
                            child: user.status == Status.Authenticating
                                ? Center(child: CircularProgressIndicator())
                                : RaisedButton(
                                    color: Colors.red,
                                    textTheme: ButtonTextTheme.primary,
                                    textColor: Colors.white,
                                    onPressed: () async {
                                      if (_formKey.currentState.validate()) {
                                        if (!await user.signIn(
                                            _email.text, _password.text)) {
                                          _key.currentState
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                "There was an error logging into the app"),
                                          ));
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    child: Text('Log in'),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        side: BorderSide(color: Colors.red)))));
                  }),
                  //
                  Builder(builder: (BuildContext context) {
                    return SignUpButton();
                  })
                ])));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  static SnackBar createTextSnackBar(String s) {
    SnackBar snackbar =
        SnackBar(content: Text(s), duration: Duration(seconds: 3));
    return snackbar;
  }
}

class SignUpButton extends StatefulWidget {
  @override
  _SignUpButtonState createState() => _SignUpButtonState();
}

class _SignUpButtonState extends State<SignUpButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        padding: new EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: ButtonTheme(
            minWidth: buttonWidth,
            child: RaisedButton(
                color: Colors.teal,
                textTheme: ButtonTextTheme.primary,
                textColor: Colors.white,
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: _key.currentContext,
                      builder: (BuildContext context) {
                        return PasswordConfirmModalBottomSheet();
                      });
                },
                child: Text('New user? Click to sign up'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                    side: BorderSide(color: Colors.teal)))));
  }
}

class PasswordConfirmModalBottomSheet extends StatefulWidget {
  @override
  _PasswordConfirmModalBottomSheetState createState() =>
      _PasswordConfirmModalBottomSheetState();
}

class _PasswordConfirmModalBottomSheetState
    extends State<PasswordConfirmModalBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserRepository>(context);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: new Container(
          height: 230,
          color: Colors.white,
          child: Form(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                Container(
                  alignment: Alignment.center,
                  padding: new EdgeInsets.fromLTRB(0, padding, 0, padding),
                  width: buttonWidth,
                  child: Text('Please confirm your password below:'),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: new EdgeInsets.fromLTRB(0, padding, 0, padding),
                  width: buttonWidth,
                  child: Builder(builder: (BuildContext context) {
                    return TextFormField(
                        onChanged: (_) {
                          setState(() {
                            passwordConfirmErrorMessage = null;
                          });
                        },
                        controller: _passwordConfirm,
                        obscureText: true,
                        decoration: InputDecoration(
                          errorText: passwordConfirmErrorMessage == null
                              ? null
                              : passwordConfirmErrorMessage,
                          labelText: 'Password',
                        ));
                  }),
                ),
                // Confirm button
                ButtonTheme(
                    minWidth: 60,
                    height: 40,
                    child: RaisedButton(
                        color: Colors.teal,
                        textTheme: ButtonTextTheme.normal,
                        textColor: Colors.white,
                        onPressed: () async {
                          if (doPasswordsMatch()) {
                            if (!await user.registerNewUser(
                                _email.text, _passwordConfirm.text)) {
                            } else {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          } else {
                            setState(() {
                              passwordConfirmErrorMessage =
                                  'Passwords must match!';
                            });
                          }
                        },
                        child: Text('Confirm'),
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(1.0),
                          // side: BorderSide(color: Colors.red)
                        ))),
              ]))),
    );
  }

  doPasswordsMatch() {
    if (_passwordConfirm.text == _password.text) {
      print(' doPasswordsMatch: passwords match! ');
      return true;
    } else {
      print(' doPasswordsMatch: passwords don\'t match! ');
      return false;
    }
  }
}
