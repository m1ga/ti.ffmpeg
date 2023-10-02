/**
 * ti.ffmpeg
 *
 * Created by Christian Clare, Tambit Software, 2023
 *
 */

#import "TiFfmpegModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiFfmpegModule

#pragma mark Internal

- (id)moduleGUID
{
    return @"eb17ed6a-9cbe-433f-bc93-16cc91810514";
}

- (NSString *)moduleId
{
    return @"ti.ffmpeg";
}

#pragma mark Lifecycle

- (void)startup
{
    // This method is called when the module is first loaded
    // You *must* call the superclass
    [super startup];
    DebugLog(@"[DEBUG] %@ loaded", self);
}

#pragma Public APIs

- (void)run:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);

    NSString *input = [args objectForKey:@"input"];
    // Inputs is an array of NSDictionary
    NSArray *inputs = [args objectForKey:@"inputs"];
    NSString *output = [args objectForKey:@"output"];
    NSString *watermark = [args objectForKey:@"watermark"];
    NSString *options = [args objectForKey:@"options"];

    NSLog(@"watermark: %@", watermark);

    _successCallback = [args objectForKey:@"success"];
    _errorCallback = [args objectForKey:@"error"];
    _logCallback = [args objectForKey: @"log"];
    _progressCallback = [args objectForKey: @"progress"];

    if (watermark != nil && ![[NSString stringWithFormat:@"%@", watermark] isEqualToString:@""]) {
        watermark = [NSString stringWithFormat:@"-i %@", watermark];
    } else {
        watermark = @"";
    }

    NSLog(@"input: %@", input);
    NSLog(@"output: %@", output);
    NSLog(@"watermark: %@", watermark);
    NSLog(@"options: %@", options);
    NSLog(@"inputs: %@", inputs);

    NSString *inputCommandLine = @"";

    if (input != nil) {
        NSLog(@"input processing...");
        inputCommandLine = [NSString stringWithFormat: @"-i %@", input];
    } else if (inputs != nil) {
        NSLog(@"inputs processing...");
        // Loop through files and options adding
        for (int i = 0; i < [inputs count]; i++) {
            NSDictionary *singleInput = inputs[i];
            NSString *option = [singleInput valueForKey:@"option"];
            inputCommandLine = [inputCommandLine stringByAppendingFormat:@"%@ -i %@ ", (option != nil ? option : @""), [singleInput valueForKey:@"input"]];
        }
    }

    NSLog(@"inputCommandLine: %@", inputCommandLine);

    NSString *commandLine = [NSString stringWithFormat: @"%@ %@ %@ %@", inputCommandLine, watermark, options, output];

    NSLog(@"commandLine: %@", commandLine);

    FFmpegSession* session = [FFmpegKit executeAsync:commandLine withCompleteCallback:^(FFmpegSession* session){

        SessionState state = [session getState];
        ReturnCode *returnCode = [session getReturnCode];

        NSLog(@"FFmpeg process exited with state %@ and rc %@.%@", [FFmpegKitConfig sessionStateToString:state], returnCode, [session getFailStackTrace]);

        if (returnCode != nil && [returnCode.description isEqualToString:@"0"]) {
            NSLog(@"FFmpeg returned success...")
            NSLog(@"returnCode.description: %@", returnCode.description);
            NSDictionary *event = @{ @"success" : @(YES) };
            [self fireSuccessCallbackWithDict: event];
        } else {
            NSLog(@"FFmpeg returned failure...")
            // Get last line of output as that is normally where the error is reported
            NSString *output = [session getOutput];
            NSString *error = [self getLastLine:output];
            NSLog(@"Error: %@", error);
            NSDictionary *event = @{
                @"success" : @(NO),
                @"error" : error != nil ? error : @""
            };
            [self fireErrorCallbackWithDict: event];
        }

    } withLogCallback:^(Log *log) {

        if (log != nil) {
            NSDictionary *event = @{ @"message" : [log getMessage] };

            [self fireLogCallbackWithDict: event];
            // NSLog(@"FFmpeg process logged %@", [log getMessage]);
        }

    } withStatisticsCallback:^(Statistics *statistics) {

        if (statistics != nil) {
            // This is causing a crash - probably because one of the get calls is failing
            // NSLog(@"FFmpeg process statistics: frame: %@, time: %@, bitrate: %@, speed: %@", [statistics getVideoFrameNumber], [statistics getTime], [statistics getBitrate], [statistics getSpeed]);
            NSLog(@"FFmpeg process statistics: frame: %@, size: %@, currentTime: %@", [@([statistics getVideoFrameNumber]) stringValue], [@([statistics getSize]) stringValue], [@([statistics getTime]) stringValue]);
            NSDictionary *event = @{
                @"frame" : [@([statistics getVideoFrameNumber]) stringValue],
                @"size" : [@([statistics getSize]) stringValue],
                @"currentTime" : [@([statistics getTime]) stringValue],

            };
            [self fireProgressCallbackWithDict: event];
        }

    }];

}

- (void)info:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);

    NSString *options = [args objectForKey:@"options"];

    if (options == nil || [options isEqualToString:@""]) {
        NSLog(@"Info call failed: options not available");
        return;
    }

    // NSLog(@"options: %@", options);

    NSString *commandLine = [NSString stringWithFormat: @"%@", options];

    // NSLog(@"commandLine: %@", commandLine);

    FFmpegSession* session = [FFmpegKit executeAsync:commandLine withCompleteCallback:^(FFmpegSession* session){

        NSString *output = [session getOutput];
        NSLog(@"output: %@", output);

    } withLogCallback:^(Log *log) {

    } withStatisticsCallback:^(Statistics *statistics) {

    }];

}

- (void)fireSuccessCallbackWithDict:(NSDictionary *)dict
{
    if (_successCallback) {
        [self _fireEventToListener:@"success" withObject:dict listener:_successCallback thisObject:nil];
    }
}

- (void)fireErrorCallbackWithDict:(NSDictionary *)dict
{
    if (_errorCallback) {
        [self _fireEventToListener:@"error" withObject:dict listener:_errorCallback thisObject:nil];
    }
}

- (void)fireLogCallbackWithDict:(NSDictionary *)dict
{
    if (_logCallback) {
        [self _fireEventToListener:@"log" withObject:dict listener:_logCallback thisObject:nil];
    }
}

- (void)fireProgressCallbackWithDict:(NSDictionary *)dict
{
    if (_progressCallback) {
        [self _fireEventToListener:@"progress" withObject:dict listener:_progressCallback thisObject:nil];
    }
}

- (NSString*)getLastLine:(NSString*)textString
{
    if (textString == nil) {
        return @"";
    }
    NSUInteger stringLength = [textString length];
    NSUInteger paragraphStart = 0;
    NSUInteger paragraphEnd = 0;
    NSUInteger bodyEnd = 0;
    NSMutableArray *lineArray = [NSMutableArray array];
    NSRange range;
    while (paragraphEnd < stringLength)
    {
        [textString getParagraphStart: &paragraphStart end: &paragraphEnd
                          contentsEnd: &bodyEnd forRange:NSMakeRange(paragraphEnd, 0)];
        range = NSMakeRange(paragraphStart, bodyEnd - paragraphStart);
        [lineArray addObject:[textString substringWithRange:range]];
    }

    if ([lineArray count] == 0) {
        return @"";
    } else {
        return [lineArray lastObject];
    }

}


@end
