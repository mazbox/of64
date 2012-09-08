/**
 *  main.cpp
 *
 *  Created by Marek Bereza on 06/01/2012.
 */

#include "main.h"

#ifdef OF_SCREEN_SAVER
    #include "ofxAppMacScreenSaver.h"
#else
    #include "ofAppGlutWindow.h"
#endif
#include "testApp.h"

#ifdef OF_SCREEN_SAVER
    ofxAppMacScreenSaver *ofxScreensaver_main() {
        cout << "---------------------------------------------------" << endl;
        cout << "main.cpp :: ofxAppMacScreenSaver : creating instance" << endl;
        cout << "---------------------------------------------------" << endl;
        
        ofxAppMacScreenSaver *screensaver = new ofxAppMacScreenSaver();
        screensaver->setApp(new testApp());
        return screensaver;
    }
#else 
    //========================================================================
    int main( ){
        
        ofAppGlutWindow window;
        window.setGlutDisplayString("rgb double depth alpha samples>=4");
        ofSetupOpenGL(&window, 1024,768, OF_WINDOW);			// <-------- setup the GL context
        
        // this kicks off the running of my app
        // can be OF_WINDOW or OF_FULLSCREEN
        ofRunApp( new testApp());
        
    }
#endif