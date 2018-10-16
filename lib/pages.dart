import 'package:flutter/material.dart';

class Pages extends StatefulWidget {
  Pages({Key key, @required this.children, this.bottomSelector = false})
      : super(key: key);

  final List<Widget> children;
  final bool bottomSelector;

  @override
  _PagesState createState() => new _PagesState();
}

class _PagesState extends State<Pages> with TickerProviderStateMixin {
  TabController controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null || widget.children.length != controller.length) {
      controller =
          new TabController(length: widget.children.length, vsync: this);
    }

    Widget selector = new Container(
      margin: !widget.bottomSelector
          ? const EdgeInsets.only(top: 6.0, bottom: 1.0)
          : const EdgeInsets.only(top: 3.0, bottom: 4.0),
      child: new Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: new _PageSelector(
            controller: controller,
          ),
        ),
      ),
    );

    Widget content = new Expanded(
      child: new TabBarView(
        controller: controller,
        children: widget.children,
      ),
    );

    List<Widget> widgets;

    if (!widget.bottomSelector)
      widgets = [selector, content];
    else
      widgets = [content, selector];

    return new SafeArea(
      top: false,
      bottom: false,
      child: new Column(
        children: widgets,
      ),
    );
  }
}

// The following code is modified from the Flutter project which was previously
// licensed under:
//
// Copyright 2014 The Chromium Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class _PageSelector extends StatelessWidget {
  // Simplified version of TabPageSelector with the addition of changing pages
  // by clicking on the indicators.

  const _PageSelector({Key key, this.controller}) : super(key: key);

  final TabController controller;

  double _indexChangeProgress() {
    final double controllerValue = controller.animation.value;
    final double previousIndex = controller.previousIndex.toDouble();
    final double currentIndex = controller.index.toDouble();

    // The controller's offset is changing because the user is dragging the
    // TabBarView's PageView to the left or right.
    if (!controller.indexIsChanging)
      return (currentIndex - controllerValue).abs().clamp(0.0, 1.0);

    // The TabController animation's value is changing from previousIndex to currentIndex.
    return (controllerValue - currentIndex).abs() /
        (currentIndex - previousIndex).abs();
  }

  Widget _buildTabIndicator(
    int tabIndex,
    ColorTween selectedColorTween,
    ColorTween previousColorTween,
  ) {
    Color background;
    if (controller.indexIsChanging) {
      // The selection's animation is animating from previousValue to value.
      final double t = 1.0 - _indexChangeProgress();
      if (controller.index == tabIndex)
        background = selectedColorTween.lerp(t);
      else if (controller.previousIndex == tabIndex)
        background = previousColorTween.lerp(t);
      else
        background = selectedColorTween.begin;
    } else {
      // The selection's offset reflects how far the TabBarView has / been dragged
      // to the previous page (-1.0 to 0.0) or the next page (0.0 to 1.0).
      final double offset = controller.offset;
      if (controller.index == tabIndex) {
        background = selectedColorTween.lerp(1.0 - offset.abs());
      } else if (controller.index == tabIndex - 1 && offset > 0.0) {
        background = selectedColorTween.lerp(offset);
      } else if (controller.index == tabIndex + 1 && offset < 0.0) {
        background = selectedColorTween.lerp(-offset);
      } else {
        background = selectedColorTween.begin;
      }
    }
    return new InkWell(
      child: new Padding(
        padding: const EdgeInsets.only(left: 2.0, right: 2.0),
        child: new TabPageSelectorIndicator(
          backgroundColor: background,
          borderColor: selectedColorTween.end,
          size: 12.0,
        ),
      ),
      customBorder: new CircleBorder(),
      onTap: () {
        if (tabIndex >= 0 && tabIndex < controller.length)
          controller.animateTo(tabIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color fixColor = Colors.transparent;
    final Color fixSelectedColor = Theme.of(context).accentColor;
    final ColorTween selectedColorTween =
        new ColorTween(begin: fixColor, end: fixSelectedColor);
    final ColorTween previousColorTween =
        new ColorTween(begin: fixSelectedColor, end: fixColor);

    final Animation<double> animation = new CurvedAnimation(
      parent: controller.animation,
      curve: Curves.fastOutSlowIn,
    );
    return new AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget child) {
          return new Row(
            mainAxisSize: MainAxisSize.min,
            children:
                new List<Widget>.generate(controller.length, (int tabIndex) {
              return _buildTabIndicator(
                  tabIndex, selectedColorTween, previousColorTween);
            }).toList(),
          );
        });
  }
}
