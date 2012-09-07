
#include "testApp.h"
#ifdef OF_SCREEN_SAVER
    #include "ofxScreenSaver.h"
#endif

//--------------------------------------------------------------
void testApp::setup() {
    ofSetFrameRate(60);
    ofSetVerticalSync(true);
    #ifdef OF_APPLICATION
    // if you are making an application, this emulates the screen saver, since screen savers launch in full screen //
    // but if your app crashes, it is hard to get out of full screen //
    // ofSetFullscreen(true);
    #endif
    ofBackground(0,0,0);
    
    pos = ofVec2f(500, 500);
    
    vidGrabber.initGrabber(640, 480);
	vidGrabber.setUseTexture(true);
    
    colorImg.allocate(640, 480);
	greyImg.allocate(640, 480);
    
    cout << "---------------------------------------------------" << endl;
    cout << "testApp :: setup : calling setup " << ofGetWidth() << " x " << ofGetHeight() << endl;
    cout << "---------------------------------------------------" << endl;
    
}


//--------------------------------------------------------------
void testApp::update() {
    
    #ifdef OF_SCREEN_SAVER
        int threshold = [ofxScreenSaver getConfigureInteger:@"thresholdValue"];
    #else
        int threshold = 100;
    #endif
    
    
    vidGrabber.update();
	if(vidGrabber.isFrameNew()) {
		colorImg.setFromPixels(vidGrabber.getPixels(), 640, 480);
		greyImg = colorImg;
		greyImg.threshold(threshold);
	}
    
    pos = ofVec2f((ofGetWidth()-100)*.5, 500) + ofVec2f(sin(ofGetElapsedTimef())*((ofGetWidth()-100)*.5), 0);
}

//--------------------------------------------------------------
void testApp::draw() {
    ofSetColor(ofRandom(0, 255), ofRandom(0, 255), ofRandom(0, 255));
	ofRect(pos.x, pos.y, 100, 100);
	
    
#ifdef OF_SCREEN_SAVER
    float red   = [ofxScreenSaver getConfigureFloat:@"redValue"];
    float green = [ofxScreenSaver getConfigureFloat:@"greenValue"];
    float blue  = [ofxScreenSaver getConfigureFloat:@"blueValue"];
#else 
    float red   = ofRandom(0, 255);
    float green = ofRandom(0, 255);
    float blue  = ofRandom(0, 255);
#endif
    
    ofSetHexColor(0xFFFFFF);
    vidGrabber.draw(0, 0);
    ofSetColor(red, green, blue);
    greyImg.draw(640, 0);
    
#ifdef OF_SCREEN_SAVER
    ofSetColor(255);
    userInputString = [ofxScreenSaver getConfigureString:@"userInputText"];
    ofDrawBitmapString(userInputString, 20, 20);
#endif
    
}

//--------------------------------------------------------------
void testApp::keyPressed( int key ) {
#ifdef OF_APPLICATION
    if(key == 'f') {
        ofToggleFullscreen();
    }
#endif
}

//--------------------------------------------------------------
void testApp::keyReleased( int key ) {
    
}

#ifdef OF_APPLICATION
//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y ){
    
}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){
    
}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){
	
}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){
    
}
#endif

//--------------------------------------------------------------
void testApp::exit() {
    cout << "testApp :: exit : " << endl;
    vidGrabber.close();
}










