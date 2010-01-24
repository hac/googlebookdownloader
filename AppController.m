#import "AppController.h"

@implementation AppController

+ (AppController *)sharedController
{
	return sharedController;
}

+ (void)setSharedController:(AppController *)value
{
	sharedController = value;
}

- (void)awakeFromNib
{
	[AppController setSharedController:self];
	[[AppController sharedController] writeStringToLog:@"Google Book Downloader Version 1.0b2"];
}

- (void)writeStringToLog:(NSString *)string
{
	[logView setString:[NSString stringWithFormat:@"%@%@\n\n", [logView string], string]];
	[logView setFont:[NSFont fontWithName:@"Monaco" size:10]];
}

- (void)openCompanyURL:(id)sender
{
	NSString *homePageURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Company URL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homePageURL]];
}

- (void)openAppURL:(id)sender
{
	NSString *homePageURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Application URL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homePageURL]];
}

@end
