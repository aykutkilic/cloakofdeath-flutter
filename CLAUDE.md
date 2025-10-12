# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains **Cloak of Death**, a classic text adventure game originally written in Atari BASIC for 8-bit Atari computers. The project is a retro gaming preservation archive with the game's source code, binary cassette format, solution walkthrough, and visual game maps.

## File Structure

- `Cloak of Death.bas` - Original Atari BASIC source code (UTF-8 text format)
- `Cloak of Death.cas` - Binary cassette tape image for Atari emulators
- `solution.txt` - Complete walkthrough with step-by-step commands to win the game
- `cas_dump.txt` - Hexadecimal/ASCII dump of the cassette file structure
- `Cloak of death.drawio.png` / `.svg` - Visual game map diagrams
- `README.txt` - Notes about tape loading behavior

## Game Architecture

**Cloak of Death** is a haunted house escape text adventure with:

- **27 locations** (rooms numbered 1-27, with location 27 being the exit/win condition)
- **53 objects** tracked in array `P(53)` indicating object locations (0=not present, -1=in inventory, 1-27=room number)
- **Text-based parser** accepting verb-noun commands (e.g., "GET CANDLE", "OPEN DOOR")
- **State flags** (F1-F10) controlling game progression and puzzle states
- **Inventory system** with 6-item carrying capacity (tracked via `IN` variable)
- **Dynamic lighting mechanic** requiring a lit candle to see in many locations
- **Timer-based candle mechanic** (burns out after ~200 moves via `LC` counter)
- **Multiple puzzles** involving keys, locked doors, exorcism ritual, and item combinations

### Key Technical Details

The BASIC code uses:
- `USR()` calls for custom machine language routines (FIND, DRAW, CLS)
- Compressed data storage using character encoding (CHR$()+127 offset)
- String arrays for object descriptions (`O$`), location descriptions (`L$`), exits (`E$`)
- GOTO-based command dispatch (line 990: `GOTO (V*200)+800`)
- Cassette tape I/O for save/load game functionality

### Critical Game Objects

- Objects 4, 13, 16: Bible, crucifix, holy water (needed for final exorcism)
- Object 9: Lit candle (essential for navigation in dark rooms)
- Object 23: Matches (used to light candles)
- Objects 19, 20: Keys for unlocking doors
- Object 31: "Cloak" entity that must be exorcised to win

## Development Notes

This is a **preservation/archive project** of retro gaming history. When working with this codebase:

- The BASIC syntax is Atari BASIC specific (not standard BASIC)
- Line numbers are intentionally sparse to allow insertions
- Machine language routines are embedded and called via USR()
- The cassette format uses Atari FSK encoding (viewable via cas_reader.py tool)
- Character encoding uses special Atari ATASCII characters (visible as Unicode symbols in the .bas file)

When analyzing or modifying the game:
- Preserve the line number structure
- Maintain compatibility with Atari BASIC syntax
- Test changes in an Atari 8-bit emulator (e.g., Altirra, Atari800)
- The game uses memory addresses and PEEK/POKE commands specific to Atari hardware
