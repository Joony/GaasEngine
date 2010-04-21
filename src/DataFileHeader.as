package{

  import flash.utils.ByteArray;
  import flash.utils.Endian;

  public class DataFileHeader{

    public var flag:uint; // bit 0: set for colour data, clear for not                                                                                                                                                                      
    // bit 1: set for compressed, clear for uncompressed                                                                                                                                                                                    
    // bit 2: set for 32 colours, clear for 16 colours                                                                                                                                                                                      
    public var s_x:uint;
    public var s_y:uint;
    public var s_width:uint;
    public var s_height:uint;
    public var s_sp_size:uint;
    public var s_tot_size:uint;
    public var s_n_sprites:uint;
    public var s_offset_x:int;
    public var s_offset_y:int;
    public var s_compressed_size:uint;

    public function DataFileHeader(file:ByteArray){
      flag = file.readUnsignedShort();
      s_x = file.readUnsignedShort();
      s_y = file.readUnsignedShort();
      s_width = file.readUnsignedShort();
      s_height = file.readUnsignedShort();
      s_sp_size = file.readUnsignedShort();
      s_tot_size = file.readUnsignedShort();
      s_n_sprites = file.readUnsignedShort();
      s_offset_x = file.readShort();
      s_offset_y = file.readShort();
      s_compressed_size = file.readUnsignedShort();
    }

    public function readHeader():ByteArray{
      var header:ByteArray = new ByteArray();
      header.endian = Endian.BIG_ENDIAN;
      header.writeShort(flag);
      header.writeShort(s_x);
      header.writeShort(s_y);
      header.writeShort(s_width);
      header.writeShort(s_height);
      header.writeShort(s_sp_size);
      header.writeShort(s_tot_size);
      header.writeShort(s_n_sprites);
      header.writeShort(s_offset_x);
      header.writeShort(s_offset_y);
      header.writeShort(s_compressed_size);
      return header;
    }

  }

}
