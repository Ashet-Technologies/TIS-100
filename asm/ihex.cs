using System;
using System.Linq;

public class HexRecord
{
	private ushort loadOffset;
	private byte[] payload;
	
	public static readonly HexRecord EndOfFile = new HexRecord(
		RecordType.EndOfFile,
		0,
		new byte[0]);
	
	public HexRecord(RecordType type, byte[] data)
	{
		this.Type = type;
		this.Data = data;
	}
	
	public HexRecord(RecordType type, int loadOffset, byte[] data) : 
		this(type, data)
	{
		this.LoadOffset = loadOffset;
	}
	
	public RecordType Type { get; set; }
	
	public int LoadOffset {
		get { return this.loadOffset; }
		set {
			if(value < UInt16.MinValue)
				throw new ArgumentOutOfRangeException();
			if(value > UInt16.MaxValue)
				throw new ArgumentOutOfRangeException();
			this.loadOffset = (ushort)value;
		}
	}
	
	public byte[] Data {
		get { return this.payload; }
		set {
			if(value == null)
				throw new ArgumentNullException();
			if(value.Length > Byte.MaxValue) 
				throw new ArgumentOutOfRangeException();
			this.payload = value;
		}
	}
	
	public int Length => (ushort)this.payload.Length;
	
	public byte Checksum {
		get {
			byte checksum = 0;
			for(int i = 0; i < this.payload.Length; i++) {
				checksum += this.payload[i];
			}
			checksum += (byte)this.Type;
			checksum += (byte)(this.loadOffset >> 8);
			checksum += (byte)(this.loadOffset >> 0);
			checksum += (byte)(this.Length >> 0);
			checksum ^= 0xFF;
			checksum += 1;
			return checksum;
		}
	}
	
	public override string ToString() =>
		string.Format(
			":{0:X2}{1:X4}{2:X2}{3}{4:X2}",
			this.Length,
			this.LoadOffset,
			(int)this.Type,
			string.Join("", this.payload.Select(b => b.ToString("X2"))),
			this.Checksum);
}

public enum RecordType : byte
{
	Data = 0,
	EndOfFile = 1,
	ExtendedSegmentAddress = 2,
	StartSegmentAddress = 3,
	ExtendedLinearAddress = 4,
	StartLinearAddress = 5,
}