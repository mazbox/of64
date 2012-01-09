/*
 * ofxQTKitVideoGrabber.cpp
 *
 * Copyright 2010 (c) James George, http://www.jamesgeorge.org
 * in collaboration with FlightPhase http://www.flightphase.com
 *
 * Video & Audio sync'd recording + named device id's 
 * added by gameover [matt gingold] (c) 2011 http://gingold.com.au
 * with the support of hydra poesis http://hydrapoesis.net
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * ----------------------
 *
 * ofxQTKitVideoGrabber works exactly the same as the standard ofMovieGrabber
 * but uses the QTKit Objective-C Libraries to drive the video display.
 * These libraries are naturally GPU enabled, multi-threaded, as well
 * as supporting more Quicktime capture codecs such as HDV.
 *
 * You will need to add the QTKit.framework and CoreVide.framework
 * to the openFrameworks Xcode project
 *
 * Requires Mac OS 10.5 or greater
 */

#pragma once 

#include "ofMain.h"

//using this #ifdef lets this .h file be included in cpp files without throwing errors
//but when included in .m files it works correctly.  another useful trick for mixing oF/ObjC
#ifdef __OBJC__
@class QTKitVideoGrabber;
#endif

class ofxQTKitVideoGrabber : public ofBaseVideoGrabber
{
  public:
	ofxQTKitVideoGrabber();
	~ofxQTKitVideoGrabber();
   
	bool			initGrabber(int w, int h);
	bool			isFrameNew();
	void			update();
    void 			draw(float x, float y, float w, float h);
	void 			draw(float x, float y);
    float 			getWidth();
	float 			getHeight();
    unsigned char*  getPixels();
	ofPixelsRef		getPixelsRef();
	ofTexture&		getTextureReference();
	void 			setVerbose(bool bTalkToMe);
	void 			setUseTexture(bool bUse);
    
    // [added by gameover]
	void			initRecording();
	void			initGrabberWithoutPreview();	// used to init with no preview/textures etc
	vector<string>&	listVideoCodecs();
	vector<string>&	listAudioCodecs();
	void			setVideoCodec(string videoCodecIDString);
	void			setAudioCodec(string audioCodecIDString);
    void            setUseAudio(bool bUseAudio);
	void			startRecording(string filePath);
	void			stopRecording();
	bool			isRecording();
	bool			isReady();
	
    void            listDevices(); // would be better if this returned a vector of devices too, but requires updating base class
	vector<string>&	listAudioDevices();
	vector<string>&	listVideoDevices();
    
	void			close();
    
	void			setDeviceID(int videoDeviceID);
	void			setDeviceID(string videoDeviceIDString);
	int				getDeviceID();
    
	void			setVideoDeviceID(int videoDeviceID);
	void			setVideoDeviceID(string videoDeviceIDString);
	int				getVideoDeviceID();
    
	void			setAudioDeviceID(int audioDeviceID);
	void			setAudioDeviceID(string audioDeviceIDString);
	int				getAudioDeviceID();
    
	void			setDesiredFrameRate(int framerate){ ofLog(OF_LOG_WARNING, "ofxQTKitVideoGrabber -- Cannot specify framerate.");  };
	
    void			videoSettings();
	void            audioSettings();
    
  protected:

    bool confirmInit();
    
    vector<string>	videoDeviceVec;
	vector<string>	audioDeviceVec;
    vector<string>	videoCodecsVec;
	vector<string>	audioCodecsVec;
    
    int	videoDeviceID;
	int	audioDeviceID;
    string	videoCodecIDString;
	string	audioCodecIDString;
    
	bool isInited;
	bool bUseTexture;
    bool bUseAudio;
    
	#ifdef __OBJC__
	QTKitVideoGrabber* grabber; //only obj-c needs to know the type of this protected var
	#else
	void* grabber;
	#endif
};

