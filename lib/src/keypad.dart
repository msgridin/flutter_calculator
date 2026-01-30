/*
 * Copyright (C) 2019 flytreeleft<flytreeleft@crazydan.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './math_symbol.dart';

const double _numberPadRowHeight = 42.0;

class _NumberPadGridDelegate extends SliverGridDelegate {
  const _NumberPadGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = 3;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double viewTileHeight = constraints.viewportMainAxisExtent / 4.5;
    final double tileHeight = math.max(_numberPadRowHeight, viewTileHeight);

    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_NumberPadGridDelegate oldDelegate) => false;
}

const List<MathSymbol> numberSymbols = <MathSymbol>[
  MathSymbols.seven,
  MathSymbols.eight,
  MathSymbols.nine,
  MathSymbols.four,
  MathSymbols.five,
  MathSymbols.six,
  MathSymbols.one,
  MathSymbols.two,
  MathSymbols.three,
  MathSymbols.clear,
  MathSymbols.decimal,
  MathSymbols.zero,
];

const List<MathSymbol> opSymbols = <MathSymbol>[
  MathSymbols.percent,
  MathSymbols.bracket,
  MathSymbols.divide,
  MathSymbols.multiply,
  MathSymbols.minus,
  MathSymbols.plus,
  MathSymbols.delete,
  // MathSymbols.undo,
];

typedef MathSymbolOnPress = void Function(MathSymbol symbol);

class KeyPad extends StatefulWidget {
  final MathSymbolOnPress onPress;
  final KeyPadController? controller;

  const KeyPad({required this.onPress, this.controller}) : super();

  @override
  State<StatefulWidget> createState() => _KeyPadState();
}

class _KeyPadState extends State<KeyPad> {
  @override
  void initState() {
    if (widget.controller != null) {
      widget.controller?.addListener(_handleChangedDisabledKeys);
    }

    super.initState();
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller?.removeListener(_handleChangedDisabledKeys);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _createNumberSymbolsPane(context, numberSymbols),
        ),
        _createOpSymbolsPane(context, opSymbols),
      ],
    );
  }

  Widget _createNumberSymbolsPane(
    BuildContext context,
    List<MathSymbol> numberSymbols,
  ) {
    final List<Widget> numberPads =
        numberSymbols.map<Widget>((MathSymbol symbol) {
      final bool isClear = symbol == MathSymbols.clear;

      final Widget pad = Container(
        alignment: Alignment.center,
        child: Text(
          symbol.text,
          style: TextStyle(
            color: isClear ? Colors.grey : Colors.grey,
            fontSize: 14.0 * 3.0,
          ),
        ),
      );

      return TextButton(
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          foregroundColor: Colors.grey,
        ),
        onPressed: () => widget.onPress(symbol),
        child: pad,
      );
    }).toList();

    return Center(
      child: GridView.custom(
        gridDelegate: const _NumberPadGridDelegate(),
        childrenDelegate:
            SliverChildListDelegate(numberPads, addRepaintBoundaries: false),
        padding: const EdgeInsets.symmetric(vertical: 6.0),
      ),
    );
  }

  Widget _createOpSymbolsPane(
      BuildContext context, List<MathSymbol> opSymbols) {
    final ThemeData theme = Theme.of(context);

    final List<Widget> opPads = opSymbols.map<Widget>((MathSymbol symbol) {
      final _OpPad opPad = _createOpSymbolPad(context, symbol);

      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 1.0,
                color: opPad.borderColor ?? theme.dividerColor,
              ),
            ),
          ),
          child: opPad.widget,
        ),
      );
    }).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: opPads,
    );
  }

  _OpPad _createOpSymbolPad(BuildContext context, MathSymbol symbol) {
    if (symbol == MathSymbols.undo) {
      return _OpPad(
        widget: _createUndoOpSymbolPad(context),
        borderColor: Colors.black38,
      );
    }

    // ✅ IMPORTANT: TextButton.styleFrom expects OutlinedBorder?, not ShapeBorder
    final OutlinedBorder shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    );

    final bool disabled = _isDisabledKey(symbol);

    Color backgroundColor = Colors.black38;
    Widget child;

    switch (symbol) {
      case MathSymbols.delete:
        backgroundColor = Colors.black38;
        child = Text(
          symbol.text,
          style: const TextStyle(color: Colors.white, fontSize: 32),
        );
        break;
      default:
        child = Text(
          symbol.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0 * 1.5,
          ),
        );
    }

    final Widget button = TextButton(
      style: TextButton.styleFrom(
        shape: shape,
        padding: EdgeInsets.zero,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
      ),
      onPressed: disabled ? null : () => widget.onPress(symbol),
      child: child,
    );

    return _OpPad(
      widget: button,
      borderColor: backgroundColor,
    );
  }

  Widget _createUndoOpSymbolPad(BuildContext context) {
    return Container(
      color: Colors.black38,
      width: double.infinity,
      height: double.infinity,
    );
  }

  void _handleChangedDisabledKeys() {
    setState(() {});
  }

  bool _isDisabledKey(MathSymbol symbol) {
    return widget.controller != null
        ? widget.controller!._disabledKeys.contains(symbol)
        : false;
  }
}

class KeyPadController extends ChangeNotifier {
  List<MathSymbol> _disabledKeys;

  KeyPadController(List<MathSymbol> disabledKeys)
      : _disabledKeys = disabledKeys;

  void disableKeys(List<MathSymbol> keys) {
    if (listEquals(_disabledKeys, keys)) {
      return;
    }

    _disabledKeys = [...keys];

    notifyListeners();
  }

  @override
  void dispose() {
    _disabledKeys = [];

    super.dispose();
  }
}

class _OpPad {
  final Widget widget;
  final Color? borderColor;

  const _OpPad({required this.widget, this.borderColor});
}
