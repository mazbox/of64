#pragma once

#include "ofMain.h"
#include "ofxQTKitVideoGrabber.h"
#include "ofxOpenCv.h"

#ifdef OF_APPLICATION
    // include control panels, etc. for application only //
#endif

#ifdef OF_SCREEN_SAVER
    // includes for screen saver only 
#endif

class testApp : public ofBaseApp {

public:
    
    void setup();
    void update();
    void draw();
    
    void keyPressed( int key );
    void keyReleased( int key );
    
    void exit();
    
#ifdef OF_APPLICATION
    // only include these functions for application, since mouse movement awakes screen saver //
    void mouseMoved(int x, int y );
    void mouseDragged(int x, int y, int button);
    void mousePressed(int x, int y, int button);
    void mouseReleased(int x, int y, int button);
#endif
    
    ofxQTKitVideoGrabber vidGrabber;
    ofxCvColorImage colorImg;
	ofxCvGrayscaleImage greyImg;
    
    ofVec2f pos;
    
    string userInputString;
    
};




