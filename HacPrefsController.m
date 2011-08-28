#import "HacPrefsController.h"

#define defaultBookWidth 1000

@implementation HacPrefsController

- (void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	// These are the default preferences:
	NSDictionary *defaultDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									   [NSNumber numberWithInt:defaultBookWidth], @"BookWidth", 
									   [NSNumber numberWithBool:NO], @"UseCustomPageWidth",
									   [NSNumber numberWithBool:YES], @"AutoOpenDownloadsInFinder",
									   [NSNumber numberWithBool:NO], @"DonateAlertShown", nil];
	[defaults registerDefaults:defaultDictionary];
	
	[openBookInFinderAfterSaving setState:[defaults boolForKey:@"AutoOpenDownloadsInFinder"]];
	[documentWidth setIntValue:[defaults integerForKey:@"BookWidth"]];
	[widthPrefsMatrix setState:![defaults boolForKey:@"UseCustomPageWidth"]
						 atRow:1
						column:0];
	
	[documentWidth setDelegate:self];
	[[documentWidth window] setDelegate:self];
}

- (IBAction)savePrefs:(id)sender
{	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (sender == openBookInFinderAfterSaving)
		[defaults setBool:[openBookInFinderAfterSaving state] forKey:@"AutoOpenDownloadsInFinder"];
	
	if (sender == documentWidth)
		[defaults setInteger:[documentWidth intValue] forKey:@"BookWidth"];
	
	if (![documentWidth intValue])
		[documentWidth setIntValue:defaultBookWidth];
	else
		[documentWidth setIntValue:[documentWidth intValue]];
	
	[defaults setBool:![widthPrefsMatrix selectedRow] forKey:@"UseCustomPageWidth"];
	
	[documentWidth setEnabled:![widthPrefsMatrix selectedRow]];
	
	[self controlTextDidChange:nil];
}

#pragma mark -
#pragma mark Delegate Methods

- (void)controlTextDidChange:(NSNotification *)aNotification
{	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([documentWidth intValue] && [[[NSNumber numberWithInt:[documentWidth intValue]] stringValue] isEqualToString:[documentWidth stringValue]])
		[documentWidth setTextColor:[NSColor blackColor]];
	else
		[documentWidth setTextColor:[NSColor colorWithDeviceRed:.8 green:0 blue:0 alpha:1]];
	

	[defaults setInteger:[documentWidth intValue] forKey:@"BookWidth"];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[self savePrefs:nil];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	[self savePrefs:nil];
}

@end
