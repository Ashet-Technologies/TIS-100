using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Collections.Generic;

class Program
{	
	static Dictionary<string, int> labels = new Dictionary<string, int>();
	static Dictionary<int, Tuple<int, string>> patches = new Dictionary<int, Tuple<int, string>>();
	static List<byte> code = new List<byte>();
	
	static readonly Regex matcher = new Regex(
		@"^\s*(?:(?<label>[A-Z]+):)?\s*(?:(?<mnemonic>NOP|HLT|MOV|SWP|SAV|ADD|SUB|NEG|JMP|JEZ|JNZ|JGZ|JLZ|JRO)(?:\s+(?<arg1>LEFT|RIGHT|UP|DOWN|ACC|NIL|PORT[0-7]|-?\d?\d?\d))?(?:\s+(?<arg2>LEFT|RIGHT|UP|DOWN|ACC|NIL|PORT[0-7]))?(?:\s+(?<ref>[A-Z]+))?)?\s*(?<comment>#.*)?$", 
		RegexOptions.Compiled);
			
	static int Main(string[] args)
	{
		if(args.Length != 1)
		{
			Console.WriteLine("Usage: asm [fileName]");
			return 0;
		}
		
		var lines = File.ReadAllLines(args[0]);
		
		for(int i = 0; i < lines.Length; i++)
		{
			var line = lines[i].ToUpper().Trim();
			try {
				Assemble(i + 1, line);
			} catch(InvalidOperationException ex) {
				Console.Error.WriteLine(
					"{0}:{1}: {2}",
					args[0],
					i + 1,
					ex.Message);
				continue;
			}
		}
	
		foreach(var lbl in labels)
			Console.WriteLine("{0}: {1}", lbl.Key, lbl.Value);
	
		foreach(var patch in patches)
		{
			try {
				code[patch.Key] = (byte)labels[patch.Value.Item2];
			} catch(KeyNotFoundException) {
				Console.Error.WriteLine(
					"{0}:{1}: Label {2} not found!",
					args[0],
					patch.Value.Item1,
					patch.Value.Item2);
			}
		}
	
		for(int i = 0; i < code.Count; i++)
		{
			if(i > 0 && (i % 16) == 0)
				Console.WriteLine();
			Console.Write("{0:X2} ", code[i]);
		}
		Console.WriteLine();
	
		return 0;
	}
	
	static void Assemble(int lineNo, string line)
	{
		var match = matcher.Match(line);
		if(!match.Success)
		{
			throw new InvalidOperationException("Invalid line!");
		}
		
		var groups = match.Groups;
		var label = groups["label"];
		var mnemonic = groups["mnemonic"];
		var arg1 = groups["arg1"];
		var arg2 = groups["arg2"];
		var lblref = groups["ref"];
		var comment = groups["comment"];
		
		// Add labels for sure
		if(label.Length > 0)
		{
			labels.Add(label.Value, code.Count);
		}
		
		// Only continue when mnemonics are here
		if(mnemonic.Length == 0)
		{
			return;
		}
		
		byte? IMM = null;
		{
			sbyte val;
			if(sbyte.TryParse(arg1.Value, out val))
				IMM = (byte)val;
		}
		
		Register src = Register.Invalid;
		Register dst = Register.Invalid;
		
		if(Enum.TryParse<Register>(arg1.Value, out src) == false)
			src = Register.Invalid;
		if(Enum.TryParse<Register>(arg2.Value, out dst) == false)
			dst = Register.Invalid;
		
		string target = null;
		if(lblref.Length > 0 || arg1.Length > 0)
		{
			if(lblref.Length > 0)
				target = lblref.Value;
			else {
				target = arg1.Value;
				if(IMM != null)
					target = null;
			}
		}
		
		switch(mnemonic.Value)
		{
			case "NOP":
				code.Add(0x00);
				break;
			case "SWP":
				code.Add(0x01);
				break;
			case "SAV":
				code.Add(0x02);
				break;
			case "ADD":
				if (IMM != null) {
					// ADD <IMM>        | 0x0A *IMM*
					code.Add(0x0A);
					code.Add((byte)IMM);
				} else if(src != Register.Invalid) {
					// ADD <SRC>        | 0x*S*3
					code.Add((byte)(((int)src) << 4 | 0x03));
				} else {
					throw new InvalidOperationException("Invalid operand to ADD.");
				}
				break;
			case "SUB":
				if (IMM != null) {
					// SUB <IMM>        | 0x0B *IMM*
					code.Add(0x0B);
					code.Add((byte)IMM);
				} else if(src != Register.Invalid) {
					// SUB <SRC>        | 0x*S*4
					code.Add((byte)(((int)src) << 4 | 0x04));
				} else {
					throw new InvalidOperationException("Invalid operand to SUB.");
				}
				break;
			case "NEG":
				code.Add(0x05);
				break;
			case "JRO":
				if (IMM != null) {
					// JRO <IMM>        | 0x0D *IMM* 
					code.Add(0x0D);
					code.Add((byte)IMM);
				} else if(src != Register.Invalid) {
					// JRO <SRC>        | 0x*S*6
					code.Add((byte)(((int)src) << 4 | 0x06));
				} else {
					throw new InvalidOperationException("Invalid operand to JRO.");
				}
				break;
			case "HLT":
				code.Add(0x07);
				break;
			case "MOV":
				if (IMM != null) {
					// MOV <IMM>, <DST> | 0x*D*9 *IMM*
					code.Add((byte)(((int)dst) << 4 | 0x09));
					code.Add((byte)IMM);
				} else if(src != Register.Invalid) {
					// MOV <SRC>, <DST> | 0x*D*8 0x0*S*
					code.Add((byte)(((int)dst) << 4 | 0x08));
					code.Add((byte)src);
				} else {
					throw new InvalidOperationException("Invalid operand to MOV.");
				}
				break;
			case "JMP":
				if(target == null) throw new InvalidOperationException("Requires label name!");
				code.Add(0x0C);
				code.Add(0);
				patches.Add(code.Count - 1, Tuple.Create(lineNo, target));
				break;
			case "JEZ":
				if(target == null) throw new InvalidOperationException("Requires label name!");
				code.Add(0x1C);
				code.Add(0);
				patches.Add(code.Count - 1, Tuple.Create(lineNo, target));
				break;
			case "JNZ":
				if(target == null) throw new InvalidOperationException("Requires label name!");
				code.Add(0x2C);
				code.Add(0);
				patches.Add(code.Count - 1, Tuple.Create(lineNo, target));
				break;
			case "JGZ":
				if(target == null) throw new InvalidOperationException("Requires label name!");
				code.Add(0x3C);
				code.Add(0);
				patches.Add(code.Count - 1, Tuple.Create(lineNo, target));
				break;
			case "JLZ":
				if(target == null) throw new InvalidOperationException("Requires label name!");
				code.Add(0x4C);
				code.Add(0);
				patches.Add(code.Count - 1, Tuple.Create(lineNo, target));
				break;
		}
	}
	
	enum Register : byte
	{
		Invalid = 0x0,
		ACC = 0x1,
		NIL = 0x2,
		PORT0 = 0x8,
		PORT1 = 0x9,
		PORT2 = 0xA,
		PORT3 = 0xB,
		PORT4 = 0xC,
		PORT5 = 0xD,
		PORT6 = 0xE,
		PORT7 = 0xF,
		LEFT  = PORT0,
		UP    = PORT1,
		RIGHT = PORT2,
		DOWN  =  PORT3,
	}
}