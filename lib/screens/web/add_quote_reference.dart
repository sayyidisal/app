import 'package:flutter/material.dart';
import 'package:memorare/common/icons_more_icons.dart';
import 'package:memorare/components/web/fade_in_y.dart';
import 'package:memorare/components/web/nav_back_header.dart';
import 'package:memorare/data/add_quote_inputs.dart';
import 'package:memorare/screens/web/add_quote_layout.dart';
import 'package:memorare/screens/web/add_quote_nav_buttons.dart';
import 'package:memorare/state/colors.dart';
import 'package:memorare/utils/on_long_press_nav_back.dart';
import 'package:memorare/router/route_names.dart';
import 'package:memorare/router/router.dart';

class AddQuoteReference extends StatefulWidget {
  @override
  _AddQuoteReferenceState createState() => _AddQuoteReferenceState();
}

class _AddQuoteReferenceState extends State<AddQuoteReference> {
  final beginY    = 100.0;
  final delay     = 1.0;
  final delayStep = 1.2;

  String tempImgUrl = '';

  List<String> langs = ['en', 'fr'];

  final nameFocusNode = FocusNode();

  final affiliateUrlController   = TextEditingController();
  final amazonUrlController      = TextEditingController();
  final facebookUrlController    = TextEditingController();
  final nameController           = TextEditingController();
  final netflixUrlController     = TextEditingController();
  final primaryTypeController    = TextEditingController();
  final primeVideoUrlController  = TextEditingController();
  final secondaryTypeController  = TextEditingController();
  final summaryController        = TextEditingController();
  final twitterUrlController     = TextEditingController();
  final twitchUrlController      = TextEditingController();
  final websiteUrlController     = TextEditingController();
  final wikiUrlController        = TextEditingController();
  final youtubeUrlController     = TextEditingController();

