//
//  ofxScreensaverView.m
//  ofxScreensaver
//
//  Created by Marek Bereza on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ofxScreenSaver.h"
#import "Wrapper.h"


@implementation ofxScreenSaver

static BOOL gFirst = YES;

// name of your screen saver //
// more about symbol clashes. If you are making more than one screen saver //
// read this: http://cocoadevcentral.com/articles/000089.php //
static NSString* const MyModuleName = @"cc.openFrameworks.ofxScreenSaver";

//--------------------------------------------------------------
+ (BOOL) getConfigureBoolean : (NSString*)index {
	return (bool)[ [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName] boolForKey:index];
}

//--------------------------------------------------------------
+ (int) getConfigureInteger : (NSString*)index {
	return (int)[ [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName] integerForKey:index];
}

//--------------------------------------------------------------
+ (const char*) getConfigureString : (NSString*)index {
    NSString* str = (NSString*)[ [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName] stringForKey:index];
    return [str UTF8String];
}

//--------------------------------------------------------------
+ (float) getConfigureFloat : (NSString*)index {
    return (float)[ [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName] floatForKey:index];
}


//--------------------------------------------------------------
- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    
    preview = bMainFrame = bFirst = NO;     // assume failure (pessimist!)
    if ( isPreview ) {
        preview = YES;        // remember this is the preview instance
    } else if ( gFirst ) {    // if the singleton is still true
        gFirst = NO;          // clear the singleton
        bFirst = YES;
    }
    
    bClearBG = true;
    bSetup = false;
    
    
    if (self && (bFirst || preview) ) {
        
        // http://www.cocoabuilder.com/archive/cocoa/234688-nsopenglview-and-antialiasing.html
        // NSOpenGLPFASampleBuffers set to 1, and NSOpenGLPFASamples
        // set to something like 4, 8, or 16
        
		NSOpenGLPixelFormatAttribute attributes[] = { 
			NSOpenGLPFAAccelerated,
			NSOpenGLPFADoubleBuffer,
			//NSOpenGLPFAMultiScreen,
            NSOpenGLPFASampleBuffers, 1,
            NSOpenGLPFASamples, 8,
			NSOpenGLPFADepthSize, 24,
			NSOpenGLPFAAlphaSize, 8,
			NSOpenGLPFAColorSize, 24,
			NSOpenGLPFANoRecovery,
			0
		
		};  
		
		// instantiate the constants //
		ScreenSaverDefaults *defaults;
		
		defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
		
        // setup our defaults for the screen saver, first time it 
		// Register our default values
		[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @"YES", @"colorize",
                                    [NSNumber numberWithFloat:200], @"redValue",
                                    [NSNumber numberWithFloat:25], @"greenValue",
                                    [NSNumber numberWithFloat:100], @"blueValue",
                                    [NSNumber numberWithInt:100], @"thresholdValue",
                                    @"", @"userInputText",
									nil]];
		
		
		
		NSOpenGLPixelFormat *format;
		
		format = [[[NSOpenGLPixelFormat alloc] 
				   initWithAttributes:attributes] autorelease];
		
        glView = [[MyOpenGLView alloc] initWithFrame:NSZeroRect pixelFormat:format];
		
		if (!glView) {             
			NSLog( @"Couldn't initialize OpenGL view." );
			[self autorelease];
			return nil;
		} 
		
        [self addSubview:glView]; 
		[[glView openGLContext] makeCurrentContext];
        
		// enable vertical sync
		GLint i = 1;
		[[glView openGLContext] setValues:&i forParameter:NSOpenGLCPSwapInterval];
		
        if(bFirst) { 
            NSLog(@"ofxScreenSaver :: initWithFrame : bFirst, setup() = %d x %d", (int)frame.size.width, (int)frame.size.height);
            const char *s = [[[NSBundle bundleForClass:[self class]] resourcePath] UTF8String];
            init(s);
            setupOpenGL( [[[NSScreen screens] objectAtIndex:0] frame] ); 
            setup();
        }
		
        [self setAnimationTimeInterval:1/60.0];
        
        glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
        // This hint is for antialiasing
        glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
        
    }
    
    return self;
}

