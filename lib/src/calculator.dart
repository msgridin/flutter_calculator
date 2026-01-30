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

  const Calculator({super.key, this.expr, this.formulaViewController});

  @override
  State<StatefulWidget> createState() => _CalculatorState(
      expr: expr, formulaViewController: formulaViewController);
}

class _CalculatorState extends State<Calculator> {
  final MathFormulaViewController _formulaViewController;

  final KeyPadController _keyPadController =
      KeyPadController([MathSymbols.undo, MathSymbols.redo]);
  final TextEditingController _formulaResultController =
      TextEditingController();

  _CalculatorState({
    required String? expr,
    required MathFormulaViewController? formulaViewController,
  }) : _formulaViewController =
            formulaViewController ?? MathFormulaViewController(expr: expr);

  @override
  void initState() {
    super.initState();

    _formulaViewController.addListener(_handleFormulaUpdated);
    _handleFormulaUpdated();
  }

  @override
  void didUpdateWidget(Calculator oldWidget) {
    super.didUpdateWidget(oldWidget);

    _handleFormulaUpdated();
  }

  @override
  void dispose() {
    _formulaViewController.dispose();
    _keyPadController.dispose();
    _formulaResultController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double height = MediaQuery.of(context).size.height / 2.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: theme.primaryColor,
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              MathFormulaView(_formulaViewController),
              AutoSizeEditableText(
                context: context,
                readOnly: true,
                autofocus: false,
                showCursor: false,
                maxLines: 1,
                focusNode: FocusNode(),
                controller: _formulaResultController,
                minFontSize: 14.0,
                style: const TextStyle(
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
        SizedBox(
          height: height,
          child: KeyPad(
            controller: _keyPadController,
            onPress: _handlePressedKey,
          ),
        ),
      ],
    );
  }

  void _handlePressedKey(MathSymbol symbol) {
    _formulaViewController.process(symbol);

    final List<MathSymbol> disabledKeys = <MathSymbol>[];
    if (!_formulaViewController.formula.canUndo()) {
      disabledKeys.add(MathSymbols.undo);
    }
    if (!_formulaViewController.formula.canRedo()) {
      disabledKeys.add(MathSymbols.redo);
    }

    _keyPadController.disableKeys(disabledKeys);
  }

  void _handleFormulaUpdated() {
    final double result = _formulaViewController.formula.evaluate();

    _formulaResultController.value = _formulaResultController.value.copyWith(
      text: '= ${result.toString()}',
    );
  }
}

class CalculatorDialog extends StatefulWidget {
  final String? expr;

  const CalculatorDialog({super.key, required this.expr});

  @override
  State<StatefulWidget> createState() => _CalculatorDialogState(expr);
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  final MathFormulaViewController _formulaViewController;

  _CalculatorDialogState(String? expr)
      : _formulaViewController = MathFormulaViewController(expr: expr);

  @override
  void dispose() {
    _formulaViewController.dispose();
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.dialogBackgroundColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Calculator(
                formulaViewController: _formulaViewController,
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 1.0, color: theme.dividerColor),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: _handleCancel,
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                      ),
                      TextButton(
                        onPressed: _handleOk,
                        child: Text(
                          'OK',
                          style: TextStyle(color: theme.primaryColor),
                        ),
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
    Navigator.pop(context, 0.00);
  }

  void _handleOk() {
    Navigator.pop(context, _formulaViewController.formula.evaluate());
  }
}

Future<double?> showCalculator({
  required BuildContext context,
  String? expr,
  Locale? locale,
  TextDirection? textDirection,
  TransitionBuilder? builder,
}) async {
  Widget child = CalculatorDialog(expr: expr);

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

  return showDialog<double>(
    context: context,
    builder: (BuildContext context) {
      return builder == null ? child : builder(context, child);
    },
  );
}
