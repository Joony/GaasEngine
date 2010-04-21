package{

  import flash.utils.ByteArray;

  public class Intro{

    private static const SHOWSCREEN:uint   = 0;
    private static const COMMANDEND:uint   = 0; // end of COMMANDFLIRT block
    private static const FADEUP:uint       = 1; // fade up palette
    private static const FADEDOWN:uint     = 2;
    private static const DELAY:uint        = 3;
    private static const DOFLIRT:uint      = 4; // start flirt sequence (and wait for it to finish)
    private static const SCROLLFLIRT:uint  = 5; // start special floppy intro flirt sequence (and wait for it)
    private static const COMMANDFLIRT:uint = 6; // start flirt sequence and wait for it, while processing command block
    private static const BGFLIRT:uint      = 7; // start flirt sequence without waiting for it
    private static const WAITFLIRT:uint    = 8; // wait for sequence started by BGFLIRT
    private static const STOPFLIRT:uint    = 9;
    private static const STARTMUSIC:uint   = 10;
    private static const WAITMUSIC:uint    = 11;
    private static const PLAYVOICE:uint    = 12;
    private static const WAITVOICE:uint    = 13;
    private static const LOADBG:uint       = 14; // load new background sound
    private static const PLAYBG:uint       = 15; // play background sound
    private static const LOOPBG:uint       = 16; // loop background sound
    private static const STOPBG:uint       = 17; // stop background sound
    private static const SEQEND:uint       = 65535; // end of intro sequence

    private static const IC_PREPARE_TEXT:uint = 20; // commands used in COMMANDFLIRT block
    private static const IC_SHOW_TEXT:uint    = 21;
    private static const IC_REMOVE_TEXT:uint  = 22;
    private static const IC_MAKE_SOUND:uint   = 23;
    private static const IC_FX_VOLUME:uint    = 24;

    private static const FRAME_SIZE:uint = (Definitions.GAME_SCREEN_WIDTH * Definitions.GAME_SCREEN_HEIGHT);

    private var _disk:Disk;
    private var _screen:Screen;
    private var _textBuf:ByteArray = new ByteArray();
    private var _saveBuf:ByteArray = new ByteArray();
    private var _relDelay:uint = 0;

    private var _mainIntroSeq:Array = [
      DELAY,                  3000, // keep virgin screen up
      FADEDOWN,
      SHOWSCREEN,             60112, // revo screen + palette
      FADEUP,                 60113,
      DELAY,                  8000,
      FADEDOWN,
      SHOWSCREEN,             60114, // gibbo screen + palette
      FADEUP,                 60115,
      DELAY,                  2000,
      FADEDOWN,
      SEQEND
    ];

    private var _floppyIntroSeq:Array = [
      SHOWSCREEN,             60081,
      FADEUP,                 60080,
      DOFLIRT,                60082,
      DOFLIRT,                60083,
      DOFLIRT,                60084, // Beneath a Steel Sky
      DOFLIRT,                60085,
      DOFLIRT,                60086,
      SCROLLFLIRT,
      COMMANDFLIRT,           60087, // => command list 4a
      136, IC_MAKE_SOUND,     1, 70,
      90, IC_FX_VOLUME,       80,
      50, IC_FX_VOLUME,       90,
      5, IC_FX_VOLUME,        100,
      COMMANDEND,
      SHOWSCREEN,             60088,
      COMMANDFLIRT,           60089, // => command list 4b (cockpit)
      1000, IC_PREPARE_TEXT,  77,
      220, IC_SHOW_TEXT,      20, 160, // radar detects jamming signal
      105, IC_REMOVE_TEXT,
      105, IC_PREPARE_TEXT,   81,
      105, IC_SHOW_TEXT,      170,  86, // well switch to override you fool
      35, IC_REMOVE_TEXT,
      35, IC_PREPARE_TEXT,    477,
      35, IC_SHOW_TEXT,       30, 160,
      3, IC_REMOVE_TEXT,
      COMMANDEND,
      SHOWSCREEN,             60090,
      COMMANDFLIRT,           60091, // => command list 4c
      1000, IC_FX_VOLUME,     100,
      25, IC_FX_VOLUME,       110,
      15, IC_FX_VOLUME,       120,
      4, IC_FX_VOLUME,        127,
      COMMANDEND,
      FADEDOWN,
      SHOWSCREEN,             60093,
      FADEUP,                 60092,
      COMMANDFLIRT,           60094, // => command list 5
      31, IC_MAKE_SOUND,      2, 127,
      COMMANDEND,
      WAITMUSIC,
      FADEDOWN,
      SHOWSCREEN,             60096,
      STARTMUSIC,             2,
      FADEUP,                 60095,
      COMMANDFLIRT,           60097, // => command list 6a
      1000, IC_PREPARE_TEXT,  478,
      13, IC_SHOW_TEXT,       175, 155,
      COMMANDEND,
      COMMANDFLIRT,           60098, // => command list 6b
      131, IC_REMOVE_TEXT,
      131, IC_PREPARE_TEXT,   479,
      74, IC_SHOW_TEXT,       175, 155,
      45, IC_REMOVE_TEXT,
      45, IC_PREPARE_TEXT,    162,
      44, IC_SHOW_TEXT,       175, 155,
      4, IC_REMOVE_TEXT,
      COMMANDEND,
      SEQEND
    ];

    public function Intro(disk:Disk, screen:Screen){
      _disk = disk;
      _screen = screen;
    }

    public function startIntro():void{
      if (_screen.sequenceRunning())
	_screen.stopSequence();
    }

    public function doIntro(){
      var seqData:Array = _mainIntroSeq;
      while(seqData["current"]() != SEQEND) {
	if (!nextPart(seqData))
	  return false;
      }

      seqData = _floppyIntroSeq;

      while(seqData["current"]() != SEQEND) {
	if(!nextPart(seqData))
	  return false;
      }

      return true;
    }
    

    private function nextPart(data:Array) {
      var vData:uint = null;
      
      // return false means cancel intro
      var command:uint = data["next"]();
      switch(command){
        case SHOWSCREEN:
	  _screen.showScreen(data["next"]());
	  return true;
        case FADEUP:
	  _screen.paletteFadeUp(data["next"]());
	  _relDelay += 32 * 20; // hack: the screen uses a seperate delay function for the blocking fadeups. So add 32*20 msecs to out delay counter.
	  return true;
        case FADEDOWN:
	  _screen.fnFadeDown(0);
	  _relDelay += 32 * 20; // hack: see above.
	  return true;
        case DELAY:
	  if(!escDelay(data["next"]()))
	    return false;
	  return true;
        case DOFLIRT:
	  _screen.startSequence(data["next"]());
	  while(_screen.sequenceRunning())
	    if(!escDelay(50))
	      return false;
	  return true;
        case SCROLLFLIRT:
	  return floppyScrollFlirt();
        case COMMANDFLIRT:
	  return commandFlirt(data);
        case STOPFLIRT:
	  _screen.stopSequence();
	  return true;
        case BGFLIRT:
	  _screen.startSequence(data["next"]());
	  return true;
        case WAITFLIRT:
	  while(_screen.sequenceRunning())
	    if(!escDelay(50))
	      return false;
	  return true;
      default:
	trace("Unknown intro command:", command);
      }
      return true;
    }


    public function floppyScrollFlirt():Boolean{
      var scrollScreen:ByteArray;// = (uint8*)malloc(FRAME_SIZE * 2);
      memset(scrollScreen, 0, FRAME_SIZE);
      memcpy(scrollScreen + FRAME_SIZE, _skyScreen->giveCurrent(), FRAME_SIZE);

      uint8 *scrollPos = scrollScreen + FRAME_SIZE;
      uint8 *vgaData = _skyDisk->loadFile(60100);
      uint8 *diffData = _skyDisk->loadFile(60101);
      uint16 frameNum = READ_LE_UINT16(diffData);
      uint8 *diffPtr = diffData + 2;
      uint8 *vgaPtr = vgaData;
      bool doContinue = true;

      for (uint16 frameCnt = 1; (frameCnt < frameNum) && doContinue; frameCnt++) {
	uint8 scrollVal = *diffPtr++;
	if (scrollVal)
	  scrollPos -= scrollVal * GAME_SCREEN_WIDTH;

	uint16 scrPos = 0;
	while (scrPos < FRAME_SIZE) {
	  uint8 nrToDo, nrToSkip;
	  do {
	    nrToSkip = *diffPtr++;
	    scrPos += nrToSkip;
	  } while (nrToSkip == 255);
	  do {
	    nrToDo = *diffPtr++;
	    memcpy(scrollPos + scrPos, vgaPtr, nrToDo);
	    scrPos += nrToDo;
	    vgaPtr += nrToDo;
	  } while (nrToDo == 255);
	}
	_system->copyRectToScreen(scrollPos, GAME_SCREEN_WIDTH, 0, 0, GAME_SCREEN_WIDTH, GAME_SCREEN_HEIGHT);
	_system->updateScreen();
	if (!escDelay(60))
	  doContinue = false;
      }
      memcpy(_skyScreen->giveCurrent(), scrollPos, FRAME_SIZE);
      free(diffData);
      free(vgaData);
      free(scrollScreen);
      return doContinue;
    }

    

  }

}
