import {
  NativeModules,
  DeviceEventEmitter,
  NativeEventEmitter,
  Platform,
} from "react-native";

const { RNZoom } = NativeModules;

import * as Types from "./types";

if (!RNZoom) console.error("RNZoom native module is not linked.");

const DEFAULT_USER_TYPE = 2;

const subscriptions = {};

async function initialize(
  params: Types.RNZoomInitializeParams,
  settings: {
    // ios only
    disableShowVideoPreviewWhenJoinMeeting?: boolean;
  } = {
    disableShowVideoPreviewWhenJoinMeeting: true,
  }
): Promise<{ initialized: boolean }> {
  if (!params.domain) params.domain = "zoom.us";

  return RNZoom.initialize(params, settings);
}

async function joinMeeting(params: Types.RNZoomJoinMeetingParams) {
  let { meetingNumber, noAudio = false, noVideo = false } = params;
  if (!meetingNumber) {
    throw new Error("Zoom.joinMeeting requires meetingNumber");
  }
  if (typeof meetingNumber !== "string") {
    meetingNumber = meetingNumber.toString();
  }

  return RNZoom.joinMeeting({
    ...params,
    meetingNumber,
    noAudio: !!noAudio, // required
    noVideo: !!noVideo, // required
  });
}

async function startMeeting(params: Types.RNZoomStartMeetingParams) {
  let { userType = DEFAULT_USER_TYPE, meetingNumber } = params;

  if (!meetingNumber) {
    throw new Error("Zoom.startMeeting requires meetingNumber");
  }
  if (typeof meetingNumber !== "string") {
    meetingNumber = meetingNumber.toString();
  }

  return RNZoom.startMeeting({ userType, ...params, meetingNumber });
}

async function joinMeetingWithWebUrl(url: string) {
  return RNZoom.joinMeetingWithWebUrl(url);
}

async function getMyUserMeetingInfo(): Promise<Types.RNZoomMyselfMeetingInfo> {
  return RNZoom.getMyUserMeetingInfo();
}

// Listeners
function onInitResults(callback: Types.RNZoomInitResultEventCallback) {
  if (subscriptions[Types.RNZoomSubscriptionEvents.INITIALIZE_RESULT_EVENT]) {
    return;
  }
  const listener =
    Platform.OS === "ios" ? new NativeEventEmitter(RNZoom) : DeviceEventEmitter;

  subscriptions[
    Types.RNZoomSubscriptionEvents.INITIALIZE_RESULT_EVENT
  ] = listener.addListener(
    Types.RNZoomSubscriptionEvents.INITIALIZE_RESULT_EVENT,
    callback
  );
}

function addMeetingStatusEventListener(
  callback: Types.RNZoomMeetingStatusEventCallback
) {
  if (
    subscriptions[Types.RNZoomSubscriptionEvents.MEETING_STATUS_CHANGE_EVENT]
  ) {
    console.log("Zoom already has subscription meeting status event");
    return;
  }
  const listener =
    Platform.OS === "ios" ? new NativeEventEmitter(RNZoom) : DeviceEventEmitter;

  subscriptions[
    Types.RNZoomSubscriptionEvents.MEETING_STATUS_CHANGE_EVENT
  ] = listener.addListener(
    Types.RNZoomSubscriptionEvents.MEETING_STATUS_CHANGE_EVENT,
    callback
  );
}
function removeMeetingStatusEventListener() {
  if (
    !subscriptions[Types.RNZoomSubscriptionEvents.MEETING_STATUS_CHANGE_EVENT]
  ) {
    return;
  }

  subscriptions[
    Types.RNZoomSubscriptionEvents.MEETING_STATUS_CHANGE_EVENT
  ].remove();
  delete subscriptions[
    Types.RNZoomSubscriptionEvents.MEETING_STATUS_CHANGE_EVENT
  ];
}

function addInMeetingEventListener(
  callback: Types.RNZoomInMeetingEventCallback
) {
  if (subscriptions[Types.RNZoomSubscriptionEvents.IN_MEETING_EVENT]) {
    console.log("Zoom already has subscription in meeting event");
    return;
  }
  const listener =
    Platform.OS === "ios" ? new NativeEventEmitter(RNZoom) : DeviceEventEmitter;

  subscriptions[
    Types.RNZoomSubscriptionEvents.IN_MEETING_EVENT
  ] = listener.addListener(
    Types.RNZoomSubscriptionEvents.IN_MEETING_EVENT,
    callback
  );
}
function removeInMeetingEventListener() {
  if (!subscriptions[Types.RNZoomSubscriptionEvents.IN_MEETING_EVENT]) {
    return;
  }

  subscriptions[Types.RNZoomSubscriptionEvents.IN_MEETING_EVENT].remove();
  delete subscriptions[Types.RNZoomSubscriptionEvents.IN_MEETING_EVENT];
}

export default {
  initialize,
  joinMeeting,
  startMeeting,
  joinMeetingWithWebUrl,
  getMyUserMeetingInfo,
  onInitResults,
  addMeetingStatusEventListener,
  removeMeetingStatusEventListener,
  addInMeetingEventListener,
  removeInMeetingEventListener,
};
