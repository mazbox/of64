/**
 *  main.cpp
 *
 *  Created by Marek Bereza on 06/01/2012.
 */

#include "main.h"
#include "ofxAppMacScreenSaver.h"
#include "testApp.h"
ofxAppMacScreenSaver *ofxScreensaver_main() {
	ofxAppMacScreenSaver *screensaver = new ofxAppMacScreenSaver();
	screensaver->setApp(new testApp());
	return screensaver;
}