#import <Foundation/Foundation.h>
#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>
#import "VisionCameraPoseLandmarksPlugin-Swift.h"

@interface PoseLandmarksPlugin (FrameProcessorPluginLoader)
@end

@implementation PoseLandmarksPlugin (FrameProcessorPluginLoader)
+ (void) load {
  [FrameProcessorPluginRegistry addFrameProcessorPlugin:@"detectPoseLandmarks"
    withInitializer:^FrameProcessorPlugin*(VisionCameraProxyHolder* proxy, NSDictionary* options) {
    return [[PoseLandmarksPlugin alloc] initWithProxy:proxy withOptions:options];
  }];
}
@end
