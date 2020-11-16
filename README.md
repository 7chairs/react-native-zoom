# react-native-zoom

This is a bridge for ZoomUS SDK:

- android: https://github.com/zoom/zoom-sdk-android
- ios: https://github.com/zoom/zoom-sdk-ios

Tested on XCode 11.5 and node 12.18.1.

## Getting started

`$ npm i @7chairs/react-native-zoom`

### Installation

Library will be linked automatically.

If you have `react-native < 0.60`, check [Linking Guide](https://github.com/7chairs/react-native-zoom/blob/master/docs/LINKING.md)

#### iOS

Make sure you have appropriate description in Info.plist:

- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSPhotoLibraryUsageDescription`

## Usage

```typescript
import Zoom from "react-native-zoom";

// initialize minimal
await Zoom.initialize({
  clientKey: "...",
  clientSecret: "...",
});

// initialize with extra config
await Zoom.initialize(
  {
    clientKey: "...",
    clientSecret: "...",
    domain: "zoom.us",
  },
  {
    disableShowVideoPreviewWhenJoinMeeting: true,
  }
);

// get callback event for initialize results
Zoom.onInitResults(callback: RNZoomInitResultEventCallback)

// Start Meeting
await Zoom.startMeeting({
  userName: "Johny",
  meetingNumber: "12345678",
  userId: "our-identifier",
  zoomAccessToken: zak,
  userType: 2, // optional
});

// Join Meeting
await Zoom.joinMeeting({
  userName: "Johny",
  meetingNumber: "12345678",
});

// Join Meeting with extra params
await Zoom.joinMeeting({
  userName: "Johny",
  meetingNumber: "12345678",
  password: "1234",
  participantID: "our-unique-id",
  noAudio: true,
  noVideo: true,
});

// Join Meeting with zoom meeting url
await Zoom.joinMeetingWithWebUrl("<zoom_meeting_url>");

// Register event callback for join meeting status
Zoom.addMeetingStatusEventListener(callback: RNZoomMeetingStatusEventCallback);

// Unregister listener
Zoom.removeMeetingStatusEventListener();
```

## In Meeting Events

```typescript
import Zoom from "react-native-zoom";

// Get My User Meeting Info
await Zoom.getMyUserMeetingInfo(): Promise<RNZoomMyselfMeetingInfo>

// Register listener to inMeetingEvents
Zoom.addInMeetingEventListener((callback: RNZoomInMeetingEventCallback) => {
  const { event, payload } = callback;
  //...
});
// Unregister listener
Zoom.removeInMeetingEventListener();
```

### events could be: [See iOS/Android SDK for more details]

```typescript
"meeting.user.video.active";
"meeting.user.video.speaker";
"meeting.user.video.status";
"meeting.user.audio.status";
"meeting.user.joined";
"meeting.user.left";
```

## FAQ

#### Does library support Expo?

You have to eject your expo project to use this library.
