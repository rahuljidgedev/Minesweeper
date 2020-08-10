import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Minesweeper',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: GameGridApp(title: "Minesweeper"));
  }
}

class GameGridApp extends StatefulWidget {
  GameGridApp({this.title}) : super();
  final String title;

  @override
  _MyGridAppState createState() => _MyGridAppState(title);
}

class _MyGridAppState extends State<GameGridApp> {
  String title;
  bool gameWon = false;
  int rows,
      columns,
      topLeft,
      gridSize,
      top,
      topRight,
      left,
      right,
      bottomLeft,
      bottom,
      bottomRight,
      remainingBlocks;
  var map;
  var statusMap;
  var flaggedMap;
  List<Widget> blockList = [];

  _MyGridAppState(String title) {
    this.title = title;
    _createNewGame(4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.grid_on, color: Colors.white, size: 32),
              onPressed: () => _setGridSize(),
            ),
            IconButton(
              icon: Icon(Icons.play_circle_outline,
                  color: Colors.white, size: 32),
              onPressed: () => {_createNewGame(0)},
            ),
            IconButton(
                icon: Icon(Icons.close, color: Colors.black54, size: 32),
                onPressed: () => exit(0)),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.all(16),
              child: Text(
                remainingBlocks.toString() + " blocks left.",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.black45,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: columns,
                childAspectRatio: (MediaQuery.of(context).size.width / 2) / (MediaQuery.of(context).size.height / 4),
                children: List.generate(rows * columns, (index) {
                  if(flaggedMap[index]) {
                    return Container(
                      margin: EdgeInsets.all(8),
                      child: Material(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(8))),
                          child: InkWell(
                            onLongPress: () => _flagTheMine(index),
                            child: Container(
                              margin: EdgeInsets.all(gameWon ? 6 : 12),
                              child: Image(
                                image: AssetImage('assets/flagged_mine.png'),
                              ),
                            ),
                          ),
                      ),
                    );
                  }else if (!statusMap[index]) {
                    return Container(
                        margin: EdgeInsets.all(8),
                        child: Material(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          child: RaisedButton(
                            onPressed: () => _processTap(index),
                            onLongPress: () => _flagTheMine(index),
                            color: Colors.white70,
                            splashColor: Colors.teal,
                          ),
                        ));
                  } else if (statusMap[index] && map[index] == -1) {
                    return Container(
                      margin: EdgeInsets.all(8),
                      child: Material(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          child: Container(
                            margin: EdgeInsets.all(gameWon ? 6 : 12),
                            child: Image(
                              image: gameWon
                                  ? AssetImage('assets/won_flag.png')
                                  : AssetImage('assets/mine.png'),
                            ),
                          )),
                    );
                  } else if (statusMap[index] && map[index] > 0) {
                    return Container(
                      margin: EdgeInsets.all(8),
                      child: Material(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: Center(
                            child: Text(
                          map[index].toString(),
                          style: TextStyle(
                              color: Colors.pink,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        )),
                      ),
                    );
                  } else {
                    return Container(
                      margin: EdgeInsets.all(8),
                      child: Material(
                        elevation: 2,
                        color: Colors.black12,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                      ),
                    );
                  }
                }),
              ),
            )
          ],
        ));
  }

  _deriveMinesMap(List map) {
    final rMin = 0, rMax = rows - 1, cMin = 0, cMax = columns - 1;
    int mineCount = 0;
    /*Calculate for set A {0}*/
    if (map[rMin * cMin] != -1) {
      if (map[right] == -1) mineCount++;
      if (map[bottom] == -1) mineCount++;
      if (map[bottomRight] == -1) mineCount++;
      map[rMin * cMin] = mineCount;
    }
    /*Calculate for set B {1,2,3}*/
    for (var i = cMin + 1; i < cMax; i++) {
      if (map[rMin + (cMin + i)] != -1) {
        mineCount = 0;
        if (map[rMin + (cMin + i) + left] == -1) mineCount++;
        if (map[rMin + (cMin + i) + right] == -1) mineCount++;
        if (map[rMin + (cMin + i) + bottomLeft] == -1) mineCount++;
        if (map[rMin + (cMin + i) + bottom] == -1) mineCount++;
        if (map[rMin + (cMin + i) + bottomRight] == -1) mineCount++;
        map[rMin + (cMin + i)] = mineCount;
      }
    }

    /*Calculate for set C {4}*/
    if (map[rMin + cMax] != -1) {
      mineCount = 0;
      if (map[(rMin + cMax) + left] == -1) mineCount++;
      if (map[(rMin + cMax) + bottomLeft] == -1) mineCount++;
      if (map[(rMin + cMax) + bottom] == -1) mineCount++;
      map[rMin + cMax] = mineCount;
    }

    /*Calculate for set D {5,10,15}*/
    for (var i = rMin + 1; i < rMax; i++) {
      if (map[i * (cMax + 1)] != -1) {
        mineCount = 0;
        if (map[(i * (cMax + 1)) + top] == -1) mineCount++;
        if (map[(i * (cMax + 1)) + topRight] == -1) mineCount++;
        if (map[(i * (cMax + 1)) + right] == -1) mineCount++;
        if (map[(i * (cMax + 1)) + bottom] == -1) mineCount++;
        if (map[(i * (cMax + 1)) + bottomRight] == -1) mineCount++;
        map[i * (cMax + 1)] = mineCount;
      }
    }

    /*Calculate for set E {6,7,8,11,12,13,16,17,18}*/
    for (var i = rMin + 1; i < rMax; i++) {
      for (var j = cMin + 1; j < cMax; j++) {
        if (map[i * (cMax + 1) + j] != -1) {
          mineCount = 0;
          if (map[(i * (cMax + 1) + j) + topLeft] == -1) mineCount++;
          if (map[(i * (cMax + 1) + j) + top] == -1) mineCount++;
          if (map[(i * (cMax + 1) + j) + topRight] == -1) mineCount++;
          if (map[(i * (cMax + 1) + j) + left] == -1) mineCount++;
          if (map[(i * (cMax + 1) + j) + right] == -1) mineCount++;
          if (map[(i * (cMax + 1) + j) + bottomLeft] == -1) mineCount++;
          if (map[(i * (cMax + 1) + j) + bottom] == -1) mineCount++;
          if (map[(i * (cMax + 1) + j) + bottomRight] == -1) mineCount++;
          map[i * (cMax + 1) + j] = mineCount;
        }
      }
    }
    /*Calculate for set F {9,14,19}*/
    for (var i = rMin + 1; i < rMax; i++) {
      if (map[i * (cMax + 1) + cMax] != -1) {
        mineCount = 0;
        if (map[(i * (cMax + 1) + cMax) + topLeft] == -1) mineCount++;
        if (map[(i * (cMax + 1) + cMax) + top] == -1) mineCount++;
        if (map[(i * (cMax + 1) + cMax) + left] == -1) mineCount++;
        if (map[(i * (cMax + 1) + cMax) + bottomLeft] == -1) mineCount++;
        if (map[(i * (cMax + 1) + cMax) + bottom] == -1) mineCount++;
        map[i * (cMax + 1) + cMax] = mineCount;
      }
    }

    /*Calculate for set G {20}*/
    if (map[rMax * (cMax + 1)] != -1) {
      mineCount = 0;
      if (map[(rMax * (cMax + 1)) + top] == -1) mineCount++;
      if (map[(rMax * (cMax + 1)) + topRight] == -1) mineCount++;
      if (map[(rMax * (cMax + 1)) + right] == -1) mineCount++;
      map[rMax * (cMax + 1)] = mineCount;
    }

    /*Calculate for set H {21,22,23}*/
    for (var i = cMin + 1; i < cMax; i++) {
      if (map[rMax * (cMax + 1) + i] != -1) {
        mineCount = 0;
        if (map[(rMax * (cMax + 1) + i) + topLeft] == -1) mineCount++;
        if (map[(rMax * (cMax + 1) + i) + top] == -1) mineCount++;
        if (map[(rMax * (cMax + 1) + i) + topRight] == -1) mineCount++;
        if (map[(rMax * (cMax + 1) + i) + left] == -1) mineCount++;
        if (map[(rMax * (cMax + 1) + i) + right] == -1) mineCount++;
        map[rMax * (cMax + 1) + i] = mineCount;
      }
    }

    /*Calculate for set I {24}*/
    if (map[(rMax * (cMax + 1)) + cMax] != -1) {
      mineCount = 0;
      if (map[((rMax * (cMax + 1)) + cMax) + topLeft] == -1) mineCount++;
      if (map[((rMax * (cMax + 1)) + cMax) + top] == -1) mineCount++;
      if (map[((rMax * (cMax + 1)) + cMax) + left] == -1) mineCount++;
      map[(rMax * (cMax + 1)) + cMax] = mineCount;
    }
    return map;
  }

  _populateMinesInTheMap(int sizeOfMap) {
    var map = List.filled(sizeOfMap, 0);
    int numberOfMines = (sizeOfMap * 0.30).floor();
    remainingBlocks = map.length - numberOfMines;
    var random = new Random();
    for (var i = 0; i < numberOfMines; i++) {
      map[random.nextInt(map.length)] = -1;
    }
    return map;
  }

  _processTap(int index) {
    /*if user tapped the mine block.*/
    if (map[index] == -1) {
      statusMap = List.filled((rows * columns), true);
      flaggedMap = List.filled((rows * columns), false);
      Fluttertoast.showToast(
          msg: 'You lost.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white);
      /*if used tapped any number block.*/
    } else {
      statusMap[index] = true;
      remainingBlocks--;
      if (remainingBlocks == 0) {
        gameWon = true;
        statusMap = List.filled((rows * columns), true);
        flaggedMap= List.filled((rows * columns), false);
        Fluttertoast.showToast(
            msg: 'You won.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIos: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    }
    setState(() {
      statusMap = statusMap;
    });
  }

  _createNewGame(int gridSize) {
    gameWon = false;
    if (gridSize != 0) rows = columns = this.gridSize = gridSize;
    statusMap = List.filled((rows * columns), false);
    flaggedMap = List.filled((rows * columns), false);
    topLeft = -columns - 1;
    top = -columns;
    topRight = -columns + 1;
    left = -1;
    right = 1;
    bottomLeft = columns - 1;
    bottom = columns;
    bottomRight = columns + 1;
    map = _populateMinesInTheMap(rows * columns);
    map = _deriveMinesMap(map);
    if (gridSize == 0) {
      setState(() {});
    }
  }

  _setGridSize() {
    if (gridSize == 4) {
      gridSize = rows = columns = 5;
    } else if (gridSize == 5) {
      gridSize = rows = columns = 6;
    } else if (gridSize == 6) {
      gridSize = rows = columns = 4;
    }
    _createNewGame(gridSize);
    setState(() {});
  }

  _flagTheMine(int index) {
    flaggedMap[index] = !flaggedMap[index];
    setState(() {});
  }
}
