/**
 *  Wrapper.cpp
 *
 *  Created by Marek Bereza on 09/01/2012.
 */

#include "Wrapper.h"
#include "ofxAppMacScreenSaver.h"
#include "main.h"
#include <string>
#import <AppKit/AppKit.h>
#include <sys/time.h>

using namespace std;



ofxAppMacScreenSaver *screensaver = NULL;
string dataPath = "";

void init(const char *resPath) {
	screensaver = ofxScreensaver_main();
	dataPath = resPath;
}
void setupOpenGL(NSRect a_frame) {
    NSLog(@"Wrapper :: setupOpenGL : a_frame");
    screensaver->setupOpenGL(a_frame.size.width, a_frame.size.height, 0, dataPath);
}

void setup() {
    screensaver->setup();
    screensaver->initializeWindow();
}

void display() {
    
    //struct timeval now;
    //gettimeofday( &now, NULL );
    //return now.tv_usec/1000 + now.tv_sec*1000;
    //int ctime = (int)now.tv_usec/1000 + now.tv_sec*1000;
    
    //NSLog(@"----> Wrapper :: display : %d", ctime);
	screensaver->display();
}
void resize_cb(int w, int h) {
	screensaver->resize_cb(w, h);
}
void idle_cb() {
	screensaver->idle_cb();
}
void exit_cb() {
    if(screensaver != NULL) {
        screensaver->exit_cb();
        delete screensaver;
        screensaver = NULL;
    }
}
void keyDown_cb( int key ) {
    screensaver->keyPressed( key );
}
void keyUp_cb( int key ) {
    screensaver->keyReleased( key );
}












