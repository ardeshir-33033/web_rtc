import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
// import 'package:flutter_foreground_plugin/flutter_foreground_plugin.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' as Get;
import 'package:webrtc_test/call_model.dart';

import 'locator.dart';
import 'messaging_client.dart';

typedef void StreamStateCallback(MediaStream stream);

class Signaling extends Get.GetxController {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'username': 'SRNetwork',
        'credential': 'L96HZNDkrEZTEM',
        'urls': [
          'stun:stun.shahryar-raeis.com',
          'turn:turn.shahryar-raeis.com'
          // 'stun:stun1.l.google.com:19302',
          // 'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  List<CallModel> callList = [];
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  // RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  MediaStream? localStream;
  // MediaStream? remoteStream;
  // String? roomId;
  // String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;
  TextEditingController textEditingController = TextEditingController(text: '');

  bool enableAudio = true,
      enableVideo = true,
      isFrontCameraSelected = true,
      speakerPhone = true,
      enableTorch = false,
      isScreenShared = false;

  Future<String> createRoom() async {
    RTCPeerConnection? peerConnection;
    RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
    await remoteRenderer.initialize();

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();

    print('Create PeerConnection with configuration: $configuration');

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    peerConnection.onTrack = (event) {
      peerConnection!.addTrack(event.track, event.streams[0]);
      remoteRenderer.srcObject = event.streams[0];
    };

    // localStream?.getTracks().forEach((track) {
    //   peerConnection?.addTrack(track, localStream!);
    // });

    // Code for collecting ICE candidates below
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      print('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };
    // Finish Code for collecting ICE candidate

    // Add code for creating a room
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    print('Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    print('New room created with SDK offer. Room ID: $roomId');
    // Created a Room

    // peerConnection?.onTrack = (RTCTrackEvent event) {
    //   print('Got remote track: ${event.streams[0]}');
    //
    //   event.streams[0].getTracks().forEach((track) {
    //     print('Add a track to the remoteStream $track');
    //     remoteStream?.addTrack(track);
    //   });
    // };

    // Listening for remote session description below
    roomRef.snapshots().listen((snapshot) async {
      print('Got updated room: ${snapshot.data()}');

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        print("Someone tried to connect");
        await peerConnection?.setRemoteDescription(answer);
      }
    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          print('Got new remote ICE candidate: ${jsonEncode(data)}');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    });
    // Listen for remote ICE candidates above

    callList.add(CallModel(
      textController: TextEditingController(text: roomId),
      peerConnection: peerConnection,
      roomId: roomId,
      remoteRenderer: remoteRenderer,
    ));

    // locator<MessagingClient>().sendSignal(roomId);

    return roomId;
  }

  Future<void> joinRoom(String roomId) async {
    RTCPeerConnection? peerConnection;

    FirebaseFirestore db = FirebaseFirestore.instance;
    print(roomId);
    DocumentReference roomRef = db.collection('rooms').doc('$roomId');
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $configuration');
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          print('onIceCandidate: complete!');
          return;
        }
        print('onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      // peerConnection?.onTrack = (RTCTrackEvent event) {
      //   print('Got remote track: ${event.streams[0]}');
      //   event.streams[0].getTracks().forEach((track) {
      //     print('Add a track to the remoteStream: $track');
      //     remoteStream?.addTrack(track);
      //   });
      // };

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      print('Got offer $data');
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();
      print('Created Answer $answer');

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        snapshot.docChanges.forEach((document) {
          var data = document.doc.data() as Map<String, dynamic>;
          print(data);
          print('Got new remote ICE candidate: $data');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        });
      });
    }
  }

  Future<void> openUserMedia() async {
    var stream = await navigator.mediaDevices.getUserMedia({
      'video': enableVideo
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
      'audio': enableAudio
    });

    localRenderer.srcObject = stream;
    localStream = stream;

    remoteRenderer.srcObject = await createLocalMediaStream('key');
    update(["ui"]);
  }

  Future<void> makeScreenSharing() async {
    final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};
    isScreenShared = true;

    try {
      var stream =
          await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
      localRenderer.srcObject = stream;
      localStream = stream;
      replaceMediaStream(stream);
      update(["ui"]);
    } catch (e) {
      print(e.toString());
    }
  }

  disableShareScreen() async {
    var stream = await navigator.mediaDevices.getUserMedia({
      'video': enableVideo
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
      'audio': enableAudio
    });
    isScreenShared = false;

    localRenderer.srcObject = stream;
    localStream = stream;

    remoteRenderer.srcObject = await createLocalMediaStream('key');
    replaceMediaStream(stream);
    update(["ui"]);
  }

  Future<void> replaceMediaStream(MediaStream newStream) {
    return peerConnection?.senders.then((senders) {
          senders.forEach((sender) async {
            if (sender.track?.kind == 'video') {
              if (newStream.getVideoTracks().length > 0) {
                await sender.replaceTrack(newStream.getVideoTracks()[0]);
              }
            } else if (sender.track?.kind == 'audio') {
              if (newStream.getAudioTracks().length > 0) {
                await sender.replaceTrack(newStream.getAudioTracks()[0]);
              }
            }
          });
          return Future.value();
        }) ??
        Future.error(
            Exception('An error occurred during switching the stream'));
  }

  Future<void> toggleAudio() async {
    enableAudio = !enableAudio;
    localStream?.getAudioTracks().forEach((track) {
      track.enabled = enableAudio;
    });
    update(["ui"]);
  }

  Future<void> toggleVideo() async {
    enableVideo = !enableVideo;
    localStream?.getVideoTracks().forEach((track) {
      track.enabled = enableVideo;
    });
    update(["ui"]);
  }

  switchCamera() {
    // change status
    isFrontCameraSelected = !isFrontCameraSelected;

    // switch camera
    localStream?.getVideoTracks().forEach((track) {
      Helper.switchCamera(track);
    });

    if (isFrontCameraSelected) {
      if (enableTorch = true) {
        toggleTorch();
      }
    }
    update(["ui"]);
  }

  toggleSpeaker() {
    speakerPhone = !speakerPhone;

    Helper.setSpeakerphoneOn(speakerPhone);
    update(["ui"]);
  }

  toggleTorch() {
    enableTorch = !enableTorch;
    localStream?.getVideoTracks().forEach((track) {
      track.setTorch(enableTorch);
    });
    update(["ui"]);
  }

  captureFrame() async {
    localStream?.getVideoTracks().forEach((track) {
      track.captureFrame();
    });
    update(["ui"]);
  }

  Future<void> hangUp() async {
    List<MediaStreamTrack> tracks = localRenderer.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      calleeCandidates.docs.forEach((document) => document.reference.delete());

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      callerCandidates.docs.forEach((document) => document.reference.delete());

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
