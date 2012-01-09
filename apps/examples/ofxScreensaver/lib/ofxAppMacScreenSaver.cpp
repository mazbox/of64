/**
 *  ofxAppMacScreenSaver.cpp
 *
 *  Created by Marek Bereza on 06/01/2012.
 */

#include "ofxAppMacScreenSaver.h"
#include "ofBaseApp.h"
#include "ofEvents.h"
#include "ofUtils.h"
#include "ofGraphics.h"
#include "ofAppRunner.h"
#include "ofConstants.h"

#include "ofConstants.h"
#include "ofEvents.h"
#include "ofTypes.h"
#ifdef TARGET_OSX
//#include "../../../libs/glut/lib/osx/GLUT.framework/Versions/A/Headers/glut.h"
#else
#error Only available for mac (now)
#endif


// glut works with static callbacks UGH, so we need static variables here:

static int			windowMode;
static bool			bNewScreenMode;
static float		timeNow, timeThen, fps;
static int			nFramesForFPS;
static int			nFrameCount;
static int			buttonInUse;
static bool			bEnableSetupScreen;


static bool			bFrameRateSet;
static int 			millisForFrame;
static int 			prevMillis;
static int 			diffMillis;

static float 		frameRate;

static double		lastFrameTime;

static int			requestedWidth;
static int			requestedHeight;
static int 			nonFullScreenX;
static int 			nonFullScreenY;
static int			windowW;
static int			windowH;
static int          nFramesSinceWindowResized;
ofBaseApp *  ofAppPtr;





//----------------------------------------------------------
ofxAppMacScreenSaver::ofxAppMacScreenSaver(){
	timeNow				= 0;
	timeThen			= 0;
	fps					= 60.0; //give a realistic starting value - win32 issues
	frameRate			= 60.0;
	windowMode			= OF_WINDOW;
	bNewScreenMode		= true;
	nFramesForFPS		= 0;
	nFramesSinceWindowResized = 0;
	nFrameCount			= 0;
	buttonInUse			= 0;
	bEnableSetupScreen	= true;
	bFrameRateSet		= false;
	millisForFrame		= 0;
	prevMillis			= 0;
	diffMillis			= 0;
	requestedWidth		= 0;
	requestedHeight		= 0;
	nonFullScreenX		= -1;
	nonFullScreenY		= -1;
	lastFrameTime		= 0.0;
	
}

#include "ofAppBaseWindow.h"
class ofxScreensaverWindow: public ofAppBaseWindow {
public:
	int getWidth() { return 1440; }
	int getHeight() { return 900; }
};
//------------------------------------------------------------
void ofxAppMacScreenSaver::setupOpenGL(int w, int h, int screenMode){
	static ofPtr<ofAppBaseWindow> window;	
	window = ofPtr<ofAppBaseWindow>(new ofxScreensaverWindow());
	ofSetupOpenGL(window, w, h, screenMode);
	int argc = 1;
	char *argv = (char*)"openframeworks";
	char **vptr = &argv;
	//glutInit(&argc, vptr);
	
	
	windowMode = screenMode;
	bNewScreenMode = true;
	ofSetCurrentRenderer(ofPtr<ofBaseRenderer>(new ofGLRenderer(false)));
	ofNotifySetup();
	ofAppPtr->setup();	
	//windowW = glutGet(GLUT_WINDOW_WIDTH);
	//windowH = glutGet(GLUT_WINDOW_HEIGHT);
}

//------------------------------------------------------------
void ofxAppMacScreenSaver::initializeWindow(){
	
    nFramesSinceWindowResized = 0;
}

//------------------------------------------------------------
void ofxAppMacScreenSaver::runAppViaInfiniteLoop(ofBaseApp * appPtr){
	ofAppPtr = appPtr;
	
	ofNotifySetup();
	ofNotifyUpdate();
	
	//glutMainLoop();
}



//------------------------------------------------------------
float ofxAppMacScreenSaver::getFrameRate(){
	return frameRate;
}

//------------------------------------------------------------
double ofxAppMacScreenSaver::getLastFrameTime(){
	return lastFrameTime;
}

//------------------------------------------------------------
int ofxAppMacScreenSaver::getFrameNum(){
	return nFrameCount;
}
/*
//------------------------------------------------------------
ofPoint ofxAppMacScreenSaver::getWindowSize(){
	return ofPoint(windowW, windowH,0);
}

//------------------------------------------------------------
ofPoint ofxAppMacScreenSaver::getScreenSize(){
	int width = 0;//glutGet(GLUT_SCREEN_WIDTH);
	int height = 0;//glutGet(GLUT_SCREEN_HEIGHT);
	return ofPoint(width, height,0);
}*/

//------------------------------------------------------------
int ofxAppMacScreenSaver::getWidth(){
	return windowW;
}

//------------------------------------------------------------
int ofxAppMacScreenSaver::getHeight(){
	return windowH;
}