  @override
  initState() {
    setState(() {
      affiliateUrlController.text   = AddQuoteInputs.reference.urls.affiliate;
      amazonUrlController.text      = AddQuoteInputs.reference.urls.amazon;
      facebookUrlController.text    = AddQuoteInputs.reference.urls.facebook;
      nameController.text           = AddQuoteInputs.reference.name;
      netflixUrlController.text     = AddQuoteInputs.reference.urls.netflix;
      primeVideoUrlController.text  = AddQuoteInputs.reference.urls.primeVideo;
      primaryTypeController.text    = AddQuoteInputs.reference.type.primary;
      secondaryTypeController.text  = AddQuoteInputs.reference.type.secondary;
      summaryController.text        = AddQuoteInputs.reference.summary;
      twitterUrlController.text     = AddQuoteInputs.reference.urls.twitter;
      twitchUrlController.text      = AddQuoteInputs.reference.urls.twitch;
      websiteUrlController.text     = AddQuoteInputs.reference.urls.website;
      wikiUrlController.text        = AddQuoteInputs.reference.urls.wikipedia;
      youtubeUrlController.text     = AddQuoteInputs.reference.urls.youtube;
    });

    super.initState();
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
                  AddQuoteCommentRoute,
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
          )
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
            child: avatar(),
          ),

          FadeInY(
            delay: delay + (2 * delayStep),
            beginY: beginY,
            child: nameField(),
          ),

          FadeInY(
            delay: delay + (3 * delayStep),
            beginY: beginY,
            child: typesFields(),
          ),

          FadeInY(
            delay: delay + (4 * delayStep),
            beginY: beginY,
            child: langAndSummary(),
          ),

          FadeInY(
            delay: delay + (5 * delayStep),
            beginY: beginY,
            child: links(),
          ),

          FadeInY(
            delay: delay + (6 * delayStep),
            beginY: beginY,
            child: clearButton(),
          ),

          FadeInY(
            delay: delay + (7 * delayStep),
            beginY: beginY,
            child: AddQuoteNavButtons(
              onPrevPressed: () => FluroRouter.router.pop(context),
              onNextPressed: () => FluroRouter.router.navigateTo(context, AddQuoteCommentRoute),
            ),
          ),
        ],
      ),
    );
  }

  Widget clearButton() {
    return FlatButton(
      padding: EdgeInsets.all(10.0),
      onPressed: () {
        AddQuoteInputs.clearReference();

        amazonUrlController.clear();
        facebookUrlController.clear();
        nameController.clear();
        netflixUrlController.clear();
        primaryTypeController.clear();
        primeVideoUrlController.clear();
        secondaryTypeController.clear();
        summaryController.clear();
        twitchUrlController.clear();
        twitterUrlController.clear();
        websiteUrlController.clear();
        wikiUrlController.clear();
        youtubeUrlController.clear();

        setState(() {});

        nameFocusNode.requestFocus();
      },
      child: Opacity(
        opacity: 0.6,
        child: Text(
          'Clear reference information',
        ),
      ),
    );
  }

  Widget helpButton() {
    return IconButton(
      iconSize: 40.0,
      icon: Opacity(
        opacity: .6,
        child: Icon(Icons.help,)
      ),
      padding: EdgeInsets.symmetric(vertical: 20.0),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.all(40.0),
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
                              '• Reference information are optional',
                              style: TextStyle(
                                fontSize: 17.0,
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
                            child: Text(
                              '• If you select the reference\'s name in the dropdown list, other fields can stay empty',
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

  Widget avatar() {
    return Padding(
      padding: EdgeInsets.only(top: 50.0, bottom: 30.0),
      child: Card(
        child: AddQuoteInputs.reference.urls.image.length > 0 ?
          Ink.image(
            width: 200.0,
            height: 250.0,
            fit: BoxFit.cover,
            image: NetworkImage(AddQuoteInputs.reference.urls.image),
            child: InkWell(
              onTap: () => showImageDialog(),
            ),
          ) :
          SizedBox(
            width: 200.0,
            height: 250.0,
            child: InkWell(
              child: Opacity(
                opacity: .6,
                child: Icon(Icons.add, size: 50.0,)
              ),
              onTap: () => showImageDialog(),
            ),
          ),
      ),
    );
  }

  Widget langAndSummary() {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: DropdownButton<String>(
            value: AddQuoteInputs.reference.lang,
            style: TextStyle(
              color: stateColors.primary,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
            underline: Container(
              color: stateColors.primary,
              height: 2.0,
            ),
            onChanged: (newValue) {
              setState(() {
                AddQuoteInputs.reference.lang = newValue;
              });
            },
            items: langs.map<DropdownMenuItem<String>>((value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value.toUpperCase()),
              );
            }).toList(),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(vertical: 50.0),
          child: SizedBox(
            width: 400,
            child: TextField(
              controller: summaryController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Summary',
                alignLabelWithHint: true,
              ),
              minLines: 10,
              maxLines: null,
              onChanged: (newValue) {
                AddQuoteInputs.reference.summary = newValue;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget links() {
    return Column(
      children: <Widget>[
        FadeInY(
          delay: delay + (9 * delayStep),
          beginY: beginY,
          child: SizedBox(
            width: 300,
            child: TextField(
              controller: wikiUrlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(IconsMore.wikipedia_w),
                labelText: 'Wikipedia'
              ),
              onChanged: (newValue) {
                AddQuoteInputs.reference.urls.wikipedia = newValue;
              },
            ),
          ),
        ),

        FadeInY(
          delay: delay + (10 * delayStep),
          beginY: beginY,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: websiteUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(IconsMore.earth),
                  labelText: 'Website'
                ),
                onChanged: (newValue) {
                  AddQuoteInputs.reference.urls.website = newValue;
                },
              ),
            ),
          ),
        ),

        FadeInY(
          delay: delay + (11 * delayStep),
          beginY: beginY,
          child: Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: amazonUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6.0,
                    end: 3.0,
                  ),
                  child: Image.asset(
                    'assets/images/amazon.png',
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxWidth: 36.0,
                ),
                  labelText: 'Amazon'
                ),
                onChanged: (newValue) {
                  AddQuoteInputs.reference.urls.amazon = newValue;
                },
              ),
            ),
          ),
        ),

        FadeInY(
          delay: delay + (12 * delayStep),
          beginY: beginY,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: facebookUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6.0,
                    end: 3.0,
                  ),
                  child: Image.asset(
                    'assets/images/facebook.png',
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxWidth: 36.0,
                ),
                  labelText: 'Facebook'
                ),
                onChanged: (newValue) {
                  AddQuoteInputs.reference.urls.facebook = newValue;
                },
              ),
            ),
          ),
        ),

        FadeInY(
          delay: delay + (13 * delayStep),
          beginY: beginY,
          child: SizedBox(
            width: 300,
            child: TextField(
              controller: twitterUrlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6.0,
                    end: 3.0,
                  ),
                  child: Image.asset(
                    'assets/images/twitter.png',
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxWidth: 36.0,
                ),
                labelText: 'Twitter'
              ),
              onChanged: (newValue) {
                AddQuoteInputs.reference.urls.twitter = newValue;
              },
            ),
          ),
        ),

        FadeInY(
          delay: delay + (14 * delayStep),
          beginY: beginY,
          child: Padding(
            padding: const EdgeInsets.only(top: 45.0),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: twitchUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6.0,
                    end: 3.0,
                  ),
                  child: Image.asset(
                    'assets/images/twitch.png',
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxWidth: 36.0,
                ),
                  labelText: 'Twitch'
                ),
                onChanged: (newValue) {
                  AddQuoteInputs.reference.urls.twitch = newValue;
                },
              ),
            ),
          ),
        ),

        FadeInY(
          delay: delay + (15 * delayStep),
          beginY: beginY,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: netflixUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6.0,
                    end: 3.0,
                  ),
                  child: Image.asset(
                    'assets/images/netflix.png',
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxWidth: 36.0,
                ),
                  labelText: 'Netflix'
                ),
                onChanged: (newValue) {
                  AddQuoteInputs.reference.urls.netflix = newValue;
                },
              ),
            ),
          ),
        ),

        FadeInY(
          delay: delay + (16 * delayStep),
          beginY: beginY,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: primeVideoUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6.0,
                    end: 3.0,
                  ),
                  child: Image.asset(
                    'assets/images/prime-video.png',
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxWidth: 36.0,
                ),
                  labelText: 'Prime Video'
                ),
                onChanged: (newValue) {
                  AddQuoteInputs.reference.urls.primeVideo = newValue;
                },
              ),
            ),
          ),
        ),

        FadeInY(
          delay: delay + (17 * delayStep),
          beginY: beginY,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: youtubeUrlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 6.0,
                    end: 3.0,
                  ),
                  child: Image.asset(
                    'assets/images/youtube.png',
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxWidth: 36.0,
                ),
                  labelText: 'YouTube'
                ),
                onChanged: (newValue) {
                  AddQuoteInputs.reference.urls.youtube = newValue;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget nameField() {
    return SizedBox(
      width: 200.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: TextField(
          autofocus: true,
          focusNode: nameFocusNode,
          controller: nameController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Name',
          ),
          onChanged: (newValue) {
            AddQuoteInputs.reference.name = newValue;
          },
        ),
      ),
    );
  }

  Widget title() {
    return Column(
      children: <Widget>[
        Text(
          'Add reference',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Opacity(
          opacity: 0.6,
          child: Text(
            '4/5',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  Widget typesFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: SizedBox(
        width: 300.0,
        child: Column(
          children: <Widget>[
            TextField(
              controller: primaryTypeController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Primary type (TV Show, Movie, ...)',
              ),
              onChanged: (newValue) {
                AddQuoteInputs.reference.type.primary = newValue;
              },
            ),

            Padding(padding: const EdgeInsets.only(bottom: 10.0)),

            TextField(
              controller: secondaryTypeController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Secondary type (Horror, Thriller, ...)',
              ),
              onChanged: (newValue) {
                AddQuoteInputs.reference.type.secondary  = newValue;
              },
            ),
          ],
        ),
      ),
    );
  }

  void showImageDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.all(
              Radius.circular(5.0)
            ),
          ),

          content: Padding(
            padding: const EdgeInsets.all(40.0),
            child: SizedBox(
              width: 250.0,
              height: 150.0,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: Row(
                      children: <Widget>[
                        Text(
                          "Reference image's URL",
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: AddQuoteInputs.reference.urls.image.length > 0 ?
                        AddQuoteInputs.reference.urls.image : 'URL',
                    ),
                    onChanged: (newValue) {
                      tempImgUrl = newValue;
                    },
                  ),
                ],
              ),
            ),
          ),

          actions: <Widget>[
            FlatButton(
              child: Text(
                'CANCEL',
               ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.green,
                ),
              ),
              onPressed: () {
                setState(() {
                  AddQuoteInputs.reference.urls.image = tempImgUrl;
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      }
    );
  }
}
