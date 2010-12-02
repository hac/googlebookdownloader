#import "HacSavePanelAdditions.h"

@implementation NSSavePanel (HacSavePanelAdditions)

// This method lets you change the filename after the save panel is open.
// This allows us to remove the extension when the user selects the option to save as a directory.
- (void)setFilename:(NSString *)filename
{
	[self setDirectory:[filename stringByDeletingLastPathComponent]];
	[_nameField setStringValue:[filename lastPathComponent]];
}

@end
