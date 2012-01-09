//
//  ofxScreensaverView.h
//  ofxScreensaver
//
//  Created by Marek Bereza on 06/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import "MyOpenGLView.h"
@interface ofxScreensaverView : ScreenSaverView
{
	MyOpenGLView *glView;
}
@end
