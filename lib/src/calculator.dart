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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './math_symbol.dart';
import './math_formula_view.dart';
import './keypad.dart';
import './auto_size_editable_text.dart';

class Calculator extends StatefulWidget {
  final String? expr;
  final MathFormulaViewController? formulaViewController;

  Calculator({this.expr, this.formulaViewController});

  @override
  State<StatefulWidget> createState() =>
      _CalculatorState(expr: this.expr, formulaViewController: this.formulaViewController);
}

class _CalculatorState extends State<Calculator> {
  final MathFormulaViewController _formulaViewController;

  final KeyPadController _keyPadController = KeyPadController([MathSymbols.undo, MathSymbols.redo]);
  final TextEditingController _formulaResultController = TextEditingController();

  _CalculatorState({required String? expr, required MathFormulaViewController? formulaViewController})
      : this._formulaViewController = formulaViewController ?? MathFormulaViewController(expr: expr);

  @override
  void initState() {
    super.initState();

    this._formulaViewController.addListener(this._handleFormulaUpdated);

    this._handleFormulaUpdated();
  }

  @override
  void didUpdateWidget(Calculator oldWidget) {
    super.didUpdateWidget(oldWidget);

    this._handleFormulaUpdated();
  }

  @override
  void dispose() {
    this._formulaViewController.dispose();
    this._keyPadController.dispose();
    this._formulaResultController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    double height = MediaQuery.of(context).size.height / 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.red,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('123345667889'),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: theme.primaryColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                MathFormulaView(this._formulaViewController),
                AutoSizeEditableText(
                  context: context,
                  readOnly: true,
                  autofocus: false,
                  showCursor: false,
                  maxLines: 1,
                  focusNode: FocusNode(),
                  controller: this._formulaResultController,
                  minFontSize: 14.0,
                  style: TextStyle(
                    fontSize: 14.0 * 3.0,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  cursorColor: Colors.white,
                  backgroundCursorColor: theme.focusColor,
                ),
              ],
            ),
          ),
          Container(
            height: height,
            child: KeyPad(
              controller: this._keyPadController,
              onPress: this._handlePressedKey,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePressedKey(MathSymbol symbol) {
    this._formulaViewController.process(symbol);

    List<MathSymbol> disabledKeys = [];
    if (!this._formulaViewController.formula.canUndo()) {
      disabledKeys.add(MathSymbols.undo);
    }
    if (!this._formulaViewController.formula.canRedo()) {
      disabledKeys.add(MathSymbols.redo);
    }

    this._keyPadController.disableKeys(disabledKeys);
  }

  void _handleFormulaUpdated() {
    final double result = this._formulaViewController.formula.evaluate();

    this._formulaResultController.value = this._formulaResultController.value.copyWith(
          text: "= ${result.toString()}",
        );
  }
}

class CalculatorDialog extends StatefulWidget {
  final String? expr;

  const CalculatorDialog({required this.expr}) : super();

  @override
  State<StatefulWidget> createState() => _CalculatorDialogState(this.expr);
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  final MathFormulaViewController _formulaViewController;

  _CalculatorDialogState(String? expr) : this._formulaViewController = MathFormulaViewController(expr: expr);

  @override
  void dispose() {
    this._formulaViewController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        dialogBackgroundColor: Colors.transparent,
      ),
      child: Dialog(
        child: Container(
          color: theme.dialogBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Calculator(
                formulaViewController: this._formulaViewController,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 1.0, color: theme.dividerColor),
                  ),
                ),
                child: ButtonBarTheme(
                  data: ButtonBarTheme.of(context),
                  child: ButtonBar(
                    children: <Widget>[
                      FlatButton(
                        child: Text('Cancel'),
                        onPressed: this._handleCancel,
                      ),
                      FlatButton(
                        child: Text('OK'),
                        onPressed: this._handleOk,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  void _handleOk() {
    Navigator.pop(context, this._formulaViewController.formula.evaluate());
  }
}

Future<double> showCalculator({
  required BuildContext context,
  String? expr,
  Locale? locale,
  TextDirection? textDirection,
  TransitionBuilder? builder,
}) async {
  Widget child = CalculatorDialog(
    expr: expr,
  );

  if (textDirection != null) {
    child = Directionality(
      textDirection: textDirection,
      child: child,
    );
  }

  if (locale != null) {
    child = Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }

  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return builder == null ? child : builder(context, child);
    },
  );
}
