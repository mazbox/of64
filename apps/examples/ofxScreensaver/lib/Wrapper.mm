/**
 *  Wrapper.cpp
 *
 *  Created by Marek Bereza on 09/01/2012.
 */

#include "Wrapper.h"
#include "ofxAppMacScreenSaver.h"
#include "main.h"

ofxAppMacScreenSaver *screensaver;

void init() {
	screensaver = ofxScreensaver_main();
}
void setup() {


	screensaver->setupOpenGL(0, 0, 0);//, <#int h#>, <#int screenMode#>)
	screensaver->initializeWindow();
	
}
void display() {
	screensaver->display();
}
void resize_cb(int w, int h) {
	screensaver->resize_cb(w, h);
}
void idle_cb() {
	screensaver->idle_cb();
}