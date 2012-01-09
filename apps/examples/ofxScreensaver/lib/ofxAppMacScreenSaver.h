/**     ___           ___           ___                         ___           ___     
 *     /__/\         /  /\         /  /\         _____         /  /\         /__/|    
 *    |  |::\       /  /::\       /  /::|       /  /::\       /  /::\       |  |:|    
 *    |  |:|:\     /  /:/\:\     /  /:/:|      /  /:/\:\     /  /:/\:\      |  |:|    
 *  __|__|:|\:\   /  /:/~/::\   /  /:/|:|__   /  /:/~/::\   /  /:/  \:\   __|__|:|    
 * /__/::::| \:\ /__/:/ /:/\:\ /__/:/ |:| /\ /__/:/ /:/\:| /__/:/ \__\:\ /__/::::\____
 * \  \:\~~\__\/ \  \:\/:/__\/ \__\/  |:|/:/ \  \:\/:/~/:/ \  \:\ /  /:/    ~\~~\::::/
 *  \  \:\        \  \::/          |  |:/:/   \  \::/ /:/   \  \:\  /:/      |~~|:|~~ 
 *   \  \:\        \  \:\          |  |::/     \  \:\/:/     \  \:\/:/       |  |:|   
 *    \  \:\        \  \:\         |  |:/       \  \::/       \  \::/        |  |:|   
 *     \__\/         \__\/         |__|/         \__\/         \__\/         |__|/   
 *
 *  Description: 
 *				 
 *  ofxAppMacScreenSaver.h, created by Marek Bereza on 06/01/2012.
 */

#pragma once

#include <string>
using namespace std;
class ofBaseApp;

class ofxAppMacScreenSaver {
	
public:
	
	ofxAppMacScreenSaver();
	~ofxAppMacScreenSaver(){}
	
	void setupOpenGL(int w, int h, int screenMode, string dataPath);
	void initializeWindow();
	void runAppViaInfiniteLoop(ofBaseApp * appPtr);
	void setApp(ofBaseApp *app);
	
	
	/*ofPoint		getWindowSize();
	ofPoint		getScreenSize();
	*/
	
	int			getWidth();
	int			getHeight();	
	
	int			getWindowMode();
	
	int			getFrameNum();
	float		getFrameRate();
	double		getLastFrameTime();
	void		setFrameRate(float targetRate);
	
	void		enableSetupScreen();
	void		disableSetupScreen();
	
	// call this to do all the opengl stuff
	void display(void);
	
	// run this when there's time to wait before the next frame
	// it should tell the drawer when to ask itself to redraw
	void idle_cb(void);
	
	// call this when frame size has changed
	void resize_cb(int w, int h);

};

