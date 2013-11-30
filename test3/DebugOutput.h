/************************************************************************
 * DebugOutput.h
 *
 * Definitions for DebugOutput class
 ************************************************************************/

// cf http://mobiledevelopertips.com/cocoa/filename-and-line-number-with-nslog-part-ii.html

// Show full path of filename?
#define DEBUG_SHOW_FULLPATH YES

// Enable debug (NSLog) wrapper code?
#define DEBUG 1

#if DEBUG
  #define debug(format,...) [[DebugOutput sharedDebug] output:__FILE__ lineNumber:__LINE__ input:(format), ##__VA_ARGS__]
#else
  #define debug(format,...) 
#endif
  
@interface DebugOutput : NSObject
{
}
+ (DebugOutput *) sharedDebug;
-(void)output:(char*)fileName lineNumber:(int)lineNumber input:(NSString*)input, ...;
@end
