/**
 *  testApp.cpp
 *
 *  Created by Marek Bereza on 09/01/2012.
 */

#include "testApp.h"
ofVec2f pos;
void testApp::setup() {
	pos = ofVec2f(500, 500);

	vidGrabber.initGrabber(640, 480);
	vidGrabber.setUseTexture(true);
	colorImg.allocate(640, 480);
	greyImg.allocate(640, 480);
}

void testApp::update() {
	vidGrabber.update();
	if(vidGrabber.isFrameNew()) {
		colorImg.setFromPixels(vidGrabber.getPixels(), 640, 480);
		greyImg = colorImg;
		greyImg.threshold(100);
	}
	pos = ofVec2f(500, 500) + ofVec2f(sin(ofGetElapsedTimef())*500, 0);
}

void testApp::draw() {
	ofBackground(0, 0, 0);


	ofSetColor(ofRandom(0, 255), ofRandom(0, 255), ofRandom(0, 255));
	ofRect(pos.x, pos.y, 100, 100);
	ofSetHexColor(0xFFFFFF);
		vidGrabber.draw(0, 0);

	greyImg.draw(640, 0);
}