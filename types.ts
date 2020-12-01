export enum RNZoomSubscriptionEvents {
  INITIALIZE_RESULT_EVENT = "InitializeResultEvent",
  MEETING_STATUS_CHANGE_EVENT = "MeetingStatusChangedEvent",
  IN_MEETING_EVENT = "InMeetingEvent",
}

export interface RNZoomInitializeParams {
  clientKey: string;
  clientSecret: string;
  domain?: string;
}

export interface RNZoomJoinMeetingParams {
  userName: string;
  meetingNumber: string | number;
  password?: string;
  participantID?: string;
  vanityID?: string;
  noAudio?: boolean;
  noVideo?: boolean;

  // ios only fields:
  zoomAccessToken?: string;
  webinarToken?: string;
}

export interface RNZoomStartMeetingParams {
  userName: string;
  meetingNumber: string | number;
  userId: string;
  userType?: number;
  zoomAccessToken: string;
}

export interface RNZoomMyselfMeetingInfo {
  name: string;
  userId: string;
}

export type RNZoomInitResultEventCallback = ({
  success,
  errorCode,
}: {
  success: boolean;
  errorCode: number;
}) => void;
export type RNZoomMeetingStatusEventCallback = ({
  inMeeting,
  status,
  payload,
}: {
  inMeeting: boolean;
  status: string;
  payload: { meetingStatus: string; errorCode: number };
}) => void;
export type RNZoomInMeetingEventCallback = (
  { event, payload },
  { event: string, payload: any }
) => void;
