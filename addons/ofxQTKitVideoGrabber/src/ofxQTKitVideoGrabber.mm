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

#include "ofxQTKitVideoGrabber.h"
#import <QTKit/QTKit.h>
#import <QuickTime/QuickTime.h>

static inline void argb_to_rgb(unsigned char* src, unsigned char* dst, int numPix)
{
	for(int i = 0; i < numPix; i++){
		memcpy(dst, src+1, 3);
		src+=4;
		dst+=3;
	}	
}

@interface QTKitVideoGrabber : QTCaptureVideoPreviewOutput
{
    QTCaptureSession *session;
	QTCaptureDeviceInput *videoDeviceInput;
	QTCaptureDeviceInput *audioDeviceInput;
	QTCaptureDevice* selectedVideoDevice;
	QTCaptureDevice* selectedAudioDevice;
    QTCaptureMovieFileOutput *captureMovieFileOutput;
	NSInteger width, height;
	NSInteger videoDeviceID, audioDeviceID;
	
	CVImageBufferRef cvFrame;
	ofTexture* texture;
	ofPixels* pixels;	

    BOOL hasNewFrame;
	BOOL isRunning;
	BOOL isFrameNew;
    BOOL isRecording;
	BOOL isRecordReady;
    BOOL verbose;
	BOOL useTexture;
    BOOL useAudio;

}

@property(nonatomic, readonly) NSInteger height;
@property(nonatomic, readonly) NSInteger width;
@property(nonatomic, readwrite) NSInteger videoDeviceID;
@property(nonatomic, readwrite) NSInteger audioDeviceID;
@property(retain) QTCaptureSession* session;
@property(nonatomic, retain) QTCaptureDeviceInput* videoDeviceInput;
@property(nonatomic, retain) QTCaptureDeviceInput* audioDeviceInput;
@property(nonatomic, retain) QTCaptureMovieFileOutput *captureMovieFileOutput;
@property(nonatomic, readonly) BOOL isRunning;
@property(readonly) ofPixels* pixels;
@property(readonly) ofTexture* texture;
@property(readonly) BOOL isFrameNew;
@property(readonly) BOOL isRecording;
@property(readonly) BOOL isRecordReady;
@property(nonatomic, readwrite) BOOL verbose;
@property(nonatomic, readwrite) BOOL useTexture;
@property(nonatomic, readwrite) BOOL useAudio;

+ (NSArray*) listDevices;
+ (NSArray*) listAudioDevices;

- (id) initWithWidth:(NSInteger)width 
			  height:(NSInteger)height 
		 videodevice:(NSInteger)videoDeviceID
		 audiodevice:(NSInteger)audioDeviceID
		usingTexture:(BOOL)_useTexture
		  usingAudio:(BOOL)_useAudio;

- (id) initWithoutPreview:(NSInteger)_videoDeviceID 
			  audiodevice:(NSInteger)_audioDeviceID 
			   usingAudio:(BOOL)_useAudio;

- (void) outputVideoFrame:(CVImageBufferRef)videoFrame 
		 withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
		   fromConnection:(QTCaptureConnection *)connection;

- (bool) setSelectedVideoDevice:(QTCaptureDevice *)selectedVideoDevice;
- (bool) setSelectedAudioDevice:(QTCaptureDevice *)selectedAudioDevice;

- (void) setVideoDeviceID:(NSInteger)_videoDeviceID;
- (void) setAudioDeviceID:(NSInteger)_audioDeviceID;

- (void) initRecording:(NSString*)_selectedVideoCodec audioCodec:(NSString*)_selectedAudioCodec;
- (void) setVideoCodec:(NSString*)_selectedVideoCodec;
- (void) setAudioCodec:(NSString*)_selectedAudioCodec;
- (void) startRecording:(NSString*)filePath;
- (void) stopRecording;

+ (NSArray*) listVideoCodecs;
+ (NSArray*) listAudioCodecs;

+ (void) enumerateArray:(NSArray*)someArray;
+ (int)	 getIndexofStringInArray:(NSArray*)someArray stringToFind:(NSString*)someStringDescription;

- (void) videoSettings;
- (void) audioSettings;

