import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Art Social App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const TopBar(),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNotifLike(
              username:'Baching',
              iconPath: 'graphics/icons/icon2.jpg',
            ),
            _buildNotif(
              username:'Baching',
              comment: 'Picasso would be proud of...',
              iconPath: 'graphics/icons/icon2.jpg',
            ),
            _buildNotif(
              username:'Haizzle',
              comment: 'What medium did you use...',
              iconPath: 'graphics/icons/icon3.jpg',
            ),
            _buildNotifLike(
              username:'Papricart',
              iconPath: 'graphics/icons/icon4.jpg',
            ),
            _buildNotif(
              username:'Papricart',
              comment: 'The details are detailing!',
              iconPath: 'graphics/icons/icon4.jpg',
            ),
            _buildNotifLike(
              username:'Fufi',
              iconPath: 'graphics/icons/icon5.jpg',
            ),
            _buildNotifLike(
              username:'Zeon',
              iconPath: 'graphics/icons/icon6.jpg',
            ),
            _buildNotif(
              username:'Zeon',
              comment: 'Peter how are you doin dat',
              iconPath: 'graphics/icons/icon6.jpg',
            ),
            _buildNotif(
              username:'Rizzle',
              comment: 'What yarn did you use?',
              iconPath: 'graphics/icons/icon7.jpg',
            ),
            _buildNotifLike(
              username:'Rui-chin',
              iconPath: 'graphics/icons/icon8.jpg',
            ),
            _buildNotifLike(
              username:'Tannerp',
              iconPath: 'graphics/icons/icon9.jpg',
            ),
            _buildNotifLike(
              username:'MeiMei',
              iconPath: 'graphics/icons/icon10.jpg',
            ),
            _buildNotifLike(
              username:'Manong Edgar',
              iconPath: 'graphics/icons/icon11.jpg',
            ),
          ]
        )
      )
    );
  }
}

Widget _buildNotif({
    required String username,
    String comment= '',
    required String iconPath,
}) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        width: 393,
        height: 82.499,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              width: 393,
              top: 0,
              height: 82.499,
              child: Stack(
                children: [
                  Positioned(
                        left: 26,
                        width: 43,
                        top: 19,
                        height: 43,
                        child: Image.asset(iconPath, width: 43, height: 43),
                      ),
                  Positioned(
                    left: 81,
                    top: 42,
                    child: Text(
                      'Commented: "$comment"',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 13, color: const Color(0xff7e7e7e), fontFamily: 'Inter-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    left: 10,
                    width: 373.001,
                    top: 82.499,
                    height: 1,
                    child: Container(
                      width: 373.001,
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffea1a7f), width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 353,
                    width: 15,
                    top: 42,
                    height: 3,
                    child: Image.asset('graphics/Dot.png', width: 15, height: 3,),
                  ),
                  Positioned(
                    left: 26,
                    width: 43,
                    top: 19,
                    height: 43,
                    child: Image.asset('graphics/Profile Icon.png', width: 43, height: 43,),
                  ),
                  Positioned(
                    left: 81,
                    width: 201,
                    top: 22,
                    height: 15,
                    child: Text(
                      username,
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 13, color: const Color(0xff000000), fontFamily: 'Inter-Bold', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    left: 151,
                    width: 13,
                    top: 24,
                    height: 12,
                    child: Image.asset('graphics/Verified Icon.png', width: 13, height: 12,),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildNotifLike({
    required String username,
    required String iconPath,
}) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        width: 393,
        height: 82.499,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              width: 393,
              top: 0,
              height: 82.499,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    width: 393,
                    top: 0,
                    height: 82,
                    child: Container(
                      width: 393,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xfffffdfd),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 81,
                    top: 42,
                    child: Text(
                      'Liked your post!',
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 13, color: const Color(0xff7e7e7e), fontFamily: 'Inter-Regular', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    left: 10,
                    width: 373.001,
                    top: 82.499,
                    height: 1,
                    child: Container(
                      width: 373.001,
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffea1a7f), width: 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 353,
                    width: 15,
                    top: 42,
                    height: 3,
                    child: Image.asset('graphics/Dot.png', width: 15, height: 3,),
                  ),
                  Positioned(
                    left: 26,
                    width: 43,
                    top: 19,
                    height: 43,
                    child: Image.asset('graphics/Profile Icon.png', width: 43, height: 43,),
                  ),
                  Positioned(
                    left: 81,
                    width: 201,
                    top: 22,
                    height: 15,
                    child: Text(
                      username,
                      textAlign: TextAlign.left,
                      style: TextStyle(decoration: TextDecoration.none, fontSize: 13, color: const Color(0xff000000), fontFamily: 'Inter-Bold', fontWeight: FontWeight.normal),
                      maxLines: 9999,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    left: 151,
                    width: 13,
                    top: 24,
                    height: 12,
                    child: Image.asset('graphics/Verified Icon.png', width: 13, height: 12,),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xff14c1e1),
      child: SizedBox(
        width: double.infinity,
        height: 76,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              width: double.infinity,
              top: 0,
              height: 76,
              child: Container(
                width: double.infinity,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xff14c1e1),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 15,
                      left: 0,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_rounded, size: 30),
                        onPressed: () {
                          Navigator.pushNamed(context, "/homescreen");
                        },
                      ),
                    ),
                    Positioned(
                      left: 39,
                      width: 122,
                      top: 27,
                      height: 24,
                      child: Text(
                        'Notifications',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 20,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          fontFamily: 'Inter-Bold',
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 9999,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}