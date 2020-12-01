
#import "RNZoom.h"

@implementation RNZoom

- (instancetype)init {
    self = [super init];
    return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(
                 initialize,
                 data: (NSDictionary *)data
                 withSettings: (NSDictionary *)settings
                 withResolve: (RCTPromiseResolveBlock)resolve
                 withReject: (RCTPromiseRejectBlock)reject
)
{
  @try {

      MobileRTCSDKInitContext *context = [[MobileRTCSDKInitContext alloc] init];
      
      context.domain = data[@"domain"];;
      context.enableLog = YES;
      context.locale = MobileRTC_ZoomLocale_Default;
      
      NSDictionary *res = @{
          @"initialized": [NSNumber numberWithBool:[[MobileRTC sharedRTC] isRTCAuthorized]]
      };
      if ([[MobileRTC sharedRTC] isRTCAuthorized]) {
          resolve(res);
          return;
      }

      //Note: This step is optional, Method is uesd for iOS Replaykit Screen share integration,if not,just ignore this step.
      // context.appGroupId = @"group.zoom.us.MobileRTCSampleExtensionReplayKit";
      [[MobileRTC sharedRTC] initialize:context];
      
      [[[MobileRTC sharedRTC] getMeetingSettings]
      disableShowVideoPreviewWhenJoinMeeting:settings[@"disableShowVideoPreviewWhenJoinMeeting"]];

      MobileRTCAuthService *authService = [[MobileRTC sharedRTC] getAuthService];
      if (authService) {
          authService.delegate = self;
          authService.clientKey = data[@"clientKey"];
          authService.clientSecret = data[@"clientSecret"];
          [authService sdkAuth];
          resolve(res);
      } else {
          NSLog(@"onZoomSDKInitializeResult, no authService");
          reject(@"onZoomSDKInitializeResult", @"no authService", nil);
      }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing initialize", ex);
  }
}

RCT_REMAP_METHOD(
                 startMeeting,
                 data: (NSDictionary *)data
                 startMeetingResolver: (RCTPromiseResolveBlock)resolve
                 rejecter: (RCTPromiseRejectBlock)reject
)
{
    @try {
        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
        if (ms) {
          ms.delegate = self;
          MobileRTCMeetingStartParam4WithoutLoginUser *params = [[MobileRTCMeetingStartParam4WithoutLoginUser alloc]init];
          params.userName = data[@"userName"];
          params.meetingNumber = data[@"meetingNumber"];
          params.userID = data[@"userId"];
          params.zak = data[@"zoomAccessToken"];

          MobileRTCMeetError startMeetingResult = [ms startMeetingWithStartParam:params];
          NSLog(@"startMeeting, startMeetingResult=%d", startMeetingResult);
            resolve(nil);
        } else {
            reject(@"onStartMeetingResult", @"no MeetingService", nil);
        }
  } @catch (NSError *ex) {
        reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing startMeeting", ex);
  }
}

RCT_REMAP_METHOD(
                 joinMeeting,
                 data: (NSDictionary *)data
                 joinMeetingResolver: (RCTPromiseResolveBlock)resolve
                 rejecter: (RCTPromiseRejectBlock)reject
)
{
    @try {
        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
        if (ms) {
            ms.delegate = self;

          MobileRTCMeetingJoinParam * joinParam = [[MobileRTCMeetingJoinParam alloc]init];
          joinParam.userName = data[@"userName"];
          joinParam.password =  data[@"password"];
          joinParam.zak = data[@"zoomAccessToken"];
            if (data[@"vanityID"]) {
                joinParam.vanityID = data[@"vanityID"];
            } else {
                joinParam.meetingNumber = data[@"meetingNumber"];
            }
            
            if (data[@"participantID"]) {
                joinParam.participantID = data[@"participantID"];
            }
            if (data[@"webinarToken"]) {
                joinParam.webinarToken =  data[@"webinarToken"];
            }
            if (data[@"noAudio"]) {
                joinParam.noAudio = data[@"noAudio"];
            }
            if (data[@"noVideo"]) {
                joinParam.noVideo = data[@"noVideo"];
            }
          
            
            MobileRTCMeetError joinMeetingResult = [ms joinMeetingWithJoinParam:joinParam];
            NSLog(@"joinMeeting, joinMeetingResult=%d", joinMeetingResult);
            resolve(nil);
        } else {
            reject(@"onJoinMeeting", @"no MeetingService", nil);
        }
  } @catch (NSError *ex) {
        reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing joinMeeting", ex);
  }
}

RCT_REMAP_METHOD(
                 joinMeetingWithWebUrl,
                 url: (NSString *)url
                 joinMeetingResolver: (RCTPromiseResolveBlock)resolve
                 rejecter: (RCTPromiseRejectBlock)reject
)
{
  @try {
    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    if (ms) {
        ms.delegate = self;

        MobileRTCMeetError joinMeetingResult = [ms handZoomWebUrl:url];
        NSLog(@"joinMeetingWithWebUrl, joinMeetingResult=%d", joinMeetingResult);
        
        resolve(nil);
    } else {
        reject(@"onJoinMeetingWithWebUrl", @"no MeetingService", nil);
    }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing joinMeetingWithWebUrl", ex);
  }
}

RCT_REMAP_METHOD(getMyUserMeetingInfo,
                 withResolve:(RCTPromiseResolveBlock)resolve
                 withReject:(RCTPromiseRejectBlock)reject
)
{
  @try {
      MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
      if (!ms) {
          return reject(@"ERR_MEETING_SERVICE", @"could not approach zoom meeting", nil);
      }
            
      MobileRTCMeetingState meetingState = ms.getMeetingState;
      if (meetingState == MobileRTCMeetingState_InMeeting) {
          NSMutableDictionary *dict = [self getUserInfoByUserId:[ms myselfUserID]];
          return resolve(dict);
      }
      
      reject(@"ERR_MEETING_SERVICE", @"user has not joined meeting", nil);
      
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing getMyUserMeetingInfo", ex);
  }
}


/** Listeners */
- (NSArray<NSString *> *)supportedEvents
{
  return @[@"InitializeResultEvent", @"MeetingStatusChangedEvent", @"InMeetingEvent"];
}

- (void)onMobileRTCAuthReturn:(MobileRTCAuthError)returnValue {
    NSLog(@"onZoomSDKInitializeResult, errorCode=%d", returnValue);
    
    BOOL success = returnValue == MobileRTCAuthError_Success;
    int errorCode = success ? 0 : 1;
    
    NSDictionary *body = @{
        @"success": [NSNumber numberWithBool:success],
        @"errorCode": [NSNumber numberWithInt:errorCode]
    };
    [self sendEventWithName:@"InitializeResultEvent" body:body];
}

- (void)onMeetingReturn:(MobileRTCMeetError)errorCode internalError:(NSInteger)internalErrorCode {
    NSLog(@"onMeetingReturn, error=%d, internalErrorCode=%zd", errorCode, internalErrorCode);
}

- (void)onMeetingStateChange:(MobileRTCMeetingState)state {
    NSLog(@"onMeetingStatusChanged, meetingState=%d", state);
    
    BOOL success = state == MobileRTCMeetingState_InMeeting;
    int errorCode = success ? 0 : 1;
    
    NSString *status;
    switch (state) {
        case MobileRTCMeetingState_Idle:
            status = @"left";
            break;
        case MobileRTCMeetingState_Connecting:
            status = @"connecting";
            break;
        case MobileRTCMeetingState_InMeeting:
            status = @"joined";
            break;
        default:
            status = @"other";
            break;
    }
    
    NSDictionary *body = @{
        @"inMeeting": [NSNumber numberWithBool:success],
        @"status": status,
        @"payload": @{
                @"meetingStatus": [NSString stringWithFormat:@"%u", state],
                @"errorCode": [NSNumber numberWithInt:errorCode]
        }
    };
    [self sendEventWithName:@"MeetingStatusChangedEvent" body:body];
}

- (void)onMeetingError:(MobileRTCMeetError)errorCode message:(NSString *)message {
    NSLog(@"onMeetingError, errorCode=%d, message=%@", errorCode, message);
}


- (void) notifyInMeetingEvent:(NSString *)event params:(NSDictionary *)params {
    NSDictionary *body = @{
        @"event": event,
        @"payload": params
    };
    [self sendEventWithName:@"InMeetingEvent" body:body];
}

- (NSMutableDictionary *)getUserInfoByUserId:(NSUInteger)userID {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    MobileRTCMeetingUserInfo *userInfo = [ms userInfoByID:userID];
    [dict setObject:[NSString stringWithFormat:@"%li",  userID] forKey:@"userId"];
    if (userInfo.userName != nil) {
        [dict setObject:userInfo.userName forKey:@"name"];
    }
    return dict;
}

- (void)onSinkMeetingActiveVideo:(NSUInteger)userID {
    [self notifyInMeetingEvent:@"meeting.user.video.active" params:[self getUserInfoByUserId:userID]];
}

- (void)onSinkMeetingVideoStatusChange:(NSUInteger)userID {
    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    MobileRTCMeetingUserInfo *userInfo = [ms userInfoByID:userID];
    BOOL active = [[userInfo videoStatus] isSending];
    [self notifyInMeetingEvent:@"meeting.user.video.status" params:@{
        @"userId": [NSString stringWithFormat:@"%li",  userID],
        @"name": userInfo.userName,
        @"active": [NSNumber numberWithBool:active]
    }];
}

- (void)onSinkMeetingAudioStatusChange:(NSUInteger)userID {
    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    MobileRTCMeetingUserInfo *userInfo = [ms userInfoByID:userID];
    BOOL muted = [[userInfo audioStatus] isMuted];
    [self notifyInMeetingEvent:@"meeting.user.audio.status" params:@{
        @"userId": [NSString stringWithFormat:@"%li",  userID],
        @"name": userInfo.userName,
        @"muted": [NSNumber numberWithBool:muted]
    }];
}

- (void)onAudioOutputChange {}


- (void)onMyAudioStateChange {}


- (void)onSinkMeetingAudioRequestUnmuteByHost {}


- (void)onSinkMeetingMyAudioTypeChange {}


- (void)onSinkMeetingActiveVideoForDeck:(NSUInteger)userID {
    [self notifyInMeetingEvent:@"meeting.user.video.speaker" params:[self getUserInfoByUserId:userID]];
}

- (void)onMyVideoStateChange {}


- (void)onSinkMeetingPreviewStopped {}


- (void)onSinkMeetingShowMinimizeMeetingOrBackZoomUI:(MobileRTCMinimizeMeetingState)state {}


- (void)onSinkMeetingVideoQualityChanged:(MobileRTCNetworkQuality)qality userID:(NSUInteger)userID {}


- (void)onSinkMeetingVideoRequestUnmuteByHost:(void (^ _Nonnull)(BOOL))completion {}


- (void)onSpotlightVideoChange:(BOOL)on {}


- (void)onSinkMeetingUserJoin:(NSUInteger)userID {
    [self notifyInMeetingEvent:@"meeting.user.joined" params:[self getUserInfoByUserId:userID]];
}

- (void)onSinkMeetingUserLeft:(NSUInteger)userID {
    [self notifyInMeetingEvent:@"meeting.user.left" params:[self getUserInfoByUserId:userID]];
}

- (void)onClaimHostResult:(MobileRTCClaimHostError)error {}


- (void)onInMeetingUserUpdated {}


- (void)onMeetingCoHostChange:(NSUInteger)cohostId {}


- (void)onMeetingHostChange:(NSUInteger)hostId {}


- (void)onMyHandStateChange {}


- (void)onSinkMeetingUserLowerHand:(NSUInteger)userID {}


- (void)onSinkMeetingUserRaiseHand:(NSUInteger)userID {}


- (void)onSinkUserNameChanged:(NSUInteger)userID userName:(NSString * _Nonnull)userName {}


@end
