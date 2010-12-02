#import <Cocoa/Cocoa.h>

// The PDF is a Quartz object.
#import <Quartz/Quartz.h>

#import "GoogleBook.h"

#import "GoogleBookDelegate.h"

@interface MyDocument : NSDocument <GoogleBookDelegate>
{
	IBOutlet NSTextField *locationBar;
	
	// These are for the save sheet:
	NSSavePanel *savePanel;
	IBOutlet NSView *formatChooserView;
	IBOutlet NSPopUpButton *formatChooserButton;
	BOOL saveAsFolder;
	
	// These are in the progress indicator sheet:
	IBOutlet NSTextField *progressLabel;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSButton *cancelButton;
	
	// This is the book that downloads and compiles our book data.
	GoogleBook *book;
	
	NSString *savePath;
	
	// This is where we hold all the data when the user is choosing a place to save the file.
	PDFDocument *pdfDocument;
	
	// Remember the last error encountered in these strings.
	NSString *errorMessage, *errorInformation;
	
	BOOL userWantsToAbort;
}

- (IBAction)beginDownload:(id)sender;
- (IBAction)cancelDownload:(id)sender;

- (IBAction)saveFormatChanged:(id)sender;

@end