- (void)startAnimation {
    
    if ( [[[self window] screen] isEqual:[[NSScreen screens] objectAtIndex:0]] && !preview) {
        bMainFrame = YES;
    }
    
    
    if(preview && !bSetup) {
        
        NSBundle* saverBundle   = [NSBundle bundleForClass: [self class]];
        NSString* previewPath   = [saverBundle pathForResource: @"preview" ofType: @"png"];
        
        previewImage      = [[NSImage alloc] initWithContentsOfFile: previewPath];
        
        
        glEnable(GL_TEXTURE_2D);
        
        // Employee Texture //
        glGenTextures(1, &previewTextureID);
        glBindTexture(GL_TEXTURE_2D, previewTextureID);
        glPixelStorei(GL_UNPACK_ALIGNMENT,1);
        
        NSBitmapImageRep * bitmap = [NSBitmapImageRep imageRepWithData:[previewImage TIFFRepresentation]];
        
        GLenum	 imageFormat = GL_RGBA;
        if ([bitmap hasAlpha] == YES) {
            imageFormat = GL_RGBA;
        } else {
            imageFormat = GL_RGB;
        }
        
        glTexImage2D(GL_TEXTURE_2D, 0, imageFormat, [previewImage size].width, [previewImage size].height, 
                     0, imageFormat, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
        
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        
        glDisable(GL_TEXTURE_2D);
        
        [bitmap release];
    }
    
    
    if(!bMainFrame && !preview) {
        // black out any additional screens //
        [self lockFocus]; 
        [[NSColor blackColor] set]; 
        NSRectFill([self bounds]); 
        [self unlockFocus]; 
        
        [[self window] flushWindow];
        
        return;
    }
    
    bClearBG = true;
    bSetup = true;
    
    [super startAnimation];
}

- (void)stopAnimation {
    NSLog(@"ofxScreenSaver :: stopAnimation : ");
    exit_cb();
    gFirst      = YES;
    bClearBG    = true;
    preview     = true;
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect {
    
    [super drawRect:rect];
    
    if((bMainFrame && !preview) && bSetup) {
        [[glView openGLContext] makeCurrentContext];
        // now do OF drawing
        display();
        [[glView openGLContext] flushBuffer];
    }
    
    if(preview) {
        [[glView openGLContext] makeCurrentContext];
        
        glClearColor(0., 0., 0., 1.);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glLoadIdentity();
        
        
        glColor4f(1., 1., 1., 1.f);
        
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, previewTextureID);
        
        [self drawFSQuad];
        
        glBindTexture(GL_TEXTURE_2D, 0);
        glDisable(GL_TEXTURE_2D);
        
        [[glView openGLContext] flushBuffer];
    }
     
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


- (void)animateOneFrame {
    if(!bSetup) return;
    if(!preview && !bMainFrame) return;
	if(bFirst && !preview) idle_cb(); // update OF app //
	// Redraw
	[self setNeedsDisplay:YES];
    return;
}

- (void) drawFSQuad {
    glBegin(GL_QUADS);
        glTexCoord2f(0.0f, 0.); 
        glVertex2f(-1., 1.f);
        
        glTexCoord2f(1., 0.); 
        glVertex2f( 1., 1.);
        
        glTexCoord2f(1., 1.); 
        glVertex2f( 1., -1.);
        
        glTexCoord2f(0.0f, 1.0); 
        glVertex2f(-1, -1);
    glEnd();
}

- (void)keyDown:(NSEvent *)theEvent {
    //  handle any necessary keyDown events here and pass the rest on to the superclass
    
    // OF adds 255 to the arrow keys, so check for that here //
    if([self getKeyCodeInt:theEvent] != -1) {
        keyDown_cb( [self getKeyCodeInt:theEvent] );
    } else {
        keyDown_cb([ [theEvent charactersIgnoringModifiers] UTF8String][0]);
    }
}
- (void)keyUp:(NSEvent *)theEvent {
    //  handle any necessary keyUp events here and pass the rest on to the superclass
    if([self getKeyCodeInt:theEvent] != -1) {
        keyUp_cb( [self getKeyCodeInt:theEvent] );
    } else {
        keyUp_cb([ [theEvent charactersIgnoringModifiers] UTF8String][0]);
    }
    //[super keyUp: theEvent];
}

- (int) getKeyCodeInt : (NSEvent *)theEvent {
    switch ( [theEvent keyCode] ) {
        case 126: // up arrow //
            return  357;
            break;
        case 125: // down arrow //
            return 359;
            break;
        case 124: // right arrow //
            return 358;
            break;
        case 123: // left arrow //
            return 356;
            break;
    }
    return -1;
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow *)configureSheet {
	ScreenSaverDefaults *defaults;
	
	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
	
	if (!configSheet) {
		if (![NSBundle loadNibNamed:@"ConfigureSheet" owner:self]) {
			NSLog( @"Failed to load configure sheet." );
			NSBeep();
		}
	}
	
    [colorizeOption setState:[defaults boolForKey:@"colorize"]];
    [rSlider setFloatValue:[defaults floatForKey:@"redValue"]];
    [gSlider setFloatValue:[defaults floatForKey:@"greenValue"]];
    [bSlider setFloatValue:[defaults floatForKey:@"blueValue"]];
    
    [thresholdSlider setIntValue:(int)[defaults integerForKey:@"thresholdValue"]];
    [thresholdTextField setStringValue:[NSString stringWithFormat:@"%d", [thresholdSlider intValue]] ];
    
    [textInputField setStringValue:[defaults stringForKey:@"userInputText"]];
	
	return configSheet;
}

- (IBAction) okClick: (id)sender {
	ScreenSaverDefaults *defaults;
	
	defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
	
    
	// Update our defaults
    [defaults setBool:[colorizeOption state] forKey:@"colorize"];
    [defaults setFloat:[rSlider floatValue] forKey:@"redValue"];
    [defaults setFloat:[gSlider floatValue] forKey:@"greenValue"];
    [defaults setFloat:[bSlider floatValue] forKey:@"blueValue"];
    
    [defaults setInteger:[thresholdSlider intValue] forKey:@"thresholdValue"];
    // update the text field //
    [thresholdTextField setStringValue:[NSString stringWithFormat:@"%d", [thresholdSlider intValue]] ];
    
    [defaults setObject:[textInputField stringValue] forKey:@"userInputText"];
	
    NSLog(@"ofxScreenSaver :: calling okClick : \n");
    
	// Save the settings to disk
	[defaults synchronize];
    
    bClearBG = true;
	
	// Close the sheet
	[[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction)cancelClick:(id)sender {
	[[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction)thresholdSliderChange:(id)sender {
    [thresholdTextField setStringValue:[NSString stringWithFormat:@"%d", [thresholdSlider intValue]] ];
}

- (IBAction)redSliderChange:(id)sender {
    [[ScreenSaverDefaults defaultsForModuleWithName:MyModuleName] setFloat:[rSlider floatValue] forKey:@"redValue"];
}

- (IBAction)greenSliderChange:(id)sender {
    [[ScreenSaverDefaults defaultsForModuleWithName:MyModuleName] setFloat:[gSlider floatValue] forKey:@"greenValue"];
}

- (IBAction)blueSliderChange:(id)sender {
    [[ScreenSaverDefaults defaultsForModuleWithName:MyModuleName] setFloat:[bSlider floatValue] forKey:@"blueValue"];
}


- (void)dealloc
{
    NSLog(@"ofxScreenSaver :: dealloc : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    [previewImage release];
    if(bFirst) exit_cb();
	[glView removeFromSuperview];
	[glView release];
	[super dealloc];
}

@end


