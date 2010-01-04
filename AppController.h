#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
	IBOutlet NSTextView *logView;
}

AppController *sharedController;

+ (AppController *)sharedController;
+ (void)setSharedController:(AppController *)value;

- (void)writeStringToLog:(NSString *)string;

@end