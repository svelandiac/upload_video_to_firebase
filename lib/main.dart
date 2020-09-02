import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MediaQueryData queryData;
  File _videoSelected;
  VideoPlayerController _videoPlayerController;

  Future<void> _pickVideo() async {
    final pickedVideo =
        await ImagePicker().getVideo(source: ImageSource.gallery);
    setState(() {
      _videoSelected = File(pickedVideo.path);
    });

    _videoPlayerController = VideoPlayerController.file(_videoSelected)
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController.play();
      });
  }

  Widget _buildTitle() {
    return Text(
      'Upload video to Firebase Storage',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Text(
        'Please select a video from your Gallery clicking on the button bellow'
        ' and pushing on "Upload". You will receive an app notification when '
        'process has completed.',
        textAlign: TextAlign.justify,
        style: TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildselectVideoButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          child: FlatButton(
            color: Color(0x66A5AAAB),
            onPressed: _pickVideo,
            child: Text('Select a video'),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSelected() {
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 0, 0),
              child: Text(
                'Video selected:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 18, 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _videoSelected = null;
                    _videoPlayerController.pause();
                  });
                },
                child: Text(
                  'Clear selection',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    queryData = MediaQuery.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: queryData.size.height * 0.12,
                ),
                _buildTitle(),
                SizedBox(
                  height: queryData.size.height * 0.08,
                ),
                _buildDescription(),
                SizedBox(
                  height: queryData.size.height * 0.03,
                ),
                _buildselectVideoButton(),
                SizedBox(
                  height: queryData.size.height * 0.02,
                ),
                _buildVideoSelected(),
                SizedBox(
                  height: queryData.size.height * 0.04,
                ),
                if (_videoSelected != null)
                  _videoPlayerController.value.initialized
                      ? Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: AspectRatio(
                            aspectRatio:
                                _videoPlayerController.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController),
                          ),
                        )
                      : Container(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: Uploader(file: _videoSelected),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Uploader extends StatefulWidget {
  final File file;

  Uploader({Key key, this.file}) : super(key: key);

  createState() => _UploaderState();
}


class _UploaderState extends State<Uploader> {
  final FirebaseStorage _storage =
      FirebaseStorage(storageBucket: 'gs://technical-test-86978.appspot.com');

  StorageUploadTask _uploadTask;

  /// Starts an upload task
  void _startUpload() {
    /// Unique file name for the file
    String filePath = 'videos/${DateTime.now()}.mp4';

    setState(() {
      _uploadTask = _storage.ref().child(filePath).putFile(widget.file);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_uploadTask != null) {
      /// Manage the task state and event subscription with a StreamBuilder
      return StreamBuilder<StorageTaskEvent>(
          stream: _uploadTask.events,
          builder: (_, snapshot) {
            var event = snapshot?.data?.snapshot;

            double progressPercent = event != null
                ? event.bytesTransferred / event.totalByteCount
                : 0;

            return Column(
              children: [
                if (_uploadTask.isComplete) Text('Upload completed'),

                if (_uploadTask.isPaused)
                  FlatButton(
                    child: Icon(Icons.play_arrow),
                    onPressed: _uploadTask.resume,
                  ),

                if (_uploadTask.isInProgress)
                  FlatButton(
                    child: Icon(Icons.pause),
                    onPressed: _uploadTask.pause,
                  ),

                // Progress bar
                LinearProgressIndicator(value: progressPercent),
                Text('${(progressPercent * 100).toStringAsFixed(2)} % '),
              ],
            );
          });
    } else {
      // Allows user to decide when to start the upload
      return FlatButton.icon(
        label: Text('Upload to Firebase'),
        icon: Icon(Icons.cloud_upload),
        onPressed: widget.file != null ? _startUpload : null,
      );
    }
  }
}
