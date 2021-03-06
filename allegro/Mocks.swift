//
//  Mocks.swift
//  allegro
//
//  Created by Nikhil Lele on 1/23/17.
//  Copyright © 2017 gigaunicorn. All rights reserved.
//

import Rational

let mocks: [Part] = [parsePart(CMajor, key: Key.cMajor), parsePart(DMajor, key: Key.cMajor)]

private let CMajor = [
    "4 C 4 n",
    "4 D 4 n",
    "4 E 4 n",
    "4 F 4 n",
    "4 G 4 n",
    "4 A 4 n",
    "4 B 4 n",
    "4 C 5 n",
    "8 C 4 n",
    "8 D 4 n",
    "8 E 4 n",
    "8 F 4 n",
    "8 G 4 n",
    "8 A 4 n",
    "8 B 4 n",
    "8 C 5 n"
]

private let DMajor = [
    "4 D 4 n",
    "4 E 4 n",
    "4 F 4 s", // display
    "4 G 4 n",
    "4 A 4 n",
    "4 B 4 n", // display
    "4 C 5 s",
    "4 D 5 n",
    "8 D 4 n",
    "8 E 4 n", // display
    "8 F 4 s",
    "8 G 4 n",
    "8 A 4 n",
    "8 B 4 n",
    "8 C 5 s", // display
    "8 D 5 n"
]

private let DMajorRun = [
    "8 D 4 n", // 0 -> no display
    "8 E 4 n", // 1 -> no display
    "8 F 4 s", // 2 -> display (no key hit, no prev, not natural)
    "8 G 4 n", // 3 -> no display
    "8 F 4 s", // 4 -> no display (no key hit, has prev, same acc as prev)
    "8 E 4 n", // 5 -> no display
    "8 A 4 n", // 6 -> no display
    "8 B 4 n", // 7 -> no display
    "8 C 5 s", // 0 -- new measure -> display
    "8 D 5 n", // 1 -> no display
    "8 C 5 s", // 2 -> no display (has prev)
    "8 B 4 n", // 3 -> no display
    "8 C 4 n", // 4 -> display (no key hit, has prev, diff acc than prev)
    "8 F 4 s", // 5 -> display
    "8 E 4 n", // 6 -> no display
    "8 D 4 n"  // 7 -> no display
]

// KeyDTest will be put in the key of D
private let KeyDTest = [
    "8 D 8 n", // 0 -> no display
    "8 E 8 n", // 1 -> no display
    "8 F 8 s", // 2 -> no display (key hit, no prev, same acc as key)
    "8 F 8 n", // 3 -> no display (key hit, prev, same acc as prev)
    "8 A 8 n", // 4 -> no display
    "8 G 8 n", // 5 -> no display
    "8 F 8 n", // 6 -> display (diff than key hit)
    "8 E 8 n", // 7 -> no display
    // ##### new measure
    "8 G 8 n", // 0 -> no display
    "8 F 8 n", // 1 -> display (diff than key hit)
    "8 G 8 n", // 2 -> no display
    "8 F 8 n", // 3 -> no display (same as prev)
    "8 G 8 n", // 4 -> no display
    "8 F 8 s", // 5 -> display (key hit, prev, diff than prev)
    "8 C 8 n", // 6 -> display (key hit, no prev, diff acc than key)
    "8 C 8 n"  // 7 -> no display (same as prev)
]

// comments are for ideal beam
private let BeamTest = [
    "8 E 4 n", // beam 0
    "8 F 4 n", // beam 0
    "8 E 5 n", // beam 1
    "8 D 5 n", // beam 1
    "8 A 4 n", // beam 2
    "8 A 4 n", // beam 2
    "8 B 4 n", // beam 3
    "8 C 5 n", // beam 3
    
    "16 G 4 n", // beam 0
    "16 G 4 n", // beam 0
    "16 G 4 n", // beam 1
    "16 G 4 n", // beam 1
    "8 G 4 n", // beam 2
    "8 G 4 n", // beam 2
    "16 E 5 n", // beam 3
    "16 E 5 n", // beam 3
    "16 E 5 n", // beam 4
    "16 E 5 n", // beam 4
    "8 E 5 n", // beam 5
    "8 E 5 n", // beam 5
    
    "4 F 4 n", // no beam
    "8 G 4 n", // beam 0
    "8 A 4 n", // beam 0
    "4 B 4 n", // no beam
    "8 C 4 n", // beam 1
    "8 C 4 n", // beam 1
]

// 4 C 4 n -> quarternote, C, octave 4, natural
private func parse(_ input: String) -> Note {
    let comp = input.components(separatedBy: " ")
    
    var value: Note.Value
    switch comp[0] {
    case "1": value = .whole
    case "2": value = .half
    case "4": value = .quarter
    case "8": value = .eighth
    case "16": value = .sixteenth
    default: value = .quarter
    }
    
    var letter: Note.Letter
    switch comp[1] {
    case "A": letter = .A
    case "B": letter = .B
    case "C": letter = .C
    case "D": letter = .D
    case "E": letter = .E
    case "F": letter = .F
    case "G": letter = .G
    default: letter = .C
    }
    
    var octave: Int = 5
    if let parsedOctave: Int = Int(comp[2]) {
        octave = parsedOctave
    }
    
    var accidental: Note.Accidental
    switch comp[3] {
    case "ss": accidental = .doubleSharp
    case "s": accidental = .sharp
    case "n": accidental = .natural
    case "f": accidental = .flat
    case "ff": accidental = .doubleFlat
    default: accidental = .natural
    }
    
    return Note(value: value, letter: letter, octave: octave, accidental: accidental, rest: false)
}

/*
 v2: 
 private func parsePart(_ partArray: [String], key: Key) -> Part {
 mock parts should have keys for testing
 */

private func parsePart(_ partArray: [String], key: Key) -> Part {
    let part = Part()
    for noteString in partArray {
        part.appendNote(note: parse(noteString))
    }
    return part
}

func mockPart(_ name: String) -> Part {
    
    switch name {
    case "CMajor":
        return parsePart(CMajor, key: Key.cMajor)
        
    case "DMajor":
        return parsePart(DMajor, key: Key.cMajor)
    
    case "DMajorRun":
        return parsePart(DMajorRun, key: Key.cMajor)
        
    case "KeyDTest":
        return parsePart(KeyDTest, key: Key.dMajor)
        
    case "BeamTest":
        return parsePart(BeamTest, key: Key.cMajor)
        
    default:
        let part = Part()
        part.appendNote(note: parse("1 B 4 n"))
        return part
    }
}
