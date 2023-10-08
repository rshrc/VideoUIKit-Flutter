import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:agora_uikit/controllers/rtc_buttons.dart';
import 'package:agora_uikit/models/agora_settings.dart';
import 'package:agora_uikit/src/layout/widgets/disabled_video_widget.dart';
import 'package:agora_uikit/src/layout/widgets/host_controls.dart';
import 'package:agora_uikit/src/layout/widgets/number_of_users.dart';
import 'package:agora_uikit/src/layout/widgets/user_av_state_widget.dart';
import 'package:flutter/material.dart';

class TPRCLayout extends StatefulWidget {
  final AgoraClient client;

  /// Set the height of the container in the floating view. The default height is 0.2 of the total height.
  final double? floatingLayoutContainerHeight;

  /// Set the width of the container in the floating view. The default width is 1/3 of the total width.
  final double? floatingLayoutContainerWidth;

  /// Padding of the main user or the active speaker in the floating layout.
  final EdgeInsets floatingLayoutMainViewPadding;

  /// Padding of the secondary user present in the list.
  final EdgeInsets floatingLayoutSubViewPadding;

  /// Widget that will be displayed when the local or remote user has disabled it's video.
  final Widget disabledVideoWidget;

  /// Display the camera and microphone status of a user. This feature is only available in the [Layout.floating]
  final bool? showAVState;

  /// Display the host controls. This feature is only available in the [Layout.floating]
  final bool? enableHostControl;

  /// Display the total number of users in a channel.
  final bool? showNumberOfUsers;

  // Render mode for local and remote video
  final RenderModeType? renderModeType;

  final bool? useFlutterTexture;
  final bool? useAndroidSurfaceView;

  final String? conditionText;

  const TPRCLayout(
      {Key? key,
      required this.client,
      this.floatingLayoutContainerHeight,
      this.floatingLayoutContainerWidth,
      this.floatingLayoutMainViewPadding =
          const EdgeInsets.fromLTRB(3, 0, 3, 3),
      this.floatingLayoutSubViewPadding = const EdgeInsets.fromLTRB(3, 3, 0, 3),
      this.disabledVideoWidget = const DisabledVideoWidget(),
      this.showAVState = false,
      this.enableHostControl = false,
      this.showNumberOfUsers,
      this.renderModeType = RenderModeType.renderModeHidden,
      this.useAndroidSurfaceView = false,
      this.useFlutterTexture = false,
      this.conditionText})
      : super(key: key);

  @override
  State<TPRCLayout> createState() => _TPRCLayoutState();
}

class _TPRCLayoutState extends State<TPRCLayout> {
  bool canJoinCall = true;

  Widget _getLocalViews() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: widget.client.sessionController.value.engine!,
        canvas: VideoCanvas(uid: 0, renderMode: widget.renderModeType),
        useFlutterTexture: widget.useFlutterTexture!,
        useAndroidSurfaceView: widget.useAndroidSurfaceView!,
      ),
    );
  }

  Widget _getRemoteViews(int uid) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: widget.client.sessionController.value.engine!,
        canvas: VideoCanvas(uid: uid, renderMode: widget.renderModeType),
        connection: RtcConnection(
            channelId: widget
                .client.sessionController.value.connectionData!.channelName),
        useFlutterTexture: widget.useFlutterTexture!,
        useAndroidSurfaceView: widget.useAndroidSurfaceView!,
      ),
    );
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  int? getParticipantIndex() {
    for (final user in widget.client.sessionController.value.users) {
      if (user.uid != widget.client.sessionController.value.mainAgoraUser.uid) {
        log(">>> Line 518 : ${user.uid}");

        return user.uid;
      }
    }
    return null;
  }

  Widget _viewTPRC() {
    final participantUid = getParticipantIndex();

    if (widget.client.sessionController.value.users.length > 1) {
      setState(() {
        canJoinCall = false;
      });
    }

    return widget.client.sessionController.value.users.isNotEmpty
        ? Stack(
            children: [
              if (participantUid != null)
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.blue,
                  child: _getRemoteViews(
                    participantUid ?? 0,
                  ),
                ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 240,
                  width: 160,
                  color: Colors.red,
                  child: _getLocalViews(),
                ),
              ),
            ],
          )
        : Container(
            child:
                Text(widget.conditionText ?? "Waiting for others to join..."),
          );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.client.sessionController,
      builder: (context, AgoraSettings agoraSettings, widgetx) {
        return Center(
          child: Stack(
            children: [
              // _viewFloat(),
              _viewTPRC(),
              widget.showNumberOfUsers == null ||
                      widget.showNumberOfUsers == false
                  ? Container()
                  : Positioned.fill(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: NumberOfUsers(
                          userCount: widget
                              .client.sessionController.value.users.length,
                        ),
                      ),
                    ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Visibility(
                    child: Container(
                        color: Colors.white,
                        width: MediaQuery.of(context).size.width,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget
                                .client.sessionController.value.showMicMessage)
                              widget.client.sessionController.value
                                          .muteRequest ==
                                      MicState.muted
                                  ? Text("Please unmute your mic")
                                  : Text("Please mute your mic"),
                            if (widget.client.sessionController.value
                                .showCameraMessage)
                              widget.client.sessionController.value
                                          .cameraRequest ==
                                      CameraState.disabled
                                  ? Text("Please turn on your camera")
                                  : Text("Please turn off your camera"),
                            TextButton(
                              onPressed: () {
                                widget.client.sessionController.value
                                            .showMicMessage &&
                                        !widget.client.sessionController.value
                                            .showCameraMessage
                                    ? toggleMute(
                                        sessionController:
                                            widget.client.sessionController,
                                      )
                                    : toggleCamera(
                                        sessionController:
                                            widget.client.sessionController,
                                      );
                                widget.client.sessionController.value = widget
                                    .client.sessionController.value
                                    .copyWith(
                                  displaySnackbar: false,
                                  showMicMessage: false,
                                  showCameraMessage: false,
                                );
                              },
                              child: widget.client.sessionController.value
                                      .showMicMessage
                                  ? widget.client.sessionController.value
                                              .muteRequest ==
                                          MicState.muted
                                      ? Text(
                                          "Unmute",
                                          style: TextStyle(color: Colors.blue),
                                        )
                                      : Text(
                                          "Mute",
                                          style: TextStyle(color: Colors.blue),
                                        )
                                  : widget.client.sessionController.value
                                              .cameraRequest ==
                                          CameraState.disabled
                                      ? Text(
                                          "Enable",
                                          style: TextStyle(color: Colors.blue),
                                        )
                                      : Text(
                                          "Disable",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                            )
                          ],
                        )),
                    visible:
                        widget.client.sessionController.value.displaySnackbar,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
