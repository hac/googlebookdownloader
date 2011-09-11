#import "WebKit/WebKit.h"

@interface WebView (FakeClicking)

- (NSString *)runScript:(NSString *)scriptName;

- (void)simulateMouseClick:(NSPoint)where;
- (NSPoint)locationOfElementWithId:(NSString *)elementId;
- (BOOL)clickElementWithId:(NSString *)elementId
					repeat:(int)times;

@end
