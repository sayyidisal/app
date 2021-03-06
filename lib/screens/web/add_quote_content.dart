import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import 'package:memorare/components/web/nav_back_header.dart';
import 'package:memorare/data/add_quote_inputs.dart';
import 'package:memorare/screens/web/add_quote_layout.dart';
import 'package:memorare/screens/web/add_quote_nav_buttons.dart';
import 'package:memorare/state/colors.dart';
import 'package:memorare/utils/on_long_press_nav_back.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';

class AddQuoteContent extends StatefulWidget {
  @override
  _AddQuoteContentState createState() => _AddQuoteContentState();
}

class _AddQuoteContentState extends State<AddQuoteContent> {
  final beginY    = 100.0;
  final delay     = 1.0;
  final delayStep = 1.2;

  bool isKeyHandled = false;

  FocusNode nameFocusNode;
  FocusNode clearFocusNode;

  List<String> langs = ['en', 'fr'];

  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameFocusNode = FocusNode();
    clearFocusNode = FocusNode();
    nameController.text = AddQuoteInputs.quote.name;
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    clearFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AddQuoteLayout(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              NavBackHeader(
                onLongPress: () => onLongPressNavBack(context),
              ),
              body(),
            ],
          ),

          Positioned(
            right: 120.0,
            top: 85.0,
            child: IconButton(
              onPressed: () {
                FluroRouter.router.navigateTo(
                  context,
                  AddQuoteTopicsRoute,
                );
              },
              icon: Icon(
                Icons.arrow_forward,
              ),
            ),
          ),

          Positioned(
            right: 50.0,
            top: 70.0,
            child: helpButton(),
          ),
        ],
      ),
    );
  }

  Widget body() {
    return SizedBox(
      width: 500.0,
      child: Column(
        children: <Widget>[
          FadeInY(
            beginY: beginY,
            child: title(),
          ),

          FadeInY(
            delay: delay + (1 * delayStep),
            beginY: beginY,
            child: quoteNameInput(),
          ),

          FadeInY(
            delay: delay + (2 * delayStep),
            beginY: beginY,
            child: clearButton(),
          ),

          FadeInY(
            delay: delay + (3 * delayStep),
            beginY: beginY,
            child: langSelect(),
          ),

          FadeInY(
            delay: delay + (4 * delayStep),
            beginY: beginY,
            child: AddQuoteNavButtons(
              onPrevPressed: () => FluroRouter.router.pop(context),
              prevMessage: 'Cancel',
              onNextPressed: () => FluroRouter.router.navigateTo(context, AddQuoteTopicsRoute),
            ),
          ),
        ],
      ),
    );
  }

  Widget clearButton() {
    return Padding(
      padding: EdgeInsets.only(right: 25.0, bottom: 60.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FlatButton(
            focusNode: clearFocusNode,
            onPressed: () {
              AddQuoteInputs.quote.name = '';
              nameController.clear();
              nameFocusNode.requestFocus();
            },
            child: Opacity(
              opacity: 0.6,
              child: Text(
                'Clear quote content',
              ),
            )
          ),
        ],
      ),
    );
  }

  Widget helpButton() {
    return IconButton(
      iconSize: 40.0,
      icon: Opacity(
        opacity: .6,
        child: Icon(Icons.help)
      ),
      padding: EdgeInsets.symmetric(vertical: 20.0),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext context) {
            return Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 500.0,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40.0),
                      child: Text(
                        'Help',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25.0,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 500.0,
                    child: Opacity(
                      opacity: .6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              "• Only the quote's content and a topic are required for submission",
                              style: TextStyle(
                                fontSize: 17.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              '• Your quote should be short (<200 characters), catchy and memorable',
                              style: TextStyle(
                                fontSize: 17.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              '• Quotes with an author or a reference are preferred. A reference can be a movie, a book, a song, a game or from any cultural material',
                              style: TextStyle(
                                fontSize: 17.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              '• The moderators can reject, remove or modify your quotes without notice, before or after validation',
                              style: TextStyle(
                                fontSize: 17.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              '• Explicit, offensive and disrespectful words and ideas can be rejected',
                              style: TextStyle(
                                fontSize: 17.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              "• Long press the green 'propose' button at any step to save your quote in drafts",
                              style: TextStyle(
                                fontSize: 17.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 100.0),
                    child: RaisedButton(
                      onPressed: () {
                        FluroRouter.router.pop(context);
                      },
                      color: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Text('Close'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget langSelect() {
    return DropdownButton<String>(
      value: AddQuoteInputs.quote.lang,
      style: TextStyle(
        color: stateColors.primary,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
      underline: Container(
        height: 2.0,
        color: stateColors.primary,
      ),
      onChanged: (newValue) {
        setState(() {
          AddQuoteInputs.quote.lang = newValue;
        });
      },
      items: langs.map<DropdownMenuItem<String>>((value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value.toUpperCase()),
        );
      }).toList(),
    );
  }

  Widget quoteNameInput() {
    return Padding(
      padding: EdgeInsets.only(
        left: 40.0,
        right: 40.0,
        top: 100.0,
      ),
      child: TextField(
        maxLines: null,
        autofocus: true,
        focusNode: nameFocusNode,
        controller: nameController,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (newValue) {
          AddQuoteInputs.quote.name = newValue;
        },
        style: TextStyle(
          fontSize: 22.0,
        ),
        decoration: InputDecoration(
          hintText: 'Type your quote...',
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: stateColors.primary,
              width: 2.0,
            )
          ),
        ),
      ),
    );
  }

  Widget title() {
    return Column(
      children: <Widget>[
        Text(
          'Add content',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),

        Opacity(
          opacity: 0.6,
          child: Text(
            '1/5',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
