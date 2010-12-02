#import <Foundation/Foundation.h>

#import "GoogleBookDelegate.h"

// We use PDFKit from Quartz to make a PDF of the book from the JPEGs that Google Books returns.
#import <Quartz/Quartz.h>

@interface GoogleBook : NSObject
{
	id <GoogleBookDelegate> delegate;

	NSString *bookId, *initialIndexJSON;

	NSMutableDictionary *imageIndex;
	NSMutableArray *pageOrder;

	BOOL shouldAbortAsSoonAsPossible;
}

- (void)setDelegate:(id)newDelegate;
- (id)delegate;

- (void)setBookId:(NSString *)newBookId;
- (NSString *)bookId;

- (NSString *)bookTitle;

- (BOOL)bookExists;
- (BOOL)bookIsValid;
- (BOOL)completeIndex;

- (PDFDocument *)pdfDocument;

- (BOOL)saveImagesToFolder:(NSString *)folderPath;

// Calling this stops completeIndex or pdfDocument as soon as possible. It is called when the user clicks the cancel button.
- (void)abortProcedures;

@end
