import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Unfocuser extends StatefulWidget {

  final Widget child;

  const Unfocuser({Key key, this.child}) : super(key: key);

  @override
  _UnfocuserState createState() => _UnfocuserState();
}

class _UnfocuserState extends State<Unfocuser> {

  RenderBox _lastRenderBox;

  @override
  Widget build(BuildContext context) {
    
    return Listener(
      onPointerUp: (e) {
        var rb = context.findRenderObject() as RenderBox;
        var result = BoxHitTestResult();
        rb.hitTest(result, position: e.position);
        
        if (result.path.any((entry) =>
        entry.target.runtimeType == IgnoreUnfocuserRenderBox)) {
          return;
        }
        var isEditable = result.path.any(
                (entry) =>
            entry.target.runtimeType == RenderEditable ||
                entry.target.runtimeType == RenderParagraph ||
                entry.target.runtimeType == ForceUnfocuserRenderBox
        );

        var currentFocus = FocusScope.of(context);
        if (!isEditable) {
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
            _lastRenderBox = null;
          }
        } else {
          for (var entry in result.path) {
            var isEditable =
                entry.target.runtimeType == RenderEditable ||
                    entry.target.runtimeType == RenderParagraph ||
                    entry.target.runtimeType == ForceUnfocuserRenderBox;

            if (isEditable) {
              var renderBox = (entry.target as RenderBox);
              if (_lastRenderBox != renderBox) {
                _lastRenderBox = renderBox;
                setState(() {});
              }
            }
          }
        }
      },
      child: widget.child,
    );
  }
}


class IgnoreUnfocuser extends SingleChildRenderObjectWidget {
  final Widget child;

  IgnoreUnfocuser({@required this.child}) : super(child: child);

  @override
  IgnoreUnfocuserRenderBox createRenderObject(BuildContext context) {
    return IgnoreUnfocuserRenderBox();
  }
}

class ForceUnfocuser extends SingleChildRenderObjectWidget {
  final Widget child;

  ForceUnfocuser({@required this.child}) : super(child: child);

  @override
  ForceUnfocuserRenderBox createRenderObject(BuildContext context) {
    return ForceUnfocuserRenderBox();
  }
}

class IgnoreUnfocuserRenderBox extends RenderPointerListener {}
class ForceUnfocuserRenderBox extends RenderPointerListener {}