- (void) startSession;
- (void) update;
- (void) stop;

@end

@implementation QTKitVideoGrabber
@synthesize width, height;
@synthesize session;
@synthesize videoDeviceID;
@synthesize audioDeviceID;
@synthesize videoDeviceInput;
@synthesize audioDeviceInput;
@synthesize captureMovieFileOutput;
@synthesize pixels;
@synthesize texture;
@synthesize isFrameNew;
@synthesize isRecording;
@synthesize isRecordReady;
@synthesize verbose;
@synthesize useTexture;
@synthesize useAudio;

+ (void) enumerateArray:(NSArray*)someArray
{
	NSInteger count = 0;
	for (id object in someArray) 
	{
		NSLog(@"%d - %@", count, [object description]);
		count++;
	}
	NSLog(@"\n");
}

+ (int) getIndexofStringInArray:(NSArray*)someArray stringToFind:(NSString*)someStringDescription
{
	NSInteger count = 0;
	NSInteger index = -1;
	
	for (id object in someArray) 
	{
		if ([[object description] isEqualToString:someStringDescription]) {
			index = count;
			break;
		} else count++;
	}
	
	return index;
}

+ (NSArray*) listDevices
{
	NSArray* videoDevices = [[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo] 
							 arrayByAddingObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
	
	NSLog(@"ofxQTKitVideoGrabber listing video devices");
	[self enumerateArray:videoDevices];
	
	return videoDevices;
	
}

+ (NSArray*) listAudioDevices
{
	NSArray* audioDevices = [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeSound];
	
	NSLog(@"ofxQTKitVideoGrabber listing audio devices");
	[self enumerateArray:audioDevices];
	
	return audioDevices;
}

- (id) initWithWidth:(NSInteger)_width height:(NSInteger)_height videodevice:(NSInteger)_videoDeviceID audiodevice:(NSInteger)_audioDeviceID usingTexture:(BOOL)_useTexture usingAudio:(BOOL)_useAudio
{
	if((self = [super init])){
		//configure self
		width = _width;
		height = _height;
		
		//instance variables
		cvFrame = NULL;
		hasNewFrame = NO;
		texture = NULL;
		self.useTexture = _useTexture;
		self.useAudio = _useAudio;
		isRecordReady = NO;
		isRecording = NO;
		
		[self setPixelBufferAttributes: [NSDictionary dictionaryWithObjectsAndKeys: 
										 [NSNumber numberWithInt: kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,
										 [NSNumber numberWithInt:width], kCVPixelBufferWidthKey, 
										 [NSNumber numberWithInt:height], kCVPixelBufferHeightKey, 
										 [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
										 nil]];	
        
		//pixels = (unsigned char*)calloc(sizeof(char), _width*_height*3);
        pixels = new ofPixels();
        pixels->allocate(_width, _height, OF_IMAGE_COLOR);
		
		//init the session
		self.session = [[[QTCaptureSession alloc] init] autorelease];
		
		NSError* error;
		bool success = [self.session addOutput:self error:&error];
		if( !success ){
			ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Error creating capture session");
			return nil;
		}
		
		videoDeviceID = -1;		
		[self setVideoDeviceID:_videoDeviceID];
		
		// if we're using audio add an audio device
		if (self.useAudio) {
			audioDeviceID = -1;
			[self setAudioDeviceID:_audioDeviceID];
		}
        
		// give us some info about the 'native format' of our device/s
		NSEnumerator *videoConnectionEnumerator = [[videoDeviceInput connections] objectEnumerator];
		QTCaptureConnection *videoConnection;
		
		while ((videoConnection = [videoConnectionEnumerator nextObject])) {
			NSLog(@"Video Input Format: %@\n", [[videoConnection formatDescription] localizedFormatSummary]);
		}
        
		NSEnumerator *audioConnectionEnumerator = [[audioDeviceInput connections] objectEnumerator];
		QTCaptureConnection *audioConnection;
		while ((audioConnection = [audioConnectionEnumerator nextObject])) {
			NSLog(@"Audio Input Format: %@\n", [[audioConnection formatDescription] localizedFormatSummary]);
		}   
		
		[self startSession];
	}
	return self;
}

- (id) initWithoutPreview:(NSInteger)_videoDeviceID audiodevice:(NSInteger)_audioDeviceID usingAudio:(BOOL)_useAudio
{
	if((self = [super init])){
		//configure self
		width = 0;
		height = 0;
		
		//instance variables
		cvFrame = NULL;
		hasNewFrame = NO;
		texture = NULL;
		self.useTexture = NO;
		self.useAudio = _useAudio;
		isRecordReady = NO;
		isRecording = NO;
		
		//init the session
		self.session = [[[QTCaptureSession alloc] init] autorelease];
		
		NSError* error;
		bool success = [self.session addOutput:self error:&error];
		if( !success ){
			ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Error creating capture session");
			return nil;
		}
		
		videoDeviceID = -1;		
		[self setVideoDeviceID:_videoDeviceID];
		
		// if we're using audio add an audio device										[added by gameover]
		if (self.useAudio) {
			audioDeviceID = -1;
			[self setAudioDeviceID:_audioDeviceID];
		}
		
		// give us some info about the 'native format' of our device/s					[added by gameover]
		NSEnumerator *videoConnectionEnumerator = [[videoDeviceInput connections] objectEnumerator];
		QTCaptureConnection *videoConnection;
		
		while ((videoConnection = [videoConnectionEnumerator nextObject])) {
			NSLog(@"Video Input Format: %@\n", [[videoConnection formatDescription] localizedFormatSummary]);
		}
		
		NSEnumerator *audioConnectionEnumerator = [[audioDeviceInput connections] objectEnumerator];
		QTCaptureConnection *audioConnection;
		while ((audioConnection = [audioConnectionEnumerator nextObject])) {
			NSLog(@"Audio Input Format: %@\n", [[audioConnection formatDescription] localizedFormatSummary]);
		}   
		
		[self startSession];
	}
	return self;
}

- (void) startSession
{
	//start the session
	NSLog(@"starting video session");
	[session startRunning];
	
}

- (void) setVideoDeviceID:(NSInteger)_videoDeviceID
{	
	if(videoDeviceID != _videoDeviceID){
		
		//get video device
		NSArray* videoDevices = [[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo] 
								 arrayByAddingObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
		
		ofLog(OF_LOG_VERBOSE, "ofxQTKitVideoGrabber -- Video Device List:  %s", [[videoDevices description] cString]);
		
		// Try to open the new device
		if(_videoDeviceID >= videoDevices.count){
			ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Error video device ID out of range");
			return;
		}		
		selectedVideoDevice = [videoDevices objectAtIndex:_videoDeviceID];
		if([self setSelectedVideoDevice:selectedVideoDevice]){
			videoDeviceID = _videoDeviceID;
		}
	}
}

- (void) setAudioDeviceID:(NSInteger)_audioDeviceID
{	
	if(audioDeviceID != _audioDeviceID){
		
		//get audio device
		NSArray* audioDevices = [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeSound];
		
		ofLog(OF_LOG_VERBOSE, "ofxQTKitVideoGrabber -- Audio Device List:  %s", [[audioDevices description] cString]);
		
		// Try to open the new device
		if(_audioDeviceID >= audioDevices.count){
			ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Error audio device ID out of range");
			return;
		}		
		selectedAudioDevice = [audioDevices objectAtIndex:_audioDeviceID];
		if([self setSelectedAudioDevice:selectedAudioDevice]){
			audioDeviceID = _audioDeviceID;
		}
	}
}

- (bool) setSelectedVideoDevice:(QTCaptureDevice *)_selectedVideoDevice
{
	BOOL success = YES;	
	if (self.videoDeviceInput) {
		// Remove the old device input from the session and close the device
		[self.session removeInput:videoDeviceInput];
		[[self.videoDeviceInput device] close];
		[videoDeviceInput release];
		videoDeviceInput = nil;
	}
	
	if (_selectedVideoDevice) {
		NSError *error = nil;
		
		// Try to open the new device
		success = [_selectedVideoDevice open:&error];
		if(success){
			// Create a device input for the device and add it to the session
			self.videoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:_selectedVideoDevice];
			
			success = [self.session addInput:self.videoDeviceInput error:&error];
			if(verbose) ofLog(OF_LOG_VERBOSE, "ofxQTKitVideoGrabber -- Attached camera %s", [[_selectedVideoDevice description] cString]);
		}
	}
	
	if(!success) ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Error adding device to session");	

	return success;
}

- (bool) setSelectedAudioDevice:(QTCaptureDevice *)_selectedAudioDevice
{
	BOOL success = YES;	
	if (self.audioDeviceInput) {
		// Remove the old device input from the session and close the device
		[self.session removeInput:audioDeviceInput];
		[[self.audioDeviceInput device] close];
		[audioDeviceInput release];
		audioDeviceInput = nil;
	}
	
	if (_selectedAudioDevice) {
		NSError *error = nil;
		
		// Try to open the new device
		success = [_selectedAudioDevice open:&error];
		if(success){
			// Create a device input for the device and add it to the session
			self.audioDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:_selectedAudioDevice];
			
			success = [self.session addInput:self.audioDeviceInput error:&error];
			ofLog(OF_LOG_VERBOSE, "ofxQTKitVideoGrabber -- Attached audio %s", [[_selectedAudioDevice description] cString]);
		}
	}
	
	if(!success) ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Error adding audio device to session");	
	
	return success;
}

- (void) initRecording:(NSString*)_selectedVideoCodec audioCodec:(NSString*)_selectedAudioCodec
{
	BOOL success = YES;	
	NSError *error = nil;
	
	// Create the movie file output and add it to the session		[added by gameover]
	captureMovieFileOutput = [[QTCaptureMovieFileOutput alloc] init];
	success = [self.session addOutput:captureMovieFileOutput error:&error];
	if (!success) {
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Error adding capture output to session");
	} else {
		
		[self setVideoCodec:_selectedVideoCodec];
		[self setAudioCodec:_selectedAudioCodec];
		
		isRecordReady = YES;
	}
}

+ (NSArray*) listVideoCodecs
{
	NSArray* videoCodecs = [QTCompressionOptions compressionOptionsIdentifiersForMediaType:QTMediaTypeVideo];
	
	NSLog(@"ofxQTKitVideoGrabber listing video compression options"); 
	[self enumerateArray:videoCodecs];
	
	return videoCodecs;
}

+ (NSArray*) listAudioCodecs
{
	NSArray* audioCodecs = [QTCompressionOptions compressionOptionsIdentifiersForMediaType:QTMediaTypeSound];
	
	NSLog(@"ofxQTKitVideoGrabber listing audio compression options"); 
	[self enumerateArray:audioCodecs];
	
	return audioCodecs;
}

- (void) setVideoCodec:(NSString*)_selectedVideoCodec
{
	// set codec on connection for type Video
	NSArray *outputConnections = [captureMovieFileOutput connections];
	QTCaptureConnection *connection;
	for (connection in outputConnections)
	{
		if ([[connection mediaType] isEqualToString:QTMediaTypeVideo])
			[captureMovieFileOutput setCompressionOptions:[QTCompressionOptions compressionOptionsWithIdentifier:_selectedVideoCodec] forConnection:connection];
	}
}

- (void) setAudioCodec:(NSString*)_selectedAudioCodec
{
	// set codec on connection for type Sound
	NSArray *outputConnections = [captureMovieFileOutput connections];
	QTCaptureConnection *connection;
	for (connection in outputConnections)
	{
		if ([[connection mediaType] isEqualToString:QTMediaTypeSound])
			[captureMovieFileOutput setCompressionOptions:[QTCompressionOptions compressionOptionsWithIdentifier:_selectedAudioCodec] forConnection:connection];
	}
}

- (void) startRecording:(NSString*)filePath
{
	if (isRecordReady) {
		
		BOOL success = YES;
		NSError *error = nil;
		
		if (isRecording) [self stopRecording]; // make sure last movie has stopped
		
		// set url for recording
		[captureMovieFileOutput recordToOutputFileURL:[NSURL fileURLWithPath:filePath]];
		
		ofLog(OF_LOG_VERBOSE, "Started recording movie to: %s", [filePath cString]);
		
		isRecording = YES;
		
	} else {
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Not set up to record - call initRecording first");
	}
}

- (void) stopRecording
{
	if (isRecordReady) {
		
		// set url to nil to stop recording
		[captureMovieFileOutput recordToOutputFileURL:nil];
		
		ofLog(OF_LOG_VERBOSE, "Stopped recording movie");
		
		isRecording = NO;
		
	} else {
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber - ERROR - Not set up to record - call initRecording first");
	}
}

//Frame from the camera
//this tends to be fired on a different thread, so keep the work really minimal
- (void) outputVideoFrame:(CVImageBufferRef)videoFrame 
		 withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
		   fromConnection:(QTCaptureConnection *)connection
{
	CVImageBufferRef toRelease;	
	@synchronized(self){
		toRelease = cvFrame;
		CVBufferRetain(videoFrame);
		cvFrame = videoFrame;
		hasNewFrame = YES;
		if(toRelease != NULL){
			CVBufferRelease(toRelease);
		}
	}	
}

- (void) setUseTexture:(BOOL)_useTexture
{
	if(_useTexture && texture == NULL){
		texture = new ofTexture();
		texture->allocate(self.width, self.height, GL_RGB);
	}
	useTexture = _useTexture;
}

- (void) update
{
	@synchronized(self){
		if(hasNewFrame){
			CVPixelBufferLockBaseAddress(cvFrame, 0);
			unsigned char* src = (unsigned char*)CVPixelBufferGetBaseAddress(cvFrame);
			
			//I wish this weren't necessary, but
			//in my tests the only performant & reliabile
			//pixel format for QTCapture is k32ARGBPixelFormat, 
			//to my knowledge there is only RGBA format
			//available to gl textures
			
			//convert pixels from ARGB to RGB			
			argb_to_rgb(src, pixels->getPixels(), width*height);
			if(self.useTexture){
				texture->loadData(pixels->getPixels(), width, height, GL_RGB);
			}
			CVPixelBufferUnlockBaseAddress(cvFrame, 0);
			hasNewFrame = NO;
			isFrameNew = YES;
		}
		else{
			isFrameNew = NO;
		}
	}	
}

/**
 * JG:
 * This is experimental and doesn't quite work yet --
 *
 * Bring up the oldschool video setting dialog.
 * It just gets a pointer to the underlying SequenceGrabber
 * component from within QTKit.
 * this doesn't seem to work for all cameras, for example my macbook iSight the pointer is null
 * but it does work with the Macam driver for the PS3Eye which is the important one at the moment
 */
- (void) videoSettings
{
	/*
	NSDictionary* attr = [self.videoDeviceInput.device deviceAttributes];
	if (attr == NULL) {
		ofLog(OF_LOG_WARNING, "ofxQTKitVideoGrabber -- Warning: Video Settings not available for this camera");
		return;
	}
	
	NSValue* sgnum = [attr objectForKey:QTCaptureDeviceLegacySequenceGrabberAttribute];
	if (sgnum == NULL) {
		ofLog(OF_LOG_WARNING, "ofxQTKitVideoGrabber -- Warning: Video Settings not available for this camera");
		return;
	}
	
	
	OSErr err;
	SeqGrabComponent sg = (SeqGrabComponent)[sgnum pointerValue];
	SGChannel chan;
	OSType type;
	
	err = SGPause (sg, true);
	if(err){
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Could not pause for video settings");
	}
	
	static SGModalFilterUPP gSeqGrabberModalFilterUPP = NewSGModalFilterUPP(SeqGrabberModalFilterUPP);
	err = SGGetIndChannel(sg, 1, &chan, &type );
	if (err == noErr){
		ComponentResult result = SGSettingsDialog(sg, chan, 0, NULL, 0, gSeqGrabberModalFilterUPP, 0 );
		if(result != noErr){
			ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Error in Sequence Grabber Dialog");
		}
	}
	else{
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Could not init channel");
	}
	
	SGPause(sg, false);
	*/
}

// not sure if this works at all but worth a try [gameover]
- (void) audioSettings
{
	/*
	NSDictionary* attr = [self.audioDeviceInput.device deviceAttributes];
	if (attr == NULL) {
		ofLog(OF_LOG_WARNING, "ofxQTKitVideoGrabber -- Warning: Audio Settings not available for this audio device");
		return;
	}
	
	NSValue* sgnum = [attr objectForKey:QTCaptureDeviceLegacySequenceGrabberAttribute];
	if (sgnum == NULL) {
		ofLog(OF_LOG_WARNING, "ofxQTKitVideoGrabber -- Warning: Audio Settings not available for this audio device");
		return;
	}
	
	
	OSErr err;
	SeqGrabComponent sg = (SeqGrabComponent)[sgnum pointerValue];
	SGChannel chan;
	OSType type;
	
	err = SGPause (sg, true);
	if(err){
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Could not pause for audio settings");
	}
	
	static SGModalFilterUPP gSeqGrabberModalFilterUPP = NewSGModalFilterUPP(SeqGrabberModalFilterUPP);
	err = SGGetIndChannel(sg, 1, &chan, &type );
	if (err == noErr){
		ComponentResult result = SGSettingsDialog(sg, chan, 0, NULL, 0, gSeqGrabberModalFilterUPP, 0 );
		if(result != noErr){
			ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Error in Sequence Grabber Dialog");
		}
	}
	else{
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Could not init channel");
	}
	
	SGPause(sg, false);
	*/
}

- (void) stop
{
	if(self.isRunning){
		if (isRecording) [self stopRecording];
		[self.session stopRunning];
		if ([[videoDeviceInput device] isOpen]) [[videoDeviceInput device] close];
		if ([[audioDeviceInput device] isOpen]) [[audioDeviceInput device] close];
		[videoDeviceInput release];
		[audioDeviceInput release];
		[captureMovieFileOutput release];
		//[super dealloc];															// possible mem leak but otherwise we crash on closing??
	}	
	self.session = nil;
	free(pixels);
	if(texture != NULL){
		delete texture;
	}
}


- (BOOL) isRunning
{
	return self.session && self.session.isRunning;
}

@end

//C++ Wrapper class:
ofxQTKitVideoGrabber::ofxQTKitVideoGrabber(){
	videoDeviceID = 0;
	audioDeviceID = 0;
    videoCodecIDString = "QTCompressionOptionsJPEGVideo";					// setting default video codec
	audioCodecIDString = "QTCompressionOptionsHighQualityAACAudio";			// setting audio video codec
	grabber = NULL;
	isInited = false;
	bUseTexture = true;
    bUseAudio = false;
}

ofxQTKitVideoGrabber::~ofxQTKitVideoGrabber(){
	if(isInited){
		close();		
	}
}

void ofxQTKitVideoGrabber::setDeviceID(int _videoDeviceID){
    setVideoDeviceID(_videoDeviceID);
}

void ofxQTKitVideoGrabber::setVideoDeviceID(int _videoDeviceID){
    videoDeviceID = _videoDeviceID;
	if(isInited){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[grabber setVideoDeviceID:videoDeviceID];
		[pool release];	
	}
}

void ofxQTKitVideoGrabber::setAudioDeviceID(int _audioDeviceID){
	audioDeviceID = _audioDeviceID;
	if(isInited){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[grabber setAudioDeviceID:audioDeviceID];
		[pool release];	
	}		
}

void ofxQTKitVideoGrabber::setDeviceID(string _videoDeviceIDString){
    setVideoDeviceID(_videoDeviceIDString);
}

void ofxQTKitVideoGrabber::setVideoDeviceID(string _videoDeviceIDString){
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// set array filled with devices
	NSArray* deviceArray = [[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo] 
							arrayByAddingObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];
	
	// convert device string to NSString
	NSString* deviceIDString = [NSString stringWithUTF8String: _videoDeviceIDString.c_str()];
	
	// find the index of the device name in the array of devices
	videoDeviceID = (NSInteger)[QTKitVideoGrabber getIndexofStringInArray:deviceArray
															 stringToFind:deviceIDString];
	
	if(isInited)[grabber setVideoDeviceID:videoDeviceID];
	[pool release];	
}

void ofxQTKitVideoGrabber::setAudioDeviceID(string _audioDeviceIDString){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// set array filled with devices
	NSArray* deviceArray = [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeSound];
	
	// convert device string to NSString
	NSString* deviceIDString = [NSString stringWithUTF8String: _audioDeviceIDString.c_str()];
	
	// find the index of the device name in the array of devices
	audioDeviceID = (NSInteger)[QTKitVideoGrabber getIndexofStringInArray:deviceArray
															 stringToFind:deviceIDString];
	
	if(isInited) [grabber setAudioDeviceID:audioDeviceID];
	[pool release];	
}

bool ofxQTKitVideoGrabber::initGrabber(int w, int h){
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	grabber = [[QTKitVideoGrabber alloc] initWithWidth:w height:h videodevice:videoDeviceID audiodevice:audioDeviceID usingTexture:bUseTexture usingAudio:bUseAudio];
	isInited = (grabber != nil);
	[pool release];
}

// used to init with no texture or preview etc ie., recording only
void ofxQTKitVideoGrabber::initGrabberWithoutPreview(){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	grabber = [[QTKitVideoGrabber alloc] initWithoutPreview:videoDeviceID audiodevice:audioDeviceID usingAudio:bUseAudio];
	isInited = (grabber != nil);
	[pool release];	
}

void ofxQTKitVideoGrabber::initRecording(){
	if(confirmInit()){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString * NSvideoCodec = [NSString stringWithUTF8String: videoCodecIDString.c_str()];
		NSString * NSaudioCodec = [NSString stringWithUTF8String: audioCodecIDString.c_str()];
		[grabber initRecording:NSvideoCodec audioCodec:NSaudioCodec];
		[pool release];	
	}
}

vector<string>& ofxQTKitVideoGrabber::listVideoCodecs(){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray* videoCodecs = [QTKitVideoGrabber listVideoCodecs];
	videoCodecsVec.clear();
	for (id object in videoCodecs){
		string str = [[object description] cStringUsingEncoding: NSASCIIStringEncoding];
		videoCodecsVec.push_back(str);
	}
	[pool release];	
	return videoCodecsVec;
}

vector<string>& ofxQTKitVideoGrabber::listAudioCodecs(){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray* audioCodecs = [QTKitVideoGrabber listAudioCodecs];
	audioCodecsVec.clear();
	for (id object in audioCodecs){
		string str = [[object description] cStringUsingEncoding: NSASCIIStringEncoding];
		audioCodecsVec.push_back(str);
	}
	[pool release];	
	return audioCodecsVec;
}

void ofxQTKitVideoGrabber::setVideoCodec(string _videoCodec){
	videoCodecIDString = _videoCodec;	
	if(isInited){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
		NSString * NSvideoCodec = [NSString stringWithUTF8String: videoCodecIDString.c_str()];
		[grabber setVideoCodec:NSvideoCodec];
		[pool release];
	}
	
}

void ofxQTKitVideoGrabber::setAudioCodec(string _audioCodec){
	audioCodecIDString = _audioCodec;	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	NSString * NSaudioCodec = [NSString stringWithUTF8String: audioCodecIDString.c_str()];
	[grabber setVideoCodec:NSaudioCodec];
	[pool release];
}

void ofxQTKitVideoGrabber::startRecording(string filePath){
	NSString * NSfilePath = [NSString stringWithUTF8String: ofToDataPath(filePath).c_str()];
	[grabber startRecording:NSfilePath];
}

void ofxQTKitVideoGrabber::stopRecording(){
	[grabber stopRecording];
}

void ofxQTKitVideoGrabber::update(){ 
    if(confirmInit()){
		[grabber update];
	} 
}

bool ofxQTKitVideoGrabber::isFrameNew(){
	return isInited && [grabber isFrameNew];
}

bool ofxQTKitVideoGrabber::isReady(){
	return isInited;
}

bool ofxQTKitVideoGrabber::isRecording(){
	return isReady() && [grabber isRecording];
}

// would be better if listDevices returned a vector of devices too, 
// but that requires updating the base class...perhaps we could
// then have a ofBaseDevice class to be used for enumerating any 
// type of device for video, sound, serial devices etc etc???
void ofxQTKitVideoGrabber::listDevices(){
    listVideoDevices();
}

vector<string>& ofxQTKitVideoGrabber::listVideoDevices(){
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray* videoDevices = [QTKitVideoGrabber listDevices];
	videoDeviceVec.clear();
	for (id object in videoDevices){
		string str = [[object description] cStringUsingEncoding: NSASCIIStringEncoding];
		videoDeviceVec.push_back(str);
	}
	[pool release];
	return videoDeviceVec;
	
}

vector<string>& ofxQTKitVideoGrabber::listAudioDevices(){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray* audioDevices = [QTKitVideoGrabber listAudioDevices];
	audioDeviceVec.clear();
	for (id object in audioDevices){
		string str = [[object description] cStringUsingEncoding: NSASCIIStringEncoding];
		audioDeviceVec.push_back(str);
	}
	[pool release];
	return audioDeviceVec;
    
}

void ofxQTKitVideoGrabber::close(){	
	[grabber stop];
	[grabber release];
	isInited = false;	
}

unsigned char* ofxQTKitVideoGrabber::getPixels(){
	if(confirmInit()){
		return [grabber pixels]->getPixels();
	}
	return NULL;
}

ofPixelsRef ofxQTKitVideoGrabber::getPixelsRef(){
	if(confirmInit()){
		return *[grabber pixels];
	}
}
	
void ofxQTKitVideoGrabber::setUseTexture(bool _bUseTexture){
	if(_bUseTexture != bUseTexture){
		if(isInited){
			grabber.useTexture = _bUseTexture;
		}
		bUseTexture = _bUseTexture;
	}
}

void ofxQTKitVideoGrabber::setUseAudio(bool _bUseAudio){
	if(_bUseAudio != bUseAudio){
		if(isInited){
			ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Requesting to use audio after grabber is already initialized. Try doing this first!");
		}
		bUseAudio = _bUseAudio;
	}
}

ofTexture&	ofxQTKitVideoGrabber::getTextureReference(){
	if(!bUseTexture){
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- Requesting texture while use texture is false");
	}
	if(confirmInit() && bUseTexture){
		return *[grabber texture];
	}
}

void ofxQTKitVideoGrabber::setVerbose(bool bTalkToMe){
	if(confirmInit()){
		grabber.verbose = bTalkToMe;
	}
}

void ofxQTKitVideoGrabber::videoSettings(){
	if(confirmInit()){
		NSLog(@"loading video settings");
		[grabber videoSettings];
	}
}

// no idea if this really works??? [gameover]
void ofxQTKitVideoGrabber::audioSettings(){
	if(confirmInit()){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];		// was leaking before [added by gameover]
		NSLog(@"loading audio settings");
		[grabber audioSettings];
		[pool release];
	}
}

void ofxQTKitVideoGrabber::draw(float x, float y, float w, float h){
	if(confirmInit()){
		[grabber texture]->draw(x, y, w, h);
	}
}

void ofxQTKitVideoGrabber::draw(float x, float y){
	if(confirmInit()){
		[grabber texture]->draw(x, y);
	}
}

int ofxQTKitVideoGrabber::getDeviceID(){
    return getVideoDeviceID();
}

int ofxQTKitVideoGrabber::getVideoDeviceID(){
    if(confirmInit()){
		return grabber.videoDeviceID;
	}
	return -1;
}

int ofxQTKitVideoGrabber::getAudioDeviceID(){
	if(confirmInit()){
		return grabber.audioDeviceID;
	}
	return -1;
}

float ofxQTKitVideoGrabber::getHeight(){
	if(confirmInit()){
		return float(grabber.height);
	}
	return 0;
}

float ofxQTKitVideoGrabber::getWidth(){
	if(confirmInit()){
		return float(grabber.width);
	}
	return 0;
	
}
		  
bool ofxQTKitVideoGrabber::confirmInit(){
	if(!isInited){
		ofLog(OF_LOG_ERROR, "ofxQTKitVideoGrabber -- ERROR -- Calling method on non intialized video grabber");
	}
	return isInited;
}

