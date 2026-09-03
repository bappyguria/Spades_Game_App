import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'game_screen.dart';

class BidScreen extends StatefulWidget {
  final String roomId;

  const BidScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<BidScreen> createState() =>
      _BidScreenState();
}

class _BidScreenState
    extends State<BidScreen> {

  int bid = 0;

  bool submitted = false;

  Future<void> submitBid() async {

    final uid =
        FirebaseAuth.instance
            .currentUser!
            .uid;

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.roomId)
        .update({

      "bids.$uid": bid,
    });

    setState(() {
      submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xff0B2341),

      body: SafeArea(
        child: StreamBuilder<
            DocumentSnapshot>(
          stream:
              FirebaseFirestore
                  .instance
                  .collection("rooms")
                  .doc(widget.roomId)
                  .snapshots(),

          builder:
              (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            final data =
                snapshot.data!.data()
                    as Map<String,
                        dynamic>;

            final bids =
                data["bids"] ?? {};

            final players =
                data["players"] ?? [];

            /// All Players Bid Complete

            if (bids.length == 4) {

              WidgetsBinding.instance
                  .addPostFrameCallback(
                (_) {

                  Navigator
                      .pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GameScreen(
                        roomId:
                            widget.roomId,
                      ),
                    ),
                  );
                },
              );
            }

            return Padding(
              padding:
                  const EdgeInsets.all(
                      20),

              child: Column(
                children: [

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    "PLACE YOUR BID",
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: 150,
                    height: 150,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      shape:
                          BoxShape.circle,
                    ),

                    child: Center(
                      child: Text(
                        "$bid",
                        style:
                            const TextStyle(
                          fontSize:
                              60,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [

                      IconButton(
                        iconSize: 50,
                        color:
                            Colors.white,
                        onPressed:
                            submitted
                                ? null
                                : () {

                                    if (bid >
                                        0) {

                                      setState(
                                          () {

                                        bid--;
                                      });
                                    }
                                  },
                        icon:
                            const Icon(
                          Icons.remove,
                        ),
                      ),

                      const SizedBox(
                        width: 40,
                      ),

                      IconButton(
                        iconSize: 50,
                        color:
                            Colors.white,
                        onPressed:
                            submitted
                                ? null
                                : () {

                                    if (bid <
                                        13) {

                                      setState(
                                          () {

                                        bid++;
                                      });
                                    }
                                  },
                        icon:
                            const Icon(
                          Icons.add,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 55,

                    child:
                        ElevatedButton(
                      onPressed:
                          submitted
                              ? null
                              : submitBid,

                      child: Text(
                        submitted
                            ? "WAITING..."
                            : "CONFIRM BID",
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  Text(
                    "${bids.length}/${players.length} Players Ready",
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 18,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}