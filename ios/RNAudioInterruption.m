#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <AVFoundation/AVFoundation.h>

@interface RNAudioInterruption : RCTEventEmitter <RCTBridgeModule>
@property(nonatomic, assign) BOOL observing;
@end

@implementation RNAudioInterruption
RCT_EXPORT_MODULE();
- (NSArray<NSString *> *)supportedEvents { return @[@"audioInterruption"]; }
- (void)dealloc { if (_observing) [self removeNotif]; }

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
@end
