#import "WebView+FakeClicking.h"

@implementation WebView (FakeClicking)

- (NSString *)runScript:(NSString *)scriptName
{
	NSString *inject = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:scriptName ofType:@"js"] usedEncoding:nil error:nil];
	return [self stringByEvaluatingJavaScriptFromString:inject];
}

// Originally from http://lists.apple.com/archives/cocoa-dev/2005/Sep/msg00159.html
- (void)simulateMouseClick:(NSPoint)where
{
	NSWindow *window = [self window];
	NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
	
	// Convert the point from NSView coordinates to NSWindow coordinates by shifting the origin.
	where.x += [self frame].origin.x;
	where.y += [self frame].origin.y;
	
	// Create a pair of events to simulate mouse down and mouse up.
	NSEvent *mouseDownEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
												 location:where
											modifierFlags:0
												timestamp:time
											 windowNumber:[window windowNumber]
												  context:0 eventNumber:0 clickCount:1 pressure:0];
	NSEvent *mouseUpEvent = [NSEvent mouseEventWithType:NSLeftMouseUp
											   location:where
										  modifierFlags:0
											  timestamp:time
										   windowNumber:[window windowNumber]
												context:0 eventNumber:0 clickCount:1 pressure:0];
	
	// -hitTest: returns the deepest subview under the point specified.
	// As I'm using the same point for both events, I only call - hitTest: once.
	NSView *subView = [self hitTest:[mouseUpEvent locationInWindow]];
	if (subView)
	{
		[subView mouseDown:mouseDownEvent];
		[subView mouseUp:mouseUpEvent];
	}
}

- (NSPoint)locationOfElementWithId:(NSString *)elementId
{
	[self runScript:@"GetPosition"];
	NSString *script = [NSString stringWithFormat:@"getIdPos('%@')", elementId];
	NSString *locationString = [self stringByEvaluatingJavaScriptFromString:script];
	// NSLog(@"%@ = %@", script, locationString);
	
	NSPoint where;
	
	if ([locationString length])
	{
		where = NSPointFromString(locationString);
	}
	else
	{
		where = NSMakePoint(0, 0);
	}
	
	return where;
	
}

- (void)clickOnce:(NSTimer *)timer
{
	NSMutableDictionary *userInfo = [timer userInfo];
	int times = [[userInfo valueForKey:@"times"] intValue];
	NSPoint where = NSPointFromString([userInfo valueForKey:@"where"]);
	
	if (times == 0)
	{
		[timer invalidate];
		return;
	}
	
	[self simulateMouseClick:where];
	
	[userInfo setObject:[NSNumber numberWithInt:times-1] forKey:@"times"];
}

- (BOOL)clickElementWithId:(NSString *)elementId
					repeat:(int)times
{
	NSPoint where = [self locationOfElementWithId:elementId];
	
	if (where.x == 0 && where.y == 0)
	{
		return NO;
	}
	
	// Convert the point from Javascript coordinates to NSView coordinates by changing the origin from top left to bottom left.
	where.y = [self frame].size.height - where.y;
	
	// Move the point down and to the right a bit, to make sure we're inside a button and not just on the corner.
	where.x += 20;
	where.y -= 20;
	
	[self simulateMouseClick:where];
	
	// The page seems to reload the first time we click a button, so we wait for a second.
	[NSTimer scheduledTimerWithTimeInterval:0.4
									 target:self
								   selector:@selector(clickOnce:)
								   userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInt:times-1],@"times",
											 NSStringFromPoint(where),@"where",nil]
									repeats:YES];
	
	return YES;
}

@end