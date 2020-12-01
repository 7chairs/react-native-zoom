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

#### android

Since we use zoom sdk from local './libs' folder android release apk could not be packed. Therefore you will need to do this following steps:

1. in android studio go to: File -> New -> New Module -> Import .JAR/.AAR Package

2. import both mobilertc.aar and commonlib.aar. after doind so you should have in your android root directory both 'mobilertc' and 'commonlib' folders

3. add to settings.gradle

```
include ':mobilertc'
include ':commonlib'
project(':mobilertc').projectDir = file("./mobilertc")
project(':commonlib').projectDir = file("./commonlib")
```

#### iOS

Make sure you have appropriate description in Info.plist:

- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSPhotoLibraryUsageDescription`

## Usage

```typescript
import Zoom from "@7chairs/react-native-zoom";

// initialize minimal
await Zoom.initialize({
  clientKey: "...",
  clientSecret: "...",
});

// initialize with extra config
const { initialized } = await Zoom.initialize(
  {
    clientKey: "...",
    clientSecret: "...",
    domain: "zoom.us",
  },
  {
    disableShowVideoPreviewWhenJoinMeeting: true,
  }
);

// if (!initialized) get callback event for initialize results
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
  userName: "Joh",
  meetingNumber: "12345678",
});

// Join Meeting with extra params
await Zoom.joinMeeting({
  userName: "Joh",
  meetingNumber: "12345678",
  password: "1234",
  participantID: "our-unique-id",
  zoomAccessToken: "token",
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
import Zoom from "@7chairs/react-native-zoom";

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