//------------------------------------------------------------
void ofxAppMacScreenSaver::setFrameRate(float targetRate){
	// given this FPS, what is the amount of millis per frame
	// that should elapse?
	
	// --- > f / s
	
	if (targetRate == 0){
		bFrameRateSet = false;
		return;
	}
	
	bFrameRateSet 			= true;
	float durationOfFrame 	= 1.0f / (float)targetRate;
	millisForFrame 			= (int)(1000.0f * durationOfFrame);
	
	frameRate				= targetRate;
	
}

//------------------------------------------------------------
int ofxAppMacScreenSaver::getWindowMode(){
	return windowMode;
}

//------------------------------------------------------------
void ofxAppMacScreenSaver::enableSetupScreen(){
	bEnableSetupScreen = true;
}

//------------------------------------------------------------
void ofxAppMacScreenSaver::disableSetupScreen(){
	bEnableSetupScreen = false;
}


//------------------------------------------------------------
void ofxAppMacScreenSaver::display(void){
	
	//--------------------------------
	// when I had "glutFullScreen()"
	// in the initOpenGl, I was gettings a "heap" allocation error
	// when debugging via visual studio.  putting it here, changes that.
	// maybe it's voodoo, or I am getting rid of the problem
	// by removing something unrelated, but everything seems
	// to work if I put fullscreen on the first frame of display.
	
	///// MAREK HERE	
	// set viewport, clear the screen
	////ofViewport(0, 0, glutGet(GLUT_WINDOW_WIDTH), glutGet(GLUT_WINDOW_HEIGHT));		// used to be glViewport( 0, 0, width, height );
	float * bgPtr = ofBgColorPtr();
	bool bClearAuto = ofbClearBg();
	
    // to do non auto clear on PC for now - we do something like "single" buffering --
    // it's not that pretty but it work for the most part
	

	
	if ( bClearAuto == true || nFrameCount < 3){
		ofClear(bgPtr[0]*255,bgPtr[1]*255,bgPtr[2]*255, bgPtr[3]*255);
	}
	
	if( bEnableSetupScreen )ofSetupScreen();
	
	ofNotifyDraw();
	ofAppPtr->draw();

	if (bClearAuto == false){
		// in accum mode resizing a window is BAD, so we clear on resize events.
		if (nFramesSinceWindowResized < 3){
			ofClear(bgPtr[0]*255,bgPtr[1]*255,bgPtr[2]*255, bgPtr[3]*255);
		}
	}
	
	//// MAREK HERE
	////glutSwapBuffers();

	
    nFramesSinceWindowResized++;
	
	//fps calculation moved to idle_cb as we were having fps speedups when heavy drawing was occuring
	//wasn't reflecting on the actual app fps which was in reality slower.
	//could be caused by some sort of deferred drawing?
	
	nFrameCount++;		// increase the overall frame count
	
	//setFrameNum(nFrameCount); // get this info to ofUtils for people to access
	
}


//------------------------------------------------------------
void ofxAppMacScreenSaver::idle_cb(void) {
	ofAppPtr->update();
	/*
	//	thanks to jorge for the fix:
	//	http://www.openframeworks.cc/forum/viewtopic.php?t=515&highlight=frame+rate
	
	if (nFrameCount != 0 && bFrameRateSet == true){
		diffMillis = ofGetElapsedTimeMillis() - prevMillis;
		if (diffMillis > millisForFrame){
			; // we do nothing, we are already slower than target frame
		} else {
			int waitMillis = millisForFrame - diffMillis;
			usleep(waitMillis * 1000);   //mac sleep in microseconds - cooler :)
		}
	}
	prevMillis = ofGetElapsedTimeMillis(); // you have to measure here
	
    // -------------- fps calculation:
	// theo - now moved from display to idle_cb
	// discuss here: http://github.com/openframeworks/openFrameworks/issues/labels/0062#issue/187
	//
	//
	// theo - please don't mess with this without letting me know.
	// there was some very strange issues with doing ( timeNow-timeThen ) producing different values to: double diff = timeNow-timeThen;
	// http://www.openframeworks.cc/forum/viewtopic.php?f=7&t=1892&p=11166#p11166
	
	timeNow = ofGetElapsedTimef();
	double diff = timeNow-timeThen;
	if( diff  > 0.00001 ){
		fps			= 1.0 / diff;
		frameRate	*= 0.9f;
		frameRate	+= 0.1f*fps;
	}
	lastFrameTime	= diff;
	timeThen		= timeNow;
  	// --------------
	
	ofNotifyUpdate();
	//// MAREK HERE
	////glutPostRedisplay();
	 */
}

//------------------------------------------------------------
void ofxAppMacScreenSaver::resize_cb(int w, int h) {
	windowW = w;
	windowH = h;
	
	ofNotifyWindowResized(w, h);
	
	nFramesSinceWindowResized = 0;
}


void ofxAppMacScreenSaver::setApp(ofBaseApp *app) {
	ofAppPtr = app;
}