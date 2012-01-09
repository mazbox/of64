//
//  ofxScreensaverView.m
//  ofxScreensaver
//
//  Created by Marek Bereza on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ofxScreensaverView.h"
#import "Wrapper.h"

@implementation ofxScreensaverView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
		NSOpenGLPixelFormatAttribute attributes[] = { 
		/*	NSOpenGLPFAAccelerated,
			NSOpenGLPFADepthSize, 16,
			NSOpenGLPFAMinimumPolicy,
			NSOpenGLPFAClosestPolicy,
			0
		 
		 
		 */
		
			NSOpenGLPFAAccelerated,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAMultiScreen,
			NSOpenGLPFADepthSize, 24,
			NSOpenGLPFAAlphaSize, 8,
			NSOpenGLPFAColorSize, 32,
			NSOpenGLPFANoRecovery,
			0
		
		};  
		
		
		
		NSOpenGLPixelFormat *format;
		
		format = [[[NSOpenGLPixelFormat alloc] 
				   initWithAttributes:attributes] autorelease];
		
		glView = [[MyOpenGLView alloc] initWithFrame:NSZeroRect 
										 pixelFormat:format];
		
		if (!glView)
		{             
			NSLog( @"Couldn't initialize OpenGL view." );
			[self autorelease];
			return nil;
		} 
		unsigned char *s = [[[NSBundle bundleForClass:[self class]] resourcePath] UTF8String];
		init(s);
		[self addSubview:glView]; 
		[[glView openGLContext] makeCurrentContext];
		
		// enable vertical sync
		GLint i = 1;
		[[glView openGLContext] setValues:&i forParameter:NSOpenGLCPSwapInterval];
		
		// do setupping
		setup();
		
        [self setAnimationTimeInterval:1/60.0];
    }
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];

	[[glView openGLContext] makeCurrentContext];
	
	// now do drawing
	display();
	
	[[glView openGLContext] flushBuffer];
//	glFlush(); 
}


- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	[glView setFrameSize:newSize]; 
	
	[[glView openGLContext] makeCurrentContext];
	
	// call windowResized
	resize_cb(newSize.width, newSize.height);
	[[glView openGLContext] update];
}


- (void)animateOneFrame
{
	
	idle_cb();
	// Redraw
	[self setNeedsDisplay:YES];
	
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

- (void)dealloc
{
	[glView removeFromSuperview];
	[glView release];
	[super dealloc];
}

@end


