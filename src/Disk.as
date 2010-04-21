package{

  import flash.utils.ByteArray;
  import flash.utils.Endian;
  
  import flash.utils.getTimer;
  import flash.utils.setTimeout;

  import flash.system.ApplicationDomain;

  public class Disk{
    
    [Embed(source="../libs/sky.dsk", mimeType="application/octet-stream")]
    private var _dataDiskHandleClass:Class;
    private var _dataDiskHandle:ByteArray;

    [Embed(source="../libs/sky.dnr", mimeType="application/octet-stream")]
    private var _dnrHandleClass:Class;
    private var _dnrHandle:ByteArray;
    private var _dinnerTableEntries:uint;
    private var _dinnerTableArea:ByteArray;

    private var _lastLoadedFileSize:uint;

    private var _gameVersion:uint;

    public function Disk(){

      
      _dnrHandle = new _dnrHandleClass as ByteArray;
      _dnrHandle.endian = Endian.LITTLE_ENDIAN;
      _dataDiskHandle = new _dataDiskHandleClass() as ByteArray;
      _dataDiskHandle.endian = Endian.LITTLE_ENDIAN;


      //ApplicationDomain.currentDomain.domainMemory = _dataDiskHandle;

      _dinnerTableEntries = _dnrHandle.readUnsignedInt();
      _dinnerTableArea = new ByteArray();
      _dinnerTableArea.endian = Endian.LITTLE_ENDIAN;

      var entriesRead:uint = (read(_dnrHandle, 4, _dinnerTableArea, 8 * _dinnerTableEntries)) / 8;
      
      if (entriesRead != _dinnerTableEntries)
	throw new Error("entriesRead != dinnerTableEntries. [" + entriesRead + "/" + _dinnerTableEntries + "]");
      _gameVersion = determineGameVersion();
      trace("Found BASS version v0.0" + _gameVersion + " (" + _dinnerTableEntries + " dnr entries)");
      _dnrHandle = null;
      
      _dinnerTableArea.position = 0;
      //trace("_dinnerTableArea = " + _dinnerTableArea.readUnsignedByte());

      
      initCrc();
      //trace("_crcTable:", _crcTable, _crcTable.length);

      //loadFile(60150); // uncompressed
      //loadFile(36);
      //loadFile(60300); // compressed with header

      //trace("loadFile(60111):", loadFile(60111).length); // uncompressed - Palette for Virgin logo, file number 60110.
      //trace("loadFile(60110):", loadFile(60110).length); // compressed with no header - Virgin logo, the first image to be shown. It's pallete is file number 60111.
      
    }

    // allocate memory, load the file and return a pointer
    public function loadFile(fileNumber:uint):ByteArray{
      var cflag:uint;
      
      trace("load file " + (fileNumber >> 11) + ", " + (fileNumber & 2047) + " (" + fileNumber + ")");

      var fileInfoPointer:int = getFileInfo(fileNumber);
      
      if (fileInfoPointer == -1) {
	trace("File " + fileNumber + " not found");
	return null;
      }else{
	trace("File " + fileNumber + " found (fileInfoPointer = " + fileInfoPointer + ")");
      }

      var fileFlags:uint = readUnsignedInt24bit(_dinnerTableArea, fileInfoPointer + 5);
      var fileSize:uint = fileFlags & 0x03fffff;
      _dinnerTableArea.position = fileInfoPointer + 2;
      var fileOffset:uint = _dinnerTableArea["readUnsignedIntAt"](fileInfoPointer + 2, Endian.LITTLE_ENDIAN) & 0x0ffffff;
      _dinnerTableArea.position += 4;
      //trace("fileFlags:", fileFlags, "fileSize:", fileSize, "fileOffset:", fileOffset);

      if(cflag){
	if(_gameVersion == 331)
	  fileOffset <<= 3;
	else
	  fileOffset <<= 4;
      }

      var fileDestination:ByteArray = new ByteArray();
      fileDestination.endian = Endian.LITTLE_ENDIAN;
      
      _dataDiskHandle.position = fileOffset;

      //now read in the data
      var bytesRead:uint = read(_dataDiskHandle, fileOffset, fileDestination, fileSize);
      //trace("bytesRead:", bytesRead);
      
      cflag = (fileFlags >> 23) & 0x1;
      //if cflag == 0 then file is compressed, 1 == uncompressed
      //trace("cflag:", cflag);

      fileDestination.position = 0;
      var fileHeader:DataFileHeader = new DataFileHeader(fileDestination);
      //trace("fileHeader.flag:", fileHeader.flag);
      //trace("((fileHeader.flag >> 7) & 1):", ((fileHeader.flag >> 7) & 1));

      if((!cflag) && ((fileHeader.flag >> 7) & 1)){
	trace("File is RNC compressed.");

        var decompSize:uint = (fileHeader.flag & ~0xFF) << 8;
        //trace("decompSize:", decompSize);
	decompSize |= fileHeader.s_tot_size;
	//trace("decompSize:", decompSize);

	var uncompDest:ByteArray = new ByteArray();

	var output:ByteArray;
	//output.endian = Endian.LITTLE_ENDIAN;
	var input:ByteArray = fileDestination;

	var unpackLen:int;

	//trace("(fileFlags >> 22) & 0x1:", ((fileFlags >> 22) & 0x1));

	if((fileFlags >> 22) & 0x1){ //do we include the header?
	  // don't return the file's header
	  trace("don't return the file's header");
	  output = uncompDest;
	  unpackLen = unpackM1(input, output, 0);
	}else{
	  trace("return the file's header");
	  //trace("uncompDest:", uncompDest.position, uncompDest.length);
	  uncompDest.writeBytes(fileHeader.readHeader());
	  //trace("uncompDest:", uncompDest.position, uncompDest.length);
	  output = uncompDest;
	  unpackLen = unpackM1(input, output, 0);
	  if(unpackLen){
    	    //trace("unpacking completed, adding header length, unpackLen:", unpackLen);
	    unpackLen += fileHeader.readHeader().length;
	  }
	}
	
	trace("unpacking completed, unpackLen:", unpackLen);
	
	if(unpackLen == 0){ //Unpack returned 0: file was probably not packed.
	  return fileDestination;
	}else{
	  if (unpackLen != decompSize)
	    trace("ERROR: File " + fileNumber + ": invalid decomp size! (was: " + unpackLen + ", should be: " + decompSize + ")");
	  _lastLoadedFileSize = decompSize;

	  return uncompDest;
	}

      }else{
	trace("File is not RNC compressed.");
	return fileDestination;
      }
      
      return null;
    }


    private function read(source:ByteArray, sourcePosition:uint, dataDestination:ByteArray, dataSize:uint):uint{
      source.position = sourcePosition;
      if(dataSize > source.bytesAvailable) {
	dataSize = source.bytesAvailable;
      }
      //trace("read() sourcePosition = " + sourcePosition + ", dataSize = " + dataSize + ", source.bytesAvailable = " + source.bytesAvailable + ", source.length = " + source.length);
      source.readBytes(dataDestination, 0, dataSize);
      
      return dataSize;
    }

    private function determineGameVersion():uint{
      switch(_dinnerTableEntries){
        case 232:
	  // German floppy demo (v0.0272)
	  return 272;
	case 243:
	  // pc gamer demo (v0.0109)
	  return 109;
	case 247:
	  // English floppy demo (v0.0267)
	  return 267;
	case 1404:
	  // floppy (v0.0288)
	  return 288;
	case 1413:
	  // floppy (v0.0303)
	  return 303;
	case 1445:
	  // floppy (v0.0331 or v0.0348)
	  if(_dataDiskHandle.length == 8830435)
	    return 348;
	  else
	    return 331;
	case 1711:
	  // cd demo (v0.0365)
	  return 365;
	case 5099:
	  // cd (v0.0368)
	  return 368;
	case 5097:
	  // cd (v0.0372)
	  return 372;
        default:
	  throw new Error("Unknown game version! " + _dinnerTableEntries + " dinner table entries");
      }
    }

    private function getFileInfo(fileNumber:uint):int{
      //trace("getFileInfo() fileNumber = " + fileNumber);
      var dnrTbl16Ptr:uint;
      for(var i:uint = 0; i < _dinnerTableEntries; i++){
	//trace("dnrTbl16Ptr:", _dinnerTableArea["readUnsignedShortAt"](dnrTbl16Ptr, Endian.LITTLE_ENDIAN));
	if(_dinnerTableArea["readUnsignedShortAt"](dnrTbl16Ptr, Endian.LITTLE_ENDIAN) == fileNumber){
	  return dnrTbl16Ptr;
	}
	dnrTbl16Ptr += 8;
      }

      return -1; // not found;
    }

    private static const RNC_SIGNATURE:uint = 0x524E4301;
    private static const NOT_PACKED:uint = 0;
    private static const PACKED_CRC:int = -1;
    private static const UNPACKED_CRC:int = -2;
    private static const HEADER_LEN:uint = 18;
    private static const MIN_LENGTH:uint = 2;
    private var _crcTable:ByteArray = new ByteArray();
    private function initCrc():void{
      var cnt:uint = 0;
      var tmp1:uint = 0;
      var tmp2:uint = 0;

      for(tmp2 = 0; tmp2 < 0x100; tmp2++){
	tmp1 = tmp2;
	for(cnt = 8; cnt > 0; cnt--){
	  if(tmp1 % 2) {
	    tmp1 >>= 1;
	    tmp1 ^= 0x0a001;
	  } else
	    tmp1 >>= 1;
	}
	_crcTable.position = tmp2*2;
	_crcTable.writeShort(tmp1);
      }
    }


    private var _srcPtr:uint;
    private var _dstPtr:uint;
    //private var _bitCount:uint;
    //private var _bitBuffl:uint;
    //private var _bitBuffh:uint;
    private var _bitBuff:ByteArray = new ByteArray();
    private static const BIT_BUFFER_LOW:uint = 0;
    private static const BIT_BUFFER_HIGH:uint = 2;
    private static const BIT_COUNT:uint = 4;
    private var _rawTable:ByteArray = new ByteArray();
    private var _posTable:ByteArray = new ByteArray();
    private var _lenTable:ByteArray = new ByteArray();
    private function unpackM1(input:ByteArray, output:ByteArray, key:uint):uint{
      //trace("RncDecoder::unpackM1() DEBUG!\n");

      input.endian = Endian.BIG_ENDIAN;
      var outputLow:uint;
      var outputHigh:uint;

      var inputHigh:uint;
      var inputptr:uint = input.position;
      //trace("inputptr (16bit uint) = " + input["readUnsignedShortAt"](inputptr) + ", " + inputptr + ", " + input.position);

      var unpackLen:uint = 0;
      var packLen:uint = 0;
      var counts:uint = 0;
      var crcUnpacked:uint = 0;
      var crcPacked:uint = 0;

      _bitBuff["writeShortAt"](0, BIT_BUFFER_LOW);
      _bitBuff["writeShortAt"](0, BIT_BUFFER_HIGH);
      _bitBuff["writeShortAt"](0, BIT_COUNT);

      //trace("temp = " + input["readUnsignedIntAt"](inputptr));
      if(input["readUnsignedIntAt"](inputptr) != RNC_SIGNATURE)
	return NOT_PACKED;

      inputptr += 4;
      
      // read unpacked/packed file length
      unpackLen = input["readUnsignedIntAt"](inputptr);
      //trace("unpackLen = " +  unpackLen);

      inputptr += 4;

      packLen = input["readUnsignedIntAt"](inputptr);
      //trace("packLen = " + packLen);

      inputptr += 4;

      var blocks:uint = input["readUnsignedByteAt"](inputptr + 5);
      //trace("blocks = " + blocks);

      //Read CRC's
      crcUnpacked = input["readUnsignedShortAt"](inputptr);
      //trace("crcUnpacked = " + crcUnpacked);
      inputptr += 2;
      crcPacked = input["readUnsignedShortAt"](inputptr);
      //trace("crcPacked = " + crcPacked);
      inputptr += 2;
      inputptr = (inputptr + HEADER_LEN - 16);
      //trace("inputptr = " + inputptr + ", input = " + input.position);

      //trace("crcBlock(input, inputptr, packLen) = " + crcBlock(input, inputptr,  packLen));

      if (crcBlock(input, inputptr, packLen) != crcPacked)
	return PACKED_CRC;

      inputptr = input.position + HEADER_LEN;
      _srcPtr = inputptr;
      //trace("_srcPtr (pointer 0) = " + _srcPtr + ", (16-bit uint) = " + input["readUnsignedShortAt"](_srcPtr));
      
      inputHigh = input.position + packLen + HEADER_LEN;
      outputLow = output.position;
      outputHigh = input["readUnsignedByteAt"](input.position + 16) + unpackLen + outputLow;
      //trace("inputHigh = " + inputHigh + ", outputLow = " + outputLow + ", outputHigh = " + outputHigh);
      
      _dstPtr = output.position;
      _bitBuff["writeShortAt"](0, BIT_COUNT);
      
      _bitBuff["writeShortAt"](input["readUnsignedShortAt"](_srcPtr, Endian.LITTLE_ENDIAN), BIT_BUFFER_LOW);
      //trace("_bitBuffl = " + _bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW));

      inputBits(input, 2);

      do{
	//trace("BEFORE huff tables - _srcPtr:", _srcPtr, input["readUnsignedShortAt"](_srcPtr, Endian.LITTLE_ENDIAN));

	//trace("making huff table for _rawData");
	makeHufftable(input, _rawTable);

	//trace("making huff table for _posData");
	makeHufftable(input, _posTable);

	//trace("making huff table for _lenData");
	makeHufftable(input, _lenTable);
	
	counts = inputBits(input, 16);

        //trace("AFTER huff tables - _srcPtr = " + _srcPtr + ", (16-bit uint) = " + input["readUnsignedShortAt"](_srcPtr, Endian.LITTLE_ENDIAN));

	do{
	  //trace("--counts:", counts);
	  //trace("_srcPtr:", _srcPtr);

	  var inputLength:uint = inputValue(input, _rawTable);
	  //trace("inputLength:", inputLength);
	  
	  var inputOffset:uint;

	  if(inputLength){
	    //memcpy(_dstPtr, _srcPtr, inputLength); //memcpy is allowed here
	    input.position = _srcPtr;
	    output.position = _dstPtr;
	    output.writeBytes(input, _srcPtr, inputLength);

	    /*var dstPtrString:String = "_dstPtr: ";
	    for(var i:uint = 0; i < inputLength; i++){
	      dstPtrString += output["readUnsignedByteAt"](_dstPtr + i) + ", ";
	    }
	    trace(dstPtrString);*/
	    
	    _dstPtr += inputLength;
	    //trace("_srcPtr:", _srcPtr);
	    _srcPtr += inputLength;
	    //trace("_srcPtr:", _srcPtr);

	    var a:uint = input["readUnsignedShortAt"](_srcPtr, Endian.LITTLE_ENDIAN);
	    var b:uint = input["readUnsignedShortAt"](_srcPtr + 2, Endian.LITTLE_ENDIAN);
	    
	    _bitBuff["writeShortAt"](_bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW) & ((1 << _bitBuff["readShortAt"](BIT_COUNT)) - 1), BIT_BUFFER_LOW);
	    _bitBuff["writeShortAt"](_bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW) | (a << _bitBuff["readUnsignedShortAt"](BIT_COUNT)), BIT_BUFFER_LOW);
	    _bitBuff["writeShortAt"]((a >> (16 - _bitBuff["readUnsignedShortAt"](BIT_COUNT))) | (b << _bitBuff["readUnsignedShortAt"](BIT_COUNT)), BIT_BUFFER_HIGH);
	  }
	  
	  if(counts > 1){
	    inputOffset = inputValue(input, _posTable) + 1;
	    //trace("inputOffset = " + inputOffset);

	    inputLength = inputValue(input, _lenTable) + MIN_LENGTH;
	    //trace("inputLength = " + inputLength);

	    // Don't use memcpy here! because input and output overlap.
	    //trace("---------------------");
	    var tmpPtr:uint = _dstPtr - inputOffset;
	    //trace("tmpPtr = " + tmpPtr + ", _dstPtr = " + _dstPtr + ", inputOffset = " + inputOffset + ", inputLength = " + inputLength);
	    //var outputString:String = "";
	    while (inputLength--){
	      output["writeByteAt"](output["readUnsignedByteAt"](tmpPtr), _dstPtr);
	      //outputString += output["readUnsignedByteAt"](_dstPtr) + ", ";
	      _dstPtr++;
	      tmpPtr++;
	    }
	    //trace(outputString);
	    //trace("---------------------");
	  }

	 
	}while(--counts);
      }while(--blocks);

      /*var bytesString:String = "";
      for(i = 0; i < unpackLen; i++){
        bytesString += output["readUnsignedByteAt"](i) + ", ";
      }
      trace("file:", bytesString);*/

      var temp:uint = crcBlock(output, outputLow, unpackLen);
      //trace("crcBlock(output, outputLow, unpackLen):", temp, "crcUnpacked:", crcUnpacked);
      if(temp != crcUnpacked)
	return UNPACKED_CRC;

      // all is done..return the amount of unpacked bytes
      trace("done unpacking");
      return unpackLen;
    }

    private function inputValue(input:ByteArray, table:ByteArray, debug:Boolean = false):uint{
      //trace("START -------------------------------------------------- inputValue() ");
      var values:ByteArray = new ByteArray();
      var value:uint = _bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW);

      var tablePtr:uint = 0;

      //trace("table (pointer):", tablePtr, "_srcPtr:", _srcPtr, "value:", value, "table (16-bit uint):", table["readUnsignedShortAt"](0));
      //trace("table (34) (16-bit uint) = " + table["readUnsignedShortAt"](34));

      /*table.position = 0;
      while(table.position < table.length){
	trace(table.readUnsignedShort());
      }
      table.position = 0;*/

      do{
	values["writeShortAt"]((table["readUnsignedShortAt"](tablePtr) & value), 2);
	tablePtr += 2;
	values["writeShortAt"](table["readUnsignedShortAt"](tablePtr), 0);
	tablePtr += 2;
	//trace("do -- valOne = " + values["readUnsignedShortAt"](0) + ", valTwo = " + values["readUnsignedShortAt"](2) + ", value = " + value + ", table.position = " + tablePtr);
      }while(values["readUnsignedShortAt"](0) != values["readUnsignedShortAt"](2));

      //trace("tablePtr + (0x1e * 2) = " + (tablePtr + (0x1e * 2)));
      value = table["readUnsignedShortAt"](tablePtr + (0x1e * 2));
      //trace("value = " + value);
      inputBits(input, ((value>>8) & 0x00FF));
      value &= 0x00FF;
      //trace("value = " + value);

      if(value >= 2){
	value--;
	values["writeShortAt"](inputBits(input, value & 0x00FF), 0);
	values["writeShortAt"](values["readUnsignedShortAt"](0) | (1 << value), 0);
	value = values["readUnsignedShortAt"](0);
	//trace("value = " + value);
      }

      //trace("END ---------------------------------------------------- inputValue() value:", value);
      return value;
    }

    private function makeHufftable(input:ByteArray, table:ByteArray):void{
      //var outputString:String = "";

      var tablePtr:uint;

      var bitLength:uint;
      var i:uint;
      var j:uint;
      var numCodes:uint = inputBits(input, 5);
      
      //trace("makeHufftable() numCodes:", numCodes);
      //outputString = "numCodes: " + numCodes;

      if (!numCodes)
	return;

      //outputString += ", huffLength = ";
      var huffLength:ByteArray = new ByteArray();
      for(i = 0; i < numCodes; i++){
	huffLength["writeByteAt"](inputBits(input, 4) & 0x00FF, i);
	//outputString += huffLength["readByteAt"](i) + ",";
      }

      var huffCode:ByteArray = new ByteArray();
      huffCode["writeShortAt"](0, 0);

      //outputString += " table = ";
      for(bitLength = 1; bitLength < 17; bitLength++){
	for(i = 0; i < numCodes; i++){
	  if (huffLength["readUnsignedByteAt"](i) == bitLength) {
	    table["writeShortAt"](((1 << bitLength) - 1), tablePtr);
	    //outputString += "(" + tablePtr + ") " + ((1 << bitLength) - 1) + ", ";
	    tablePtr += 2;

	    var b:uint = huffCode["readUnsignedShortAt"](0) >> (16 - bitLength);
	    var a:uint = 0;

	    for(j = 0; j < bitLength; j++){
	      a |= ((b >> j) & 1) << (bitLength - j - 1);
	    }
	    table["writeShortAt"](a, tablePtr);
	    //outputString += "(" + tablePtr + ") " + a + ", ";
	    tablePtr += 2;
	    
 	    table["writeShortAt"](((huffLength[i] << 8) | (i & 0x00FF)), (tablePtr + (0x1e * 2))); // (0x1e * 2) because we're storing shorts
	    //outputString += "(" + (tablePtr + (0x1e * 2)) + ") " + ((huffLength[i] << 8) | (i & 0x00FF));
	    //if(tablePtr + 0x1e == 34) trace("table (34) (16-bit uint) = " + table["readUnsignedShortAt"](34));

	    var tempHuffCode:uint = huffCode["readUnsignedShortAt"](0);
	    huffCode["writeShortAt"](tempHuffCode + (1 << (16 - bitLength)), 0);
	    //outputString += "(huffCode = " + huffCode["readUnsignedShortAt"](0) + "),";
	  }
	}
      }
      
      //trace(outputString);

      /*
      var outString:String = "";
      while(table.position < table.length){
	outString += table.readUnsignedByte() + ",";
      }
      trace("table:", outString);
      */

      table.position = 0;
      //trace(outputString);
    }

    private function inputBits(input:ByteArray, amount:uint):uint {
      //trace("----------------------------------------------------------- inputBits() amount:", amount);
      //trace("bit buffer low:", _bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW), "bit buffer high:", _bitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH), "bit count:", _bitBuff["readShortAt"](BIT_COUNT));
      var newBitBuff:ByteArray = new ByteArray(); // 0-1 = bitBuffl (unsigned short), 2-3 = bitBuffh (unsigned short), 4+ = _bitCount (short)
      //newBitBuff.writeBytes(_bitBuff, 0, _bitBuff.length);
      newBitBuff["writeShortAt"](_bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW), BIT_BUFFER_LOW);
      newBitBuff["writeShortAt"](_bitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH), BIT_BUFFER_HIGH);
      newBitBuff["writeShortAt"](_bitBuff["readShortAt"](BIT_COUNT), BIT_COUNT);
      //trace("bit buffer low:", newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW), "bit buffer high:", newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH), "bit count:", newBitBuff["readShortAt"](BIT_COUNT));
      
      var remBits:ByteArray = new ByteArray();  // used to store a 16-bit uint - OTT I know
      remBits["writeShortAt"](0, 0);
      var returnVal:uint;

      returnVal = ((1 << amount) - 1) & newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW);
      //trace("returnVal:", returnVal);
      newBitBuff["writeShortAt"](newBitBuff["readShortAt"](BIT_COUNT) - amount, BIT_COUNT);
      //trace("newBitCount:", newBitBuff["readShortAt"](BIT_COUNT));

      if(newBitBuff["readShortAt"](BIT_COUNT) < 0){
	newBitBuff["writeShortAt"](newBitBuff["readShortAt"](BIT_COUNT) + amount, BIT_COUNT);
	//trace("newBitCount = " + newBitBuff["readShortAt"](BIT_COUNT));

	remBits["writeShortAt"](newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH) << (16 - newBitBuff["readShortAt"](BIT_COUNT)), 0);
	//trace("remBits = " + remBits["readUnsignedShortAt"](0));

	newBitBuff["writeShortAt"](newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH) >> newBitBuff["readShortAt"](BIT_COUNT), BIT_BUFFER_HIGH);
	//trace("newBitBuffh = " + newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH));

	newBitBuff["writeShortAt"](newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW) >> newBitBuff["readShortAt"](BIT_COUNT), BIT_BUFFER_LOW);
	//trace("newBitBuffl = " + newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW));

	newBitBuff["writeShortAt"](newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW) | remBits["readUnsignedShortAt"](0), BIT_BUFFER_LOW);
	//trace("newBitBuffl = " + newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW));

	_srcPtr += 2;
	//trace("_srcPtr = " + _srcPtr);
	
	newBitBuff["writeShortAt"](input["readUnsignedShortAt"](_srcPtr, Endian.LITTLE_ENDIAN), BIT_BUFFER_HIGH);
	//trace("newBitBuffh = " + newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH));
	
	amount -= newBitBuff["readShortAt"](BIT_COUNT);
	//trace("amount = " + amount);
	
	newBitBuff["writeShortAt"](16 - amount, BIT_COUNT);
	//trace("newBitCount = " + newBitBuff["readShortAt"](BIT_COUNT));
      }
      
      //trace("remBits:", remBits["readUnsignedShortAt"](0), newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH), amount);
      remBits["writeShortAt"](newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH) << (16 - amount), 0);
      //trace("remBits:", remBits["readUnsignedShortAt"](0));


      _bitBuff["writeShortAt"](newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH) >> amount, BIT_BUFFER_HIGH);
      //trace("_bitBuffh = " + _bitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH) + ", newBitBuffh = " + newBitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH));

      _bitBuff["writeShortAt"]((newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW) >> amount) | remBits["readUnsignedShortAt"](0), BIT_BUFFER_LOW);
      //trace("_bitBuffl = " + _bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW) + ", newBitBuffl = " + newBitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW));

      _bitBuff["writeShortAt"](newBitBuff["readShortAt"](BIT_COUNT), BIT_COUNT);

      //trace("bit buffer low:", _bitBuff["readUnsignedShortAt"](BIT_BUFFER_LOW), "bit buffer high:", _bitBuff["readUnsignedShortAt"](BIT_BUFFER_HIGH), "bit count:", _bitBuff["readUnsignedShortAt"](BIT_COUNT));
      //trace("----------------------------------------------------------- inputBits() returnVal:", returnVal);
      return returnVal;
    }

    private function crcBlock(block:ByteArray, position:uint, size:uint):uint{
      var crc:uint = 0;

      //make a uint8* to crc_table
      var crcTable:uint = 0;
      var tmp:uint;
      var i:uint;

      for (i = 0; i < size; i++) {
	tmp = block["readUnsignedByteAt"](position++);
	crc ^= tmp;
	tmp = (crc >> 8) & 0x00FF;
	crc &= 0x00FF;
	//_crcTable.position = crc << 1;
	crc = _crcTable["readUnsignedShortAt"](crc << 1);
	crc ^= tmp;
      }
      //trace("block end, crc:", crc);
      return crc;
    }

	// testing speed
    private function readUnsignedInt24bit(byteArray:ByteArray, position:uint):uint{
      var tempArray:ByteArray = new ByteArray();
      tempArray.endian = Endian.LITTLE_ENDIAN;
      byteArray.position = position;
      byteArray.readBytes(tempArray, 0, 3);
      tempArray.position = 3;
      tempArray.writeByte(0);

      tempArray.position = 0;
      return tempArray.readUnsignedInt();
      
      /*
      (b[2] << 16) | (b[1] << 8) | (b[0])
      */
    }

  }

}