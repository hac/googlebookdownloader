#import <Foundation/Foundation.h>

#import "GoogleBookDelegate.h"

// We use PDFKit from Quartz to make a PDF of the book from the JPEGs that Google Books returns.
#import <Quartz/Quartz.h>

#import "ResourceDownloader.h"

@interface GoogleBook : ResourceDownloader
{
	id <GoogleBookDelegate> delegate;

	NSString *bookId, *folderPath;
	NSMutableString *htmlBody;
	
	NSMutableArray *pdfIndex;
	NSMutableDictionary *pageNumberMap;
	
	BOOL shouldAbortAsSoonAsPossible, scrollComplete, isPDF, zoomedIn;
	
	int pagesDownloaded;
	
	PDFDocument *pdfDocument;
}

- (void)setDelegate:(id)newDelegate;
- (id)delegate;

- (void)setBookId:(NSString *)newBookId;
- (NSString *)bookId;

- (NSString *)bookTitle;

- (BOOL)bookExists;

- (PDFDocument *)pdfDocument;

- (BOOL)saveImagesToFolder:(NSString *)folderPath;

// Calling this stops completeIndex or pdfDocument as soon as possible. It is called when the user clicks the cancel button.
- (void)abortProcedures;

@end
