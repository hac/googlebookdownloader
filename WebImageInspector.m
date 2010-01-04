#import "WebImageInspector.h"

@implementation WebImageInspector

- (void)update:(id)sender
{
	NSURL *imageURL = [NSURL URLWithString:[urlField stringValue]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];
	
	NSLog([[request allHTTPHeaderFields] description]);
	
	[[webView mainFrame] loadRequest:request];
		
	NSURLResponse *resp = nil;
	NSError *err = nil;
	NSData *bdsData = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
	NSImage *image = [[NSImage alloc] initWithData:bdsData];
	[outputView setString:[NSString stringWithFormat:@"Width: %f\nHeight: %f", [image size].width, [image size].height]];
}


@end