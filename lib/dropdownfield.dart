library dropdownfield;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DropDownField extends FormField<String> {
  final dynamic value;
  final String hintText;
  final TextStyle hintStyle;
  final String labelText;
  final TextStyle labelStyle;
  final TextStyle textStyle;
  final bool required;
  final bool enabled;
  final List<dynamic> items;
  final List<TextInputFormatter> inputFormatters;
  final FormFieldSetter<dynamic> setter;
  final ValueChanged<dynamic> onValueChanged;
  final bool strict;
  final int itemsVisibleInDropdown;
  final TextEditingController controller;
  final String iconText;

  DropDownField(
      {Key key,
      this.controller,
      this.value,
      this.iconText,
      this.required: false,
      this.hintText,
      this.hintStyle: const TextStyle(
          fontWeight: FontWeight.normal, color: Colors.grey, fontSize: 18.0),
      this.labelText,
      this.labelStyle: const TextStyle(
          fontWeight: FontWeight.normal, color: Colors.grey, fontSize: 18.0),
      this.inputFormatters,
      this.items,
      this.textStyle: const TextStyle(
          fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14.0),
      this.setter,
      this.onValueChanged,
      this.itemsVisibleInDropdown: 3,
      this.enabled: true,
      this.strict: true})
      : super(
          key: key,
          autovalidate: false,
          initialValue: controller != null ? controller.text : (value ?? ''),
          onSaved: setter,
          builder: (FormFieldState<String> field) {
            final CustomizedDropDownState state = field;
            final ScrollController _scrollController = ScrollController();
            final InputDecoration effectiveDecoration = InputDecoration(
                border: new OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[500])),
                filled: true,
                suffixIcon: IconButton(
                    icon: Icon(Icons.keyboard_arrow_down,
                        size: 30.0, color: Colors.black),
                    onPressed: () {
                      SystemChannels.textInput.invokeMethod('TextInput.hide');
                      state.setState(() {
                        state._showdropdown = !state._showdropdown;
                      });
                    }),
                fillColor: Colors.white,
                hintStyle: hintStyle,
                labelStyle: labelStyle,
                hintText: hintText,
                labelText: labelText);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    new Theme(
                      data: new ThemeData(
                          primaryColor: Colors.grey[500],
                          primaryColorDark: Colors.grey),
                      child: Expanded(
                        child: TextFormField(
                          autovalidate: true,
                          onTap: () {
                            // add this line when needed SystemChannels.textInput.invokeMethod('TextInput.hide');
                            state.setState(() {
                              state._showdropdown = !state._showdropdown;
                            });
                          },
                          controller: state._effectiveController,
                          decoration: effectiveDecoration.copyWith(
                              errorText: field.errorText),
                          style: textStyle,
                          textAlign: TextAlign.start,
                          autofocus: false,
                          showCursor: false,
                          readOnly: true,
                          // to make the text disabled use focusNode: new AlwaysDisabledFocusNode()
                          obscureText: false,
                          maxLengthEnforced: true,
                          maxLines: 1,
                          onSaved: setter,
                          enabled: enabled,
                          inputFormatters: inputFormatters,
                        ),
                      ),
                    ),
                    if (iconText != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10.0),
                              bottomRight: Radius.circular(10.0)),
                        ),
                        margin: EdgeInsets.only(left: 2),
                        padding: EdgeInsets.only(
                            left: 15, right: 15, top: 20, bottom: 20),
                        child: Text(
                          iconText,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                  ],
                ),
                !state._showdropdown
                    ? Container()
                    : Container(
                        color: Colors.white,
                        alignment: Alignment.topCenter,
                        height: itemsVisibleInDropdown *
                            48.0, //limit to default 3 items in dropdownlist view and then remaining scrolls
                        width: MediaQuery.of(field.context).size.width,
                        child: ListView(
                          cacheExtent: 0.0,
                          scrollDirection: Axis.vertical,
                          controller: _scrollController,
                          padding: EdgeInsets.only(left: 40.0),
                          children: items.isNotEmpty
                              ? ListTile.divideTiles(
                                      context: field.context,
                                      tiles: state._getChildren(state._items))
                                  .toList()
                              : List(),
                        ),
                      ),
              ],
            );
          },
        );

  @override
  CustomizedDropDownState createState() => CustomizedDropDownState();
}

class CustomizedDropDownState extends FormFieldState<String> {
  TextEditingController _controller;
  bool _showdropdown = false;
  @override
  DropDownField get widget => super.widget;
  TextEditingController get _effectiveController =>
      widget.controller ?? _controller;

  List<String> get _items => widget.items;

  void toggleDropDownVisibility() {}

  @override
  void didUpdateWidget(DropDownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);

      if (oldWidget.controller != null && widget.controller == null)
        _controller =
            TextEditingController.fromValue(oldWidget.controller.value);
      if (widget.controller != null) {
        setValue(widget.controller.text);
        if (oldWidget.controller == null) _controller = null;
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
    }
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void reset() {
    super.reset();
    setState(() {});
  }

  List<ListTile> _getChildren(List<String> items) {
    List<ListTile> childItems = List();
    for (var item in items) {
      childItems.add(_getListTile(item));
    }
    return childItems;
  }

  ListTile _getListTile(String text) {
    return ListTile(
      dense: true,
      title: Text(
        text,
      ),
      onTap: () {
        setState(() {
          _effectiveController.text = text;
          _handleControllerChanged();
          _showdropdown = false;
          if (widget.onValueChanged != null) widget.onValueChanged(text);
        });
      },
    );
  }

  void _handleControllerChanged() {
    // Suppress changes that originated from within this class.
    //
    // In the case where a controller has been passed in to this widget, we
    // register this change listener. In these cases, we'll also receive change
    // notifications for changes originating from within this class -- for
    // example, the reset() method. In such cases, the FormField value will
    // already have been set.
    if (_effectiveController.text != value)
      didChange(_effectiveController.text);

    if (_effectiveController.text.isNotEmpty) {
      setState(() {
        _showdropdown = true;
      });
    }
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

