package{
  
  include 'includes/ByteArray.as';
  include 'includes/Array.as';

  import flash.display.Sprite;
  import flash.display.StageScaleMode;
  import flash.utils.ByteArray;

  import flash.utils.Timer;
  import flash.utils.getTimer;

  import flash.events.TimerEvent;

  import flash.events.MouseEvent;

  public class Test extends Sprite{

    private var _disk:Disk;
    private var _screen:Screen;

    private var virginLogo:ByteArray;

    public function Test(){
      var startTime:Number = getTimer();

      stage.scaleMode = StageScaleMode.NO_SCALE;

      _disk = new Disk();
      _screen = new Screen(_disk);
      addChild(_screen);


      //virginLogo = _disk.loadFile(60110);
      _screen.setPalette(_disk.loadFile(60111));
      _screen.showScreen(60110);

      //virginLogo = _disk.loadFile(60112);
      //_screen.setPalette(_disk.loadFile(60113));      

      //virginLogo = _disk.loadFile(60114);
      //_screen.setPalette(_disk.loadFile(60115));

      //_screen.setPalette(_disk.loadFile(60080));
      //virginLogo = _disk.loadFile(60081);
      //virginLogo = _disk.loadFile(60088);
      //virginLogo = _disk.loadFile(60090);

      //virginLogo = _disk.loadFile(60093);
      //_screen.setPalette(_disk.loadFile(60092));

      //virginLogo = _disk.loadFile(60096);
      //_screen.setPalette(_disk.loadFile(60095));

      //_screen.copyRectToScreen(virginLogo, 320, 0, 0, Screen.GAME_SCREEN_WIDTH, Screen.GAME_SCREEN_HEIGHT);

      trace("" + ((getTimer() - startTime) / 1000) + " seconds");

      var intro:Intro = new Intro(_disk, _screen);

    }

    
  }
}
