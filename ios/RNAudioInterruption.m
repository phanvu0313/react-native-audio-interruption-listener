#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <AVFoundation/AVFoundation.h>
#import <CallKit/CallKit.h>

@interface RNAudioInterruption : RCTEventEmitter <RCTBridgeModule, CXCallObserverDelegate>
@property(nonatomic, assign) BOOL observing;
@property(nonatomic, strong) CXCallObserver *callObserver;
@property(nonatomic, assign) BOOL hasActiveCall;
@end

@implementation RNAudioInterruption
RCT_EXPORT_MODULE();
- (NSArray<NSString *> *)supportedEvents { return @[@"audioInterruption"]; }
- (void)dealloc {
  if (_observing) [self removeNotif];
  if (@available(iOS 10.0, *)) {
    [_callObserver setDelegate:nil queue:nil];
  }
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (instancetype)init
{
  if (self = [super init]) {
    if (@available(iOS 10.0, *)) {
      _callObserver = [CXCallObserver new];
      [_callObserver setDelegate:self queue:nil];
      [self updateActiveCall];
    }
  }
  return self;
}

- (void)updateActiveCall
{
  if (@available(iOS 10.0, *)) {
    BOOL active = NO;
    for (CXCall *call in self.callObserver.calls) {
      if (!call.hasEnded) {
        active = YES;
        break;
      }
    }
    self.hasActiveCall = active;
  }
}

RCT_EXPORT_METHOD(start:(NSString *)mode)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    AVAudioSession *s = [AVAudioSession sharedInstance];
    NSError *err = nil;
    if ([mode isEqualToString:@"record"]) {
      [s setCategory:AVAudioSessionCategoryPlayAndRecord
         withOptions:AVAudioSessionCategoryOptionDuckOthers|AVAudioSessionCategoryOptionDefaultToSpeaker
               error:&err];
    } else {
      [s setCategory:AVAudioSessionCategoryPlayback
         withOptions:AVAudioSessionCategoryOptionDuckOthers
               error:&err];
    }
    [s setActive:YES error:&err];

    if (!self->_observing) {
      [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(onInterruption:)
        name:AVAudioSessionInterruptionNotification
        object:s];
      self->_observing = YES;
    }
  });
}

RCT_EXPORT_METHOD(stop)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self->_observing) [self removeNotif];
    NSError *err = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:&err];
  });
}

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call
  API_AVAILABLE(ios(10.0))
{
  [self updateActiveCall];
}

- (void)removeNotif {
  [[NSNotificationCenter defaultCenter] removeObserver:self
    name:AVAudioSessionInterruptionNotification
    object:[AVAudioSession sharedInstance]];
  _observing = NO;
}

- (void)onInterruption:(NSNotification *)note {
  AVAudioSessionInterruptionType t =
    [note.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
  NSString *state = (t == AVAudioSessionInterruptionTypeBegan) ? @"began" : @"ended";
  [self sendEventWithName:@"audioInterruption"
                     body:@{ @"platform": @"ios", @"state": state }];
}

RCT_REMAP_METHOD(isBusy,
                 isBusyWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL busy = self.hasActiveCall;
    if (!busy) {
      busy = session.isOtherAudioPlaying;
    }
    resolve(@(busy));
  });
}
@end
