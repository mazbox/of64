//
//  ofxScreensaverView.h
//  ofxScreensaver
//
//  Created by Marek Bereza on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  

#import <ScreenSaver/ScreenSaver.h>
#import "MyOpenGLView.h"

@interface ofxScreenSaver : ScreenSaverView {
	MyOpenGLView *glView;
	// add a configure sheet //
	IBOutlet id configSheet;
    
    IBOutlet id colorizeOption;
    IBOutlet id rSlider;
    IBOutlet id gSlider;
    IBOutlet id bSlider;
    
    IBOutlet id thresholdSlider;
    IBOutlet id thresholdTextField;
    
    IBOutlet id textInputField;
    
	
    BOOL preview;
    BOOL bFirst;
    BOOL bMainFrame;
    BOOL bSetup;
    
    BOOL bGLViewSetup;
    
    BOOL bClearBG;
    GLuint previewTextureID;
    NSImage* previewImage;
    
}

- (void) drawFSQuad;
- (int) getKeyCodeInt : (NSEvent *)theEvent;

// Configure Options //
+ (BOOL) getConfigureBoolean : (NSString*)index;
+ (int) getConfigureInteger : (NSString*)index;
+ (const char*) getConfigureString : (NSString*)index;
+ (float) getConfigureFloat : (NSString*)index;

// our slider changes //
- (IBAction)thresholdSliderChange:(id)sender;
- (IBAction)redSliderChange:(id)sender;
- (IBAction)greenSliderChange:(id)sender;
- (IBAction)blueSliderChange:(id)sender;


@end
