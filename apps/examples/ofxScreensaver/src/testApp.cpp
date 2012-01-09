/**
 *  testApp.cpp
 *
 *  Created by Marek Bereza on 09/01/2012.
 */

#include "testApp.h"
ofVec2f pos;
void testApp::setup() {
	pos = ofVec2f(500, 500);
}

void testApp::update() {
	pos = ofVec2f(500, 500) + ofVec2f(sin(ofGetElapsedTimef())*500, 0);
}

void testApp::draw() {
	ofBackground(0, 0, 0);
	ofSetColor(ofRandom(0, 255), ofRandom(0, 255), ofRandom(0, 255));
	ofRect(pos.x, pos.y, 100, 100);
}