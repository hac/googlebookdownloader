#import <Foundation/Foundation.h>

@interface HacPrefsController : NSObject
{
	IBOutlet NSTextField *documentWidth;
	IBOutlet NSButton *openBookInFinderAfterSaving;
	IBOutlet NSMatrix *widthPrefsMatrix;
}

- (IBAction)savePrefs:(id)sender;

@end
