
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'whiteboard_painter.dart';

class WhiteboardWidget extends StatefulWidget {
  final IO.Socket socket;
  final String classId;
  final bool isTeacher;

  const WhiteboardWidget({
    Key? key,
    required this.socket,
    required this.classId,
    required this.isTeacher,
  }) : super(key: key);

  @override
  _WhiteboardWidgetState createState() => _WhiteboardWidgetState();
}

class _WhiteboardWidgetState extends State<WhiteboardWidget> {
  final List<DrawingLine> _lines = [];
  DrawingLine? _currentLine;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 4.0;

  @override
  void initState() {
    super.initState();
    // Both teacher and student listen for draw events.
    // The teacher listens to see their own drawing, and students listen to see the teacher's.
    // A more advanced implementation might only have students listen.
    widget.socket.on('draw-event', (data) {
      if (mounted) {
        final event = data['event'];
        final senderId = data['senderId'];

        // Don't process our own events if we are the teacher
        if (widget.isTeacher && senderId == widget.socket.id) return;

        final Map<String, dynamic> eventData = jsonDecode(event);
        final String type = eventData['type'];

        setState(() {
          switch (type) {
            case 'start':
              final List<dynamic> pointsData = eventData['points'];
              final Offset startPoint = Offset(pointsData[0], pointsData[1]);
              final int colorValue = eventData['color'];
              final double strokeWidth = (eventData['strokeWidth'] as num).toDouble();

              _lines.add(DrawingLine(
                color: Color(colorValue),
                strokeWidth: strokeWidth,
                points: [startPoint],
              ));
              break;
            case 'draw':
              if (_lines.isNotEmpty) {
                final List<dynamic> pointsData = eventData['points'];
                final Offset newPoint = Offset(pointsData[0], pointsData[1]);
                _lines.last.points.add(newPoint);
              }
              break;
            case 'end':
              // In a more complex scenario, we might finalize the line here.
              break;
          }
        });
      }
    });
  }

  void _sendDrawEvent(String type, {Offset? point}) {
    final Map<String, dynamic> eventData = {
      'type': type,
      'color': _currentColor.value,
      'strokeWidth': _currentStrokeWidth,
    };

    if (point != null) {
      eventData['points'] = [point.dx, point.dy];
    }

    widget.socket.emit('draw-event', {
      'classId': widget.classId,
      'event': jsonEncode(eventData),
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.isTeacher) return;

    _currentLine = DrawingLine(
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      points: [details.localPosition],
    );

    setState(() {
      _lines.add(_currentLine!);
    });

    _sendDrawEvent('start', point: details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isTeacher || _currentLine == null) return;

    setState(() {
      _currentLine!.points.add(details.localPosition);
    });

    _sendDrawEvent('draw', point: details.localPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.isTeacher) return;
    _sendDrawEvent('end');
    _currentLine = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: CustomPaint(
        painter: WhiteboardPainter(lines: _lines),
        size: Size.infinite,
      ),
    );
  }

  @override
  void dispose() {
    widget.socket.off('draw-event');
    super.dispose();
  }
}
