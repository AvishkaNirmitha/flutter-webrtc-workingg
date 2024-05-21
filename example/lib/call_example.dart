import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallExample extends StatefulWidget {
  const CallExample({Key? key}) : super(key: key);

  @override
  State<CallExample> createState() => _CallExampleState();
}

class _CallExampleState extends State<CallExample> {
  final TextEditingController _controller = TextEditingController();
  final Peer peer = Peer(
      options: PeerOptions(
    debug: LogLevel.All,
    // Add your PeerJS server configuration here if needed
    host: 'node-video-3-1.onrender.com',
    port: 443,
    path: '/peerjs',
    secure: true,
  ));
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  MediaConnection? _currentCall;
  bool inCall = false;
  String? peerId;

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    peer.on('open').listen((id) {
      setState(() {
        peerId = id;
      });
      print('My peer ID is: $peerId');
    });

    peer.on<MediaConnection>('call').listen((call) async {
      final mediaStream = await _getUserMedia();
      _localStream = mediaStream;

      call.answer(mediaStream);
      _handleCall(call);
    });
  }

  Future<MediaStream> _getUserMedia() async {
    return await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});
  }

  void _handleCall(MediaConnection call) {
    print('_handleCall............');
    call.on('close').listen((event) {
      print('_handleCall 1............');
      setState(() {
        print('_handleCall 2............');
        inCall = false;
      });
    });

    print('_handleCall 3............');

    call.on<MediaStream>('stream').listen((event) {
      _remoteRenderer.srcObject = event;
      _localRenderer.srcObject = _localStream;

      print('_handleCall 4............');

      setState(() {
        inCall = true;
      });
    });

    print('_handleCall 5............');

    setState(() {
      _currentCall = call;
    });
  }

  @override
  void dispose() {
    peer.dispose();
    _controller.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void connect() async {
    print('connect...');
    if (_controller.text.isEmpty) return;

    print('connect 1.1...');
    final mediaStream = await _getUserMedia();
    print('connect 2...');
    _localStream = mediaStream;
    print('connect 3...');

    final call = peer.call(_controller.text, mediaStream);
    print('connect 4...');
    // print(call);

    _handleCall(call);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call Example 2')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _renderState(),
            Text(peerId ?? ''),
            const Text('Connection ID:'),
            SelectableText(peerId ?? 'can not found peer id'),
            TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: 'Enter Peer ID')),
            ElevatedButton(onPressed: connect, child: const Text('Connect')),
            if (inCall) Expanded(child: RTCVideoView(_localRenderer)),
            if (inCall) Expanded(child: RTCVideoView(_remoteRenderer)),
          ],
        ),
      ),
    );
  }

  Widget _renderState() {
    Color bgColor = inCall ? Colors.green : Colors.grey;
    Color txtColor = Colors.white;
    String txt = inCall ? 'Connected' : 'Standby';
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        txt,
        style:
            Theme.of(context).textTheme.titleLarge?.copyWith(color: txtColor),
      ),
    );
  }
}
