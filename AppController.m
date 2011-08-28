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

- (void)openDonateURL:(id)sender
{
	NSString *donateURL = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Donate URL"];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:donateURL]];
}

- (void)showDonateAlert
{
	int button = NSRunAlertPanel(@"Please Donate!", @"The many hours spent maintaining and improving Google Book Downloader are paid for by donations. Please show your support by donating—that's the best way to ensure this application will continue to improve!", @"Donate!", @"No, thanks", nil);
	if (button == 1)
	{
		[self openDonateURL:nil];
	}
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DonateAlertShown"];
}

@end
