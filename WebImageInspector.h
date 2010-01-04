#import <Cocoa/Cocoa.h>

#import <WebKit/WebKit.h>

@interface WebImageInspector : NSObject
{
	IBOutlet NSTextField *urlField;
	IBOutlet NSTextView *outputView;
	
	IBOutlet WebView *webView;
}

- (void)update:(id)sender;

@end