package{

  public class Definitions{

    //This file is incomplete, several flags still missing.

    // grafixProg pointer types:
    public static const OG_PTR_NULL:uint    = 0;
    public static const OG_AUTOROUTE:uint   = 1;
    public static const OG_COMPACT:uint     = 2;
    public static const OG_COMPACTELEM:uint = 3; // needed by fnSetToStand
    public static const OG_TALKTABLE:uint   = 4;

    // language codes:
    public static const SKY_ENGLISH:uint = 0;
    public static const SKY_GERMAN:uint  = 1;
    public static const SKY_FRENCH:uint  = 2;
    public static const SKY_USA:uint     = 3;
    public static const SKY_SWEDISH:uint = 4;
    public static const SKY_ITALIAN:uint = 5;
    public static const SKY_PORTUGUESE:uint = 6;
    public static const SKY_SPANISH:uint = 7;

    public static const ST_COLLISION_BIT:uint = 5;

    public static const S_COUNT:uint = 0;
    public static const S_FRAME:uint = 2;
    public static const S_AR_X:uint = 4;
    public static const S_AR_Y:uint = 6;
    public static const S_LENGTH:uint = 8;

    public static const KEY_BUFFER_SIZE:uint = 80;
    public static const SEQUENCE_COUNT:uint = 3;

    public static const FIRST_TEXT_COMPACT:uint = 23;
    public static const LAST_TEXT_COMPACT:uint = 33;
    public static const FIXED_TEXT_WIDTH:uint = 128;

	//screen/grid defines
    public static const GAME_SCREEN_WIDTH:uint = 320;
    public static const GAME_SCREEN_HEIGHT:uint = 192;
    public static const FULL_SCREEN_WIDTH:uint = 320;
    public static const FULL_SCREEN_HEIGHT:uint = 200;

    public static const TOT_NO_GRIDS:uint = 70; //total no. of grids supported
    public static const GRID_SIZE:uint = 120; //grid size in bytes

    public static const GRID_X:uint = 20;
    public static const GRID_Y:uint = 24;
    public static const GRID_W:uint = 16;
    public static const GRID_H:uint = 8;

    public static const GRID_W_SHIFT:uint = 4;
    public static const GRID_H_SHIFT:uint = 3;

    public static const TOP_LEFT_X:uint = 128;
    public static const TOP_LEFT_Y:uint = 136;

	//item list defines
    public static const section_0_item:uint = 119;

    public static const MAIN_CHAR_HEIGHT:uint = 12;

    public static const C_BASE_MODE:uint = 0;
    public static const C_BASE_MODE56:uint = 56;
    public static const C_ACTION_MODE:uint = 4;
    public static const C_SP_COLOUR:uint = 90;
    public static const C_MEGA_SET:uint = 112;
    public static const C_GRID_WIDTH:uint = 114;
    public static const C_ANIM_UP:uint = 122;
    public static const C_STAND_UP:uint = 138;
    public static const C_TURN_TABLE:uint = 158;

    public static const SECTION_0_ITEM:uint = 119; //item number of first item section
    public static const NEXT_MEGA_SET:uint = (258 - C_GRID_WIDTH);

    public static const SEND_SYNC:uint = 0xFFFF;
    public static const LF_START_FX:uint = 0xFFFE;
    public static const SAFE_START_SCREEN:uint = 0;

	//autoroute defines
    public static const UPY:uint = 0;
    public static const DOWNY:uint = 1;
    public static const LEFTY:uint = 2;
    public static const RIGHTY:uint = 3;

    public static const ROUTE_SPACE:uint = 64;

    public static const PCONLY_F_R3_1:uint = 0;
    public static const PCONLY_F_R3_2:uint = 0;

    public static const RESTART_BUTT_X:uint = 147;
    public static const RESTART_BUTT_Y:uint = 309;
    public static const RESTORE_BUTT_X:uint = 246;
    public static const RESTORE_BUTT_Y:uint = 309;
    public static const EXIT_BUTT_X:uint = 345;
    public static const EXIT_BUTT_Y:uint = 309;

    public static const L_SCRIPT:uint = 1;
    public static const L_AR:uint = 2;
    public static const L_AR_ANIM:uint = 3;
    public static const L_AR_TURNING:uint = 4;
    public static const L_ALT:uint = 5;
    public static const L_MOD_ANIMATE:uint = 6;
    public static const L_TURNING:uint = 7;
    public static const L_CURSOR:uint = 8;
    public static const L_TALK:uint = 9;
    public static const L_LISTEN:uint = 10;
    public static const L_STOPPED:uint = 11;
    public static const L_CHOOSE:uint = 12;
    public static const L_FRAMES:uint = 13;
    public static const L_PAUSE:uint = 14;
    public static const L_WAIT_SYNC:uint = 15;
    public static const L_SIMPLE_MOD:uint = 16;

	// characters with own colour set
    public static const SP_COL_FOSTER:uint = 194;
    public static const SP_COL_JOEY:uint = 216;
    public static const SP_COL_JOBS:uint = 209;
    public static const SP_COL_SO:uint = 218;
    public static const SP_COL_HOLO:uint = 234;
    public static const SP_COL_LAMB:uint = 203;
    public static const SP_COL_FOREMAN:uint = 205;
    public static const SP_COL_SHADES:uint = 217;
    public static const SP_COL_MONITOR:uint = 224;
    public static const SP_COL_WRECK:uint = 219;     //wreck guard
    public static const SP_COL_ANITA:uint = 73;
    public static const SP_COL_DAD:uint = 224;
    public static const SP_COL_SON:uint = 223;
    public static const SP_COL_GALAG:uint = 194;
    public static const SP_COL_ANCHOR:uint = 85;      //194
    public static const SP_COL_BURKE:uint = 192;
    public static const SP_COL_BODY:uint = 234;
    public static const SP_COL_MEDI:uint = 235;
    public static const SP_COL_SKORL:uint = 241;     //skorl guard    will probably go
    public static const SP_COL_ANDROID2:uint = 222;
    public static const SP_COL_ANDROID3:uint = 222;
    public static const SP_COL_KEN:uint = 222;
    public static const SP_COL_HENRI30:uint = 128;     //207
    public static const SP_COL_GUARD31:uint = 216;
    public static const SP_DAN_COL:uint = 228;
    public static const SP_COL_BUZZER32:uint = 228;     //124
    public static const SP_COL_VINCENT32:uint = 193;
    public static const SP_COL_GARDENER32:uint = 145;
    public static const SP_COL_WITNESS:uint = 195;
    public static const SP_COL_JOBS82:uint = 209;
    public static const SP_COL_KEN81:uint = 224;
    public static const SP_COL_FATHER81:uint = 177;
    public static const SP_COL_TREVOR:uint = 216;
    public static const SP_COL_RADMAN:uint = 193;
    public static const SP_COL_BARMAN36:uint = 144;
    public static const SP_COL_BABS36:uint = 202;
    public static const SP_COL_GALLAGHER36:uint = 145;
    public static const SP_COL_COLSTON36:uint = 146;
    public static const SP_COL_JUKEBOX36:uint = 176;
    public static const SP_COL_JUDGE42:uint = 193;
    public static const SP_COL_CLERK42:uint = 195;
    public static const SP_COL_PROS42:uint = 217;
    public static const SP_COL_JOBS42:uint = 209;

    public static const SP_COL_HOLOGRAM_B:uint = 255;
    public static const SP_COL_BLUE:uint = 255;
    public static const SP_COL_LOADER:uint = 255;

    public static const SP_COL_UCHAR:uint = 255;

    public static const ST_NO_VMASK:uint = 0x200;

	// Files.asm
    public static const DISK_1:uint = (2048);
    public static const DISK_2:uint = (2048*2);
    public static const DISK_3:uint = (2048*3);
    public static const DISK_4:uint = (2048*4);
    public static const DISK_5:uint = (2048*5);
    public static const DISK_6:uint = (2048*6);
    public static const DISK_7:uint = (2048*7);
    public static const DISK_8:uint = (2048*8);
    public static const DISK_9:uint = (2048*9);
    public static const DISK_10:uint = (2048*10);
    public static const DISK_12:uint = (2048*12);
    public static const DISK_13:uint = (2048*13);
    public static const DISK_14:uint = (2048*14);
    public static const DISK_15:uint = (2048*15);
    public static const F_MODULE_0:uint = 60400;
    public static const F_MODULE_1:uint = 60401;
    public static const CHAR_SET_FILE:uint = 60150;

	// Script.equ


  }

}
