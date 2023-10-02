/**
 * ti.ffmpeg
 *
 * Created by Christian Clare, Tambit Software, 2023
 */

#import "TiModule.h"
#include <ffmpegkit/FFmpegKit.h>

@interface TiFfmpegModule : TiModule {
    KrollCallback *_successCallback;
    KrollCallback *_errorCallback;
    KrollCallback *_logCallback;
    KrollCallback *_progressCallback;
}

@end
