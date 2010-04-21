(function():void{
  include 'addMethodsTo.as';
  addMethodsTo(ByteArray, {
    writeShortAt:function(value:int, position:uint, endian:String = "bigEndian"):void{
      var currentEndian:String = this.endian;
      this.endian = endian;
      var currentPosition:uint = this.position;
      this.position = position;
      this.writeShort(value);
      this.position = currentPosition;
      this.endian = currentEndian;
    },
    readShortAt:function(position:uint, endian:String = "bigEndian"):int{
      var currentEndian:String = this.endian;
      this.endian = endian;
      var currentPosition:uint = this.position;
      this.position = position;
      var short:int = this.readShort();
      this.position = currentPosition;
      this.endian = currentEndian;
      return short;
    },
    readUnsignedShortAt:function(position:uint, endian:String = "bigEndian"):uint{
      var currentEndian:String = this.endian;
      this.endian = endian;
      var currentPosition:uint = this.position;
      this.position = position;
      // XXX: a horrible hack to get the file to be uncompressed completely.  Apparently there's a slight overlap.
      while(this.length - this.position < 2){
        this.position = this.length;
        this.writeByte(0);
        this.position = position;
      }
      this.position = position;
      var ushort:uint = this.readUnsignedShort();
      this.position = currentPosition;
      this.endian = currentEndian;
      return ushort;
    },
    writeByteAt:function(value:int, position:uint):void{
      var currentPosition:uint = this.position;
      this.position = position;
      this.writeByte(value);
      this.position = currentPosition;
    },
    readByteAt:function(position:uint):int{
      var currentPosition:uint = this.position;
      this.position = position;
      var byte:uint = this.readByte();
      this.position = currentPosition;
      return byte;
    },
    readUnsignedByteAt:function(position:uint):uint{
      var currentPosition:uint = this.position;
      this.position = position;
      var ubyte:uint = this.readUnsignedByte();
      this.position = currentPosition;
      return ubyte;
    },
    writeIntAt:function(value:int, position:uint):void{
      var currentPosition:uint = this.position;
      this.position = position;
      this.writeInt(value);
      this.position = currentPosition;
    },
    readUnsignedIntAt:function(position:uint, endian:String = "bigEndian"):uint{
      var currentEndian:String = this.endian;
      this.endian = endian;
      var currentPosition:uint = this.position;
      this.position = position;
      var uInt:uint = this.readUnsignedInt();
      this.position = currentPosition;
      this.endian = currentEndian;
      return uInt;
    }
  });
})();
