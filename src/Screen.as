package{

  import flash.display.BitmapData;
  import flash.display.Bitmap;
  import flash.utils.ByteArray;
  import flash.utils.getTimer;

  public class Screen extends Bitmap{

    private static const VGA_COLOURS:uint = 256;
    private static const GAME_COLOURS:uint = 240;
    
    public static const GAME_SCREEN_WIDTH:uint = 320;
    public static const GAME_SCREEN_HEIGHT:uint = 192;

    public static const SEQ_DELAY:uint = 3;

    private var _currentScreen:ByteArray;
    public function giveCurrent():ByteArray{ return _currentScreen; }

    private var _palette:ByteArray = new ByteArray();
    private var _currentPalette:uint;
    private var _top16Colours:Array = new Array();

    private var _seqInfo:SequenceData = new SequenceData();
    
    private var _disk:Disk;

    public function Screen(disk:Disk){
      _disk = disk;
      init();
    }

    private function init():void{
      this.smoothing = false;

      _top16Colours = [
		       0,   0,   0,
		       154, 154, 154,
		       255, 255, 255,
		       0,   0,   0,
		       0,   0,   0,
		       0,   0,   0,
		       0,   0,   0,
		       219, 219, 219,
		       182, 190, 199,
		       130, 125, 166,
		       117, 93,  150,
		       93,  73,  121,
		       199, 44,  44,
		       158, 20,  20,
		       117, 4,   4,
		       255, 255, 255];
      
      var tempPalette:ByteArray = new ByteArray();
      var i:uint;
      //blank the first 240 colors of the palette
      for(i = 0; i < GAME_COLOURS; i++){
	tempPalette.writeInt(0);
      }

      //set the remaining colors
      for (i = 0; i < (VGA_COLOURS-GAME_COLOURS); i++) {
	tempPalette[4 * GAME_COLOURS + i * 4] = (_top16Colours[i * 3] << 2) + (_top16Colours[i * 3] >> 4);
	tempPalette[4 * GAME_COLOURS + i * 4 + 1] = (_top16Colours[i * 3 + 1] << 2) + (_top16Colours[i * 3 + 1] >> 4);
	tempPalette[4 * GAME_COLOURS + i * 4 + 2] = (_top16Colours[i * 3 + 2] << 2) + (_top16Colours[i * 3 + 2] >> 4);
	tempPalette[4 * GAME_COLOURS + i * 4 + 3] = 0x00;
      }

      //set the palette
      updatePalette(tempPalette, 0, VGA_COLOURS);
      _currentPalette = 0;

      _seqInfo.framesLeft = 0;
      _seqInfo.data = null;
      _seqInfo.dataPosition = 0;
      _seqInfo.runningItem = false;
    }


    // SEQUENCE METHODS

    public function sequenceRunning():Boolean{
      return _seqInfo.runningItem;
    }
    
    public function startSequence(fileNumber:uint):void{
      _seqInfo.data = _disk.loadFile(fileNumber);
      _seqInfo.framesLeft = _seqInfo.data[0];
      _seqInfo.dataPosition = _seqInfo.data + 1;  //pointer
      _seqInfo.delay = SEQ_DELAY;
      _seqInfo.running = true;
      _seqInfo.runningItem = false;
    }

    public function stopSequence():void{
      _seqInfo.runningItem = false;
      _seqInfo.framesLeft = 0;
      _seqInfo.data =null
      _seqInfo.dataPosition = 0;
    }


    // PALETTE METHODS

    //set a new palette, pal is a pointer to dos vga rgb components 0..63
    public function setPalette(palette:ByteArray):void{
      convertPalette(palette, _palette);
      updatePalette(_palette, 0, GAME_COLOURS);
      //updateScreen();
    }

    private function convertPalette(inPalette:ByteArray, outPalette:ByteArray):void{ //convert 3 byte 0..63 rgb to 4byte 0..255 rgbx
      
      var dst:BitmapData = new BitmapData(GAME_SCREEN_WIDTH, GAME_SCREEN_HEIGHT);
      dst.lock();
      var xpos:uint;
      var ypos:uint;
      
      outPalette.position = 0;
      

      var i:uint;
      for(i = 0; i < VGA_COLOURS; i++){
	var red:uint = inPalette[3 * i];
	var green:uint = inPalette[3 * i + 1];
	var blue:uint = inPalette[3 * i + 2];
	var pixelValue:uint = (((red << 2) + (red >> 4)) << 16) + (((green << 2) + (green >> 4)) << 8) + ((blue << 2) + (blue >> 4));
	outPalette.writeInt(pixelValue);
	
	//trace("colour: " + i + ", red: " + red + ", green: " + green + ", blue: " + blue + ", pixelValue: " + pixelValue + ", red: " + ((red << 2) + (red >> 4)) + ", green: " + ((green << 2) + (green >> 4)) + ", blue: " + ((blue << 2) + (blue >> 4)) + ", component red: " + ((pixelValue >>> 16) & 0xff) + ", component green: " + ((pixelValue >>> 8) & 0xff) + ", blue: " + (pixelValue & 0xff));
	dst.setPixel(xpos++, ypos, pixelValue);
	if(xpos >= GAME_SCREEN_WIDTH)
	  ypos++;

      }
      
      dst.unlock();
      this.bitmapData = dst;

    }

    private function updatePalette(colours:ByteArray, start:uint, num:uint):void{
      var i:uint;
      for(i = 0; i < num; i++){
	_palette["writeIntAt"](colours["readUnsignedIntAt"](i), _currentPalette + start + i);
	//trace(colours["readUnsignedIntAt"](i))
      }
    }



    public function showScreen(fileNumber:uint):void{
      _currentScreen = _disk.loadFile(fileNumber);
      if(_currentScreen)
	copyRectToScreen(_currentScreen, 320, 0, 0, Screen.GAME_SCREEN_WIDTH, Screen.GAME_SCREEN_HEIGHT);
	
    }

    /**
     * Blit a bitmap to the virtual screen.
     * The real screen will not immediately be updated to reflect the changes.
     * Client code has to to call updateScreen to ensure any changes are
     * visible to the user. This can be used to optimize drawing and reduce
     * flicker.
     * The graphics data uses 8 bits per pixel, using the palette specified
     * via setPalette.
     *
     * @param buf the buffer containing the graphics data source
     * @param pitch the pitch of the buffer (number of bytes in a scanline)
     * @param x the x coordinate of the destination rectangle
     * @param y the y coordinate of the destination rectangle
     * @param w the width of the destination rectangle
     * @param h the height of the destination rectangle
     *
     * @see updateScreen
     */
    private function copyRectToScreen(buffer:ByteArray, pitch:int, x:int, y:int, w:int, h:int):void{
      var dst:BitmapData = new BitmapData(GAME_SCREEN_WIDTH, GAME_SCREEN_HEIGHT);
      var xpos:uint;
      var ypos:uint;
      var startTime:Number = getTimer();
      dst.lock();
      for(ypos = y; ypos < h; ypos ++){
	for(xpos = x; xpos < w; xpos++){
	  dst.setPixel(xpos, ypos, _palette["readUnsignedIntAt"](_currentPalette + buffer["readUnsignedByteAt"]((GAME_SCREEN_WIDTH * ypos) + xpos) * 4));
	  //if(_palette["readUnsignedIntAt"](buffer["readUnsignedByteAt"]((GAME_SCREEN_WIDTH * ypos) + xpos)) > 0) trace("colour:", _palette["readUnsignedIntAt"](_currentPalette + buffer["readUnsignedByteAt"]((GAME_SCREEN_WIDTH * ypos) + xpos) * 4), "index:", _currentPalette + buffer["readUnsignedByteAt"]((GAME_SCREEN_WIDTH * ypos) + xpos));
	}
      }
      dst.unlock();
      this.bitmapData = dst;
      trace("Screen update took " + ((getTimer() - startTime) / 1000) + " seconds.");

      _currentPalette++;

      /*
      if (_videoMode.screenWidth == w && pitch == w * _screenFormat.bytesPerPixel) {
	memcpy(dst, src, h*w*_screenFormat.bytesPerPixel);
      } else {
	do {
	  memcpy(dst, src, w * _screenFormat.bytesPerPixel);
	  src += pitch;
	  dst += _videoMode.screenWidth * _screenFormat.bytesPerPixel;
	} while (--h);
      }*/

    }
    

  }

}
