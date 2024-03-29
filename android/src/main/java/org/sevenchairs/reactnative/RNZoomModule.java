package org.sevenchairs.reactnative;

import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import us.zoom.sdk.InMeetingService;
import us.zoom.sdk.InMeetingUserInfo;
import us.zoom.sdk.ZoomSDK;
import us.zoom.sdk.ZoomError;
import us.zoom.sdk.ZoomSDKInitParams;
import us.zoom.sdk.ZoomSDKInitializeListener;

import us.zoom.sdk.MeetingStatus;
import us.zoom.sdk.MeetingError;
import us.zoom.sdk.MeetingService;
import us.zoom.sdk.MeetingServiceListener;

import us.zoom.sdk.StartMeetingOptions;
import us.zoom.sdk.StartMeetingParamsWithoutLogin;

import us.zoom.sdk.JoinMeetingOptions;
import us.zoom.sdk.JoinMeetingParams;

public class RNZoomModule extends ReactContextBaseJavaModule implements ZoomSDKInitializeListener, MeetingServiceListener, LifecycleEventListener {

  private final static String TAG = "RNZoom";
  private final ReactApplicationContext reactContext;


  public RNZoomModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    reactContext.addLifecycleEventListener(this);
  }

  @Override
  public String getName() {
    return "RNZoom";
  }

  @ReactMethod
  public void initialize(final ReadableMap params, final ReadableMap settings, final Promise promise) {
    try {
      reactContext.getCurrentActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          ZoomSDK zoomSDK = ZoomSDK.getInstance();
          WritableMap map = Arguments.createMap();
          map.putBoolean("initialized", zoomSDK.isInitialized());
          if (!zoomSDK.isInitialized()) {
            ZoomSDKInitParams initParams = new ZoomSDKInitParams();
            initParams.appKey = params.getString("clientKey");
            initParams.appSecret = params.getString("clientSecret");
            initParams.domain = params.getString("domain");
            zoomSDK.initialize(getReactApplicationContext(), RNZoomModule.this, initParams);
          }
          promise.resolve(map);
        }
      });
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }

  @ReactMethod
  public void startMeeting(
          final ReadableMap paramMap,
          Promise promise
  ) {
    try {
      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_START", "ZoomSDK has not been initialized successfully");
        return;
      }

      final String meetingNo = paramMap.getString("meetingNumber");
      final MeetingService meetingService = zoomSDK.getMeetingService();
      if(meetingService.getMeetingStatus() != MeetingStatus.MEETING_STATUS_IDLE) {
        long lMeetingNo = 0;
        try {
          lMeetingNo = Long.parseLong(meetingNo);
        } catch (NumberFormatException e) {
          promise.reject("ERR_ZOOM_START", "Invalid meeting number: " + meetingNo);
          return;
        }

        if(meetingService.getCurrentRtcMeetingNumber() == lMeetingNo) {
          meetingService.returnToMeeting(reactContext.getCurrentActivity());
          promise.resolve("Already joined zoom meeting");
          return;
        }
      }

      StartMeetingOptions opts = new StartMeetingOptions();
      StartMeetingParamsWithoutLogin params = new StartMeetingParamsWithoutLogin();
      params.displayName = paramMap.getString("userName");
      params.meetingNo = paramMap.getString("meetingNumber");
      params.userId = paramMap.getString("userId");
      params.userType = paramMap.getInt("userType");
      params.zoomAccessToken = paramMap.getString("zoomAccessToken");

      int startMeetingResult = meetingService.startMeetingWithParams(reactContext.getCurrentActivity(), params, opts);
      Log.i(TAG, "startMeeting, startMeetingResult=" + startMeetingResult);

      if (startMeetingResult != MeetingError.MEETING_ERROR_SUCCESS) {
        promise.reject("ERR_ZOOM_START", "startMeeting, errorCode=" + startMeetingResult);
        return;
      }

      promise.resolve(null);
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }

  @ReactMethod
  public void joinMeeting(
          final ReadableMap paramMap,
          Promise promise
  ) {
    try {
      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_JOIN", "ZoomSDK has not been initialized successfully");
        return;
      }

      final MeetingService meetingService = zoomSDK.getMeetingService();

      JoinMeetingOptions opts = new JoinMeetingOptions();
      if (paramMap.hasKey("participantID")) opts.participant_id = paramMap.getString("participantID");
      if (paramMap.hasKey("noAudio")) opts.no_audio = paramMap.getBoolean("noAudio");
      if (paramMap.hasKey("noVideo")) opts.no_video = paramMap.getBoolean("noVideo");

      JoinMeetingParams params = new JoinMeetingParams();
      if (paramMap.hasKey("vanityID")) {
        params.vanityID = paramMap.getString("vanityID");
      } else {
        params.meetingNo = paramMap.getString("meetingNumber");
      }
      params.displayName = paramMap.getString("userName");
      if (paramMap.hasKey("password")) params.password = paramMap.getString("password");

      int joinMeetingResult = meetingService.joinMeetingWithParams(reactContext.getCurrentActivity(), params, opts);
      Log.i(TAG, "joinMeeting, joinMeetingResult=" + joinMeetingResult);

      if (joinMeetingResult != MeetingError.MEETING_ERROR_SUCCESS) {
        promise.reject("ERR_ZOOM_JOIN", "joinMeeting, errorCode=" + joinMeetingResult);
        return;
      }

      promise.resolve(null);
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }


  @ReactMethod
  public void joinMeetingWithWebUrl(
          final String url,
          final Promise promise
  )
  {
    try {
      final ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if (!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_JOIN", "ZoomSDK has not been initialized successfully");
        return;
      }

      reactContext.getCurrentActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          final MeetingService meetingService = zoomSDK.getMeetingService();
          boolean joinMeetingResult = meetingService.handZoomWebUrl(url);
          Log.i(TAG, "joinMeetingWithWebUrl, joinMeetingResult=" + joinMeetingResult);

          if (!joinMeetingResult) {
            promise.reject("ERR_ZOOM_JOIN", "joinMeetingWithWebUrl, result=" + joinMeetingResult);
            return;
          }

          promise.resolve(null);
        }
      });
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }

  @ReactMethod
  public void getMyUserMeetingInfo(Promise promise) {
    try {
      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_JOIN", "ZoomSDK has not been initialized successfully");
        return;
      }

      final MeetingService meetingService = zoomSDK.getMeetingService();
      final InMeetingService inMeetingService = zoomSDK.getInMeetingService();

      if (meetingService == null || inMeetingService == null) {
        promise.reject("ERR_MEETING_SERVICE", "could not approach zoom meeting");
        return;
      }

      if (meetingService.getMeetingStatus() == MeetingStatus.MEETING_STATUS_INMEETING) {
        InMeetingUserInfo userInfo = inMeetingService.getUserInfoById(inMeetingService.getMyUserID());
        WritableMap map = Arguments.createMap();
        map.putString("name", userInfo.getUserName());
        map.putString("userId", "" + userInfo.getUserId());
        promise.resolve(map);
        return;
      }

      promise.reject("ERR_MEETING_SERVICE", "user has not joined meeting");
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }

  @Override
  public void onZoomSDKInitializeResult(int errorCode, int internalErrorCode) {
    Log.i(TAG, "onZoomSDKInitializeResult, errorCode=" + errorCode + ", internalErrorCode=" + internalErrorCode);

    WritableMap map = Arguments.createMap();
    map.putBoolean("success", errorCode == ZoomError.ZOOM_ERROR_SUCCESS);
    map.putInt("errorCode", errorCode);
    reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("InitializeResultEvent", map);

    if (errorCode == ZoomError.ZOOM_ERROR_SUCCESS) {
      registerListener();
    }
  }

  @Override
  public void onZoomAuthIdentityExpired(){
  }

  @Override
  public void onMeetingStatusChanged(MeetingStatus meetingStatus, int errorCode, int internalErrorCode) {
    Log.i(TAG, "onMeetingStatusChanged, meetingStatus=" + meetingStatus + ", errorCode=" + errorCode + ", internalErrorCode=" + internalErrorCode);

    String status;
    switch (meetingStatus) {
      case MEETING_STATUS_IDLE:
      case MEETING_STATUS_DISCONNECTING:
        status = "left";
        break;
      case MEETING_STATUS_CONNECTING:
        status = "connecting";
        break;
      case MEETING_STATUS_INMEETING:
        status = "joined";
        break;
      default:
        status = "other";
        break;
    }

    WritableMap map = Arguments.createMap();
    map.putBoolean("inMeeting", meetingStatus == MeetingStatus.MEETING_STATUS_INMEETING);
    map.putString("status", status);

    WritableMap zoomPayload = Arguments.createMap();
    zoomPayload.putString("meetingStatus", meetingStatus.name());
    zoomPayload.putInt("errorCode", errorCode);
    map.putMap("payload", zoomPayload);

    reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("MeetingStatusChangedEvent", map);
  }


  private void registerListener() {
    Log.i(TAG, "registerListener");
    ZoomSDK zoomSDK = ZoomSDK.getInstance();
    MeetingService meetingService = zoomSDK.getMeetingService();
    if(meetingService != null) {
      Log.i(TAG, "registerListener meetingService");
      meetingService.addListener(this);
    }
    InMeetingService inMeetingService = zoomSDK.getInMeetingService();
    if (inMeetingService != null) {
      Log.i(TAG, "registerListener inMeetingService");
      inMeetingService.addListener(new RNZoomInMeetingServiceListener(reactContext, inMeetingService));
    }
  }

  private void unregisterListener() {
    Log.i(TAG, "unregisterListener");
    ZoomSDK zoomSDK = ZoomSDK.getInstance();
    if(zoomSDK.isInitialized()) {
      MeetingService meetingService = zoomSDK.getMeetingService();
      meetingService.removeListener(this);
    }
  }

  @Override
  public void onCatalystInstanceDestroy() {
    unregisterListener();
  }

  // React LifeCycle
  @Override
  public void onHostDestroy() {
    unregisterListener();
  }
  @Override
  public void onHostPause() {}
  @Override
  public void onHostResume() {}
}
