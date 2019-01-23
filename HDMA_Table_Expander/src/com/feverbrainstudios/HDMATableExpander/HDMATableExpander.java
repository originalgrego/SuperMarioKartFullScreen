package com.feverbrainstudios.HDMATableExpander;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;


/**
 *  Expands Super Mario Kart's hdma tables by interpolation. Super quick and dirty utility.
 */
public class HDMATableExpander {
	
	public static void main(String[] arg) {
		new HDMATableExpander().expand(arg[0], arg[1], arg[2], Integer.valueOf(arg[3]), Integer.valueOf(arg[4]));
		System.exit(0);
	}

	private void expand(String tableFileName, String tableOutLo, String tableOutHi, int hdmaTableEntryLength, int hdmaTableEntryCap) {
		try {
			final byte[] table = Files.readAllBytes(Paths.get(tableFileName));
			final byte[] loTable = new byte[table.length];
			final byte[] hiTable = new byte[table.length];

			final int halfTableEntryLength = hdmaTableEntryLength / 2;

			int count = 0;
			int loTableCount = 0;
			int hiTableCount = 0;
			for (int x = 0; x < table.length; x += 2) {
				byte firstByte = table[x];
				byte secondByte = table[x + 1];
				short combined = getShort(firstByte, secondByte);
				short combined2 = count < hdmaTableEntryLength - 2 ? getShort(table[x+2], table[x+3]) : combined;
				short dithered = (short) ((combined + combined2) / 2);
				final byte lowerDithered = getLowerByte(dithered);
				final byte upperDithered = getUpperByte(dithered);
				if (count < halfTableEntryLength) {
					loTable[loTableCount] = firstByte;
					loTableCount ++;
					loTable[loTableCount] = secondByte;
					loTableCount ++;
					loTable[loTableCount] = lowerDithered;
					loTableCount ++;
					loTable[loTableCount] = upperDithered;
					loTableCount ++;
				} else if (count < hdmaTableEntryLength) {
					hiTable[hiTableCount] = firstByte;
					hiTableCount ++;
					hiTable[hiTableCount] = secondByte;
					hiTableCount ++;
					hiTable[hiTableCount] = lowerDithered;
					hiTableCount ++;
					hiTable[hiTableCount] = upperDithered;
					hiTableCount ++;
				} else {
					loTable[loTableCount] = 0;
					loTableCount ++;
					hiTable[hiTableCount] = 0;
					hiTableCount ++;
					loTable[loTableCount] = 0;
					loTableCount ++;
					hiTable[hiTableCount] = 0;
					hiTableCount ++;
				}
				
				count += 2;
				
				if (count >= hdmaTableEntryCap) {
					count = 0;
				}
			}

			final Path tableOutLoPath = Paths.get(tableOutLo);
			Files.deleteIfExists(tableOutLoPath);
			Files.write(tableOutLoPath, loTable, StandardOpenOption.CREATE);
			
			final Path tableOutHiPath = Paths.get(tableOutHi);
			Files.deleteIfExists(tableOutHiPath);
			Files.write(tableOutHiPath, hiTable, StandardOpenOption.CREATE);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	private byte getUpperByte(short dithered) {
		return (byte) ((dithered & 0xFF00) >> 8); 
	}

	private byte getLowerByte(short dithered) {
		return (byte) (dithered & 0xFF);
	}

	private short getShort(byte firstByte, byte secondByte) {
		short firstByteShort = (short) ((short) (firstByte) & 0xFF);
		short secondByteShort = (short) ((short) (secondByte) & 0xFF); 
		short secondByteExpanded = (short) (secondByteShort << 8);
		return (short) (secondByteExpanded + firstByteShort);
	}
}
