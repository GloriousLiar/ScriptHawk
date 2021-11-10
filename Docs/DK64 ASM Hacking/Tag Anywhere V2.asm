// Donkey Kong 64 - Tag Anywhere (V2) (U)
// Made with love by Isotarge
// With help from Tom Ballaam, 2dos, Mittenz, retroben, Kaze Emanuar, SubDrag, runehero123, Skill

// See https://pastebin.com/m82XBvYm for more info & download

// Note: Eventually we'll use Mittenz' Mr. Patcher to streamline this process dramatically
// https://github.com/MittenzHugg/Mr.Patcher
// It's very manual and hacky for now but it will improve

// To turn this patch into a ROM hack:

// You'll need:
// - DK64 US ROM
// - BizHawk + ScriptHawk
// - Hex editor
// - gedecompress
// - Decompressed DK64 ROM files (specifically 0113F0_ZLib.bin)
// - n64crc

// Method:
// TODO: Make this more readable and generalize it
// TODO: This might be slightly outdated now with version 2
// Use ScriptHawk's loadASMPatch() to assemble this file into vanilla DK64 US running RDRAM
// Copy the 4 patched bytes at the hook location into notepad or a hex editor, 0x60B0DC in RDRAM
// Find the original hook location using surrounding bytes in the decompressed version of 0113F0_ZLib.bin
// Overwrite the hook with the patched version
// Recompress the patched 0113F0_ZLib.bin with gedecompress
// If the recompressed 0113F0_ZLib.bin is smaller or the same size as the original (fits between 113F0 and C29D4 in ROM), overwrite it in ROM
// If it's bigger, you're out of luck for now (will be possible when tools & knowledge improve), try and decrease the entropy of the patch so it's smaller when recompressed
// Open BizHawk's hex editor and navigate to the main code in RDRAM at 0xED30 (chews up the missing Expansion Pak message)
// Copy all the patched bytes upto the 0x00000000 (NOP) after the return
// Overwrite the same bytes in ROM (it's uncompressed, near the start)
// Navigate to 0x3154 in ROM and replace with 0x00000000, this disables the security(or is it error?) checks on compressed files
// Save the patched ROM
// Fix the patched ROM's CRCs with n64crc

[NewlyPressedControllerInput]: 0x807ECD66
[ControllerInput]: 0x80014DC4
[HUDPointer]: 0x80754280
[KongObjectPointer]: 0x807FBB4C
[MysteryObjectPointer]: 0x807FC924
[InCutscene]: 0x807444EC
[NextMap]: 0x807444E4

[MysteryWriteOffset]: 0x29C
[CurrentCharacter]: 0x36F
[L_Button]: 0x0020
[D_Down]: 0x0400
[D_Left]: 0x0200
[D_Right]: 0x0100

.org 0x8060B0DC // retroben's hook
J       Start

.org 0x8000DE88 // In the Expansion Pak pic, TODO: Better place to put this
Start:

// Check if we're in a cutscene
LB      t2, @InCutscene
BNEZ    t2, Return
NOP

// Is the game loading?
// If so, update the ExplicitDisableMap byte and then return
LW      t2, 0x807FD888
BNEZ    t2, CheckMapDisable
NOP

// Check if we're in a map that's explicitly been disabled
LB      t2, ExplicitDisableMap
BNEZ    t2, Return
NOP

// Check if there's any collectible counters updating
// This prevents wrong collection
LW      t2, @HUDPointer

LW      t3, 0x20(t2) // CB
BNEZ    t3, Return
NOP
LW      t3, 0x50(t2) // Banana Coin
BNEZ    t3, Return
NOP
LW      t3, 0x1A0(t2) // GB Count (Character) // Note: We can't add the bottom counter because it's always shown in lobbies
BNEZ    t3, Return
NOP
LW      t3, 0x200(t2) // Banana Medal
BNEZ    t3, Return
NOP
LW      t3, 0x260(t2) // Blueprint
BNEZ    t3, Return
NOP
LW      t3, 0x290(t2) // Coloured Bananas?
BNEZ    t3, Return
NOP
LW      t3, 0x2C0(t2) // Banana Coins?
BNEZ    t3, Return
NOP

// Check if L is pressed/held
LH      t2, @ControllerInput

ANDI    t3, t2, @L_Button
BEQZ    t3, Return
NOP

ANDI    t3, t2, @D_Down
BEQZ    t3, DPADCheck
NOP
LI      t3, 1
SB      t3, 0x807552E0

DPADCheck:
// Check if DPAD-Left is newly pressed
LH      t2, @NewlyPressedControllerInput
ANDI    t3, t2, @D_Left
BEQZ    t3, CheckDRight
NOP

// Kong--
LI      t4, -1
B       UpdateKong
NOP

// Check if DPAD-Right is newly pressed
CheckDRight:
ANDI    t3, t2, @D_Right
BEQZ    t3, Return
NOP

// Kong++
LI      t4, 1

// Update Player Actor with new character value
UpdateKong:
LW      t2, @KongObjectPointer

// Check whether we're in a movement state where tagging should be disabled
// Load current movement state
LB      t0, 0x154(t2)
// Load the start of the array
LA      t1, ExplicitDisableMovementStates

// Loop through and check for movementState == disabledMovementState or null terminator
MovementCheckLoop:
LB      t3, 0(t1)
BEQ     t0, t3, Return
NOP
BNEZ    t3, MovementCheckLoop
ADDIU   t1, t1, 1

// We're in a movement state that allows tagging!
LB      t3, @CurrentCharacter(t2)

// Kong += t4
ADD     t3, t3, t4

// If Kong == 1 { Kong = 6 }
LI      t4  1
BNE     t3, t4, HighKongCheck
NOP
LI      t3, 6
B       WriteCharacter
NOP

// If Kong == 7 { Kong = 2 }
HighKongCheck:
LI      t4  7
BNE     t3, t4, WriteCharacter
NOP
LI      t3, 2

WriteCharacter:
SB      t3, @CurrentCharacter(t2)

// Update Mystery Object (cause a tag)
LW      t2, @MysteryObjectPointer
LI      t3, 0x003B
SH      t3, @MysteryWriteOffset(t2)

Return:
J       0x8060B0E4
NOP

CheckMapDisable:
// Little bit of salami
LI      t6, 0x8075E5DC
LI      t0, 0x49534F20
SW      t0, 0(t6)
LI      t0, 0x574F5A20
SW      t0, 4(t6)
LI      t0, 0x45524500
SW      t0, 8(t6)

LW      t0, @NextMap

// Load the start of the array
LA      t2, ExplicitDisableMaps

// Loop through and check for map == nextmap or null terminator
MapCheckLoop:
LB      t3, 0(t2)
BEQ     t0, t3, MapMatchFound
NOP
BNEZ    t3, MapCheckLoop
ADDIU   t2, t2, 1

// No match found
SB      r0, ExplicitDisableMap
B       Return
NOP

MapMatchFound:
LI      t2, 1
SB      t2, ExplicitDisableMap
B       Return
NOP

ExplicitDisableMap:
.byte 0 // We'll check this when the map loads to save looping through the array each frame

ExplicitDisableMaps:
//.byte 0 // Test Map
.byte 1 // Funky's Store
.byte 2 // DK Arcade
.byte 3 // K. Rool Barrel: Lanky's Maze // TODO: Test
//.byte 4 // Jungle Japes: Mountain
.byte 5 // Cranky's Lab
.byte 6 // Jungle Japes: Minecart // TODO: Test
//.byte 7 // Jungle Japes
//.byte 8 // Jungle Japes: Army Dillo
.byte 9 // Jetpac
.byte 10 // Kremling Kosh! (very easy) // TODO: Test
.byte 11 // Stealthy Snoop! (normal, no logo)
//.byte 12 // Jungle Japes: Shell
//.byte 13 // Jungle Japes: Lanky's Cave
.byte 14 // Angry Aztec: Beetle Race // Note: Softlock at the end if enabled?
.byte 15 // Snide's H.Q.
//.byte 16 // Angry Aztec: Tiny's Temple
//.byte 17 // Hideout Helm
.byte 18 // Teetering Turtle Trouble! (very easy)
//.byte 19 // Angry Aztec: Five Door Temple (DK)
//.byte 20 // Angry Aztec: Llama Temple
//.byte 21 // Angry Aztec: Five Door Temple (Diddy)
//.byte 22 // Angry Aztec: Five Door Temple (Tiny)
//.byte 23 // Angry Aztec: Five Door Temple (Lanky)
//.byte 24 // Angry Aztec: Five Door Temple (Chunky)
.byte 25 // Candy's Music Shop
//.byte 26 // Frantic Factory
.byte 27 // Frantic Factory: Car Race // TODO: Test
//.byte 28 // Hideout Helm (Level Intros, Game Over) // Note: Handled by cutscene check
//.byte 29 // Frantic Factory: Power Shed
//.byte 30 // Gloomy Galleon
//.byte 31 // Gloomy Galleon: K. Rool's Ship // TODO: Test
//.byte 32 // Batty Barrel Bandit! (easy)
//.byte 33 // Jungle Japes: Chunky's Cave
//.byte 34 // DK Isles Overworld
//.byte 35 // K. Rool Barrel: DK's Target Game // TODO: Test
//.byte 36 // Frantic Factory: Crusher Room
.byte 37 // Jungle Japes: Barrel Blast // Note: The barrels don't work as other kongs so not much point enabling it on this map
//.byte 38 // Angry Aztec
//.byte 39 // Gloomy Galleon: Seal Race
//.byte 40 // Nintendo Logo // Note: Handled by cutscene check?
.byte 41 // Angry Aztec: Barrel Blast
.byte 42 // Troff 'n' Scoff
//.byte 43 // Gloomy Galleon: Shipwreck (Diddy, Lanky, Chunky)
//.byte 44 // Gloomy Galleon: Treasure Chest
//.byte 45 // Gloomy Galleon: Mermaid
//.byte 46 // Gloomy Galleon: Shipwreck (DK, Tiny)
//.byte 47 // Gloomy Galleon: Shipwreck (Lanky, Tiny)
//.byte 48 // Fungi Forest
//.byte 49 // Gloomy Galleon: Lighthouse
//.byte 50 // K. Rool Barrel: Tiny's Mushroom Game // TODO: Test
//.byte 51 // Gloomy Galleon: Mechanical Fish
//.byte 52 // Fungi Forest: Ant Hill
//.byte 53 // Battle Arena: Beaver Brawl!
.byte 54 // Gloomy Galleon: Barrel Blast
.byte 55 // Fungi Forest: Minecart
//.byte 56 // Fungi Forest: Diddy's Barn
//.byte 57 // Fungi Forest: Diddy's Attic
//.byte 58 // Fungi Forest: Lanky's Attic
//.byte 59 // Fungi Forest: DK's Barn
//.byte 60 // Fungi Forest: Spider // TODO: Test
//.byte 61 // Fungi Forest: Front Part of Mill
//.byte 62 // Fungi Forest: Rear Part of Mill
//.byte 63 // Fungi Forest: Mushroom Puzzle
//.byte 64 // Fungi Forest: Giant Mushroom
//.byte 65 // Stealthy Snoop! (normal) // TODO: Test
//.byte 66 // Mad Maze Maul! (hard) // TODO: Test
//.byte 67 // Stash Snatch! (normal) // TODO: Test
//.byte 68 // Mad Maze Maul! (easy) // TODO: Test
//.byte 69 // Mad Maze Maul! (normal) // TODO: Test
//.byte 70 // Fungi Forest: Mushroom Leap
//.byte 71 // Fungi Forest: Shooting Game
//.byte 72 // Crystal Caves
//.byte 73 // Battle Arena: Kritter Karnage!
//.byte 74 // Stash Snatch! (easy)
//.byte 75 // Stash Snatch! (hard)
.byte 76 // DK Rap
.byte 77 // Minecart Mayhem! (easy) // TODO: Test
.byte 78 // Busy Barrel Barrage! (easy)
.byte 79 // Busy Barrel Barrage! (normal)
.byte 80 // Main Menu
//.byte 81 // Title Screen (Not For Resale Version)
.byte 82 // Crystal Caves: Beetle Race
.byte 83 // Fungi Forest: Dogadon
//.byte 84 // Crystal Caves: Igloo (Tiny)
//.byte 85 // Crystal Caves: Igloo (Lanky)
//.byte 86 // Crystal Caves: Igloo (DK)
//.byte 87 // Creepy Castle
//.byte 88 // Creepy Castle: Ballroom
//.byte 89 // Crystal Caves: Rotating Room
//.byte 90 // Crystal Caves: Shack (Chunky)
//.byte 91 // Crystal Caves: Shack (DK)
//.byte 92 // Crystal Caves: Shack (Diddy, middle part)
//.byte 93 // Crystal Caves: Shack (Tiny)
//.byte 94 // Crystal Caves: Lanky's Hut
//.byte 95 // Crystal Caves: Igloo (Chunky)
//.byte 96 // Splish-Splash Salvage! (normal)
//.byte 97 // K. Lumsy
//.byte 98 // Crystal Caves: Ice Castle
//.byte 99 // Speedy Swing Sortie! (easy)
//.byte 100 // Crystal Caves: Igloo (Diddy)
.byte 101 // Krazy Kong Klamour! (easy) // Note: Broken with switch kong
.byte 102 // Big Bug Bash! (very easy) // Note: Broken with switch kong
.byte 103 // Searchlight Seek! (very easy) // Note: Broken with switch kong
.byte 104 // Beaver Bother! (easy) // Note: Broken with switch kong
//.byte 105 // Creepy Castle: Tower
.byte 106 // Creepy Castle: Minecart
//.byte 107 // Kong Battle: Battle Arena  // TODO: Would be really cool to get multiplayer working, currently just voids you out when activated
//.byte 108 // Creepy Castle: Crypt (Lanky, Tiny)
//.byte 109 // Kong Battle: Arena 1  // TODO: Would be really cool to get multiplayer working, currently just voids you out when activated
.byte 110 // Frantic Factory: Barrel Blast
.byte 111 // Gloomy Galleon: Puftoss
//.byte 112 // Creepy Castle: Crypt (DK, Diddy, Chunky)
//.byte 113 // Creepy Castle: Museum
//.byte 114 // Creepy Castle: Library
//.byte 115 // Kremling Kosh! (easy) // TODO: Test
//.byte 116 // Kremling Kosh! (normal) // TODO: Test
//.byte 117 // Kremling Kosh! (hard) // TODO: Test
.byte 118 // Teetering Turtle Trouble! (easy)
.byte 119 // Teetering Turtle Trouble! (normal)
.byte 121 // Teetering Turtle Trouble! (hard)
// .byte 122 // Batty Barrel Bandit! (easy)
// .byte 123 // Batty Barrel Bandit! (normal)
// .byte 124 // Batty Barrel Bandit! (hard)
.byte 125 // Mad Maze Maul! (insane)
.byte 126 // Stash Snatch! (insane)
.byte 127 // Stealthy Snoop! (very easy)
.byte 128 // Stealthy Snoop! (easy)
.byte 129 // Stealthy Snoop! (hard)
//.byte 120 // Minecart Mayhem! (normal) // TODO: Test
//.byte 130 // Minecart Mayhem! (hard) // TODO: Test
.byte 131 // Busy Barrel Barrage! (hard)
//.byte 132 // Splish-Splash Salvage! (hard)
//.byte 133 // Splish-Splash Salvage! (easy)
//.byte 134 // Speedy Swing Sortie! (normal)
//.byte 135 // Speedy Swing Sortie! (hard)
.byte 136 // Beaver Bother! (normal)
.byte 137 // Beaver Bother! (hard)
.byte 138 // Searchlight Seek! (easy)
.byte 139 // Searchlight Seek! (normal)
.byte 140 // Searchlight Seek! (hard)
.byte 141 // Krazy Kong Klamour! (normal)
.byte 142 // Krazy Kong Klamour! (hard)
.byte 143 // Krazy Kong Klamour! (insane)
.byte 144 // Peril Path Panic! (very easy) // Note: Broken with switch kong
.byte 145 // Peril Path Panic! (easy)
.byte 146 // Peril Path Panic! (normal)
.byte 147 // Peril Path Panic! (hard)
.byte 148 // Big Bug Bash! (easy)
.byte 149 // Big Bug Bash! (normal)
.byte 150 // Big Bug Bash! (hard)
//.byte 151 // Creepy Castle: Dungeon
//.byte 152 // Hideout Helm (Intro Story) // Note: Handled by cutscene check
//.byte 153 // DK Isles (DK Theatre) // Note: Handled by cutscene check
//.byte 154 // Frantic Factory: Mad Jack
//.byte 155 // Battle Arena: Arena Ambush!
//.byte 156 // Battle Arena: More Kritter Karnage!
//.byte 157 // Battle Arena: Forest Fracas!
//.byte 158 // Battle Arena: Bish Bash Brawl!
//.byte 159 // Battle Arena: Kamikaze Kremlings!
//.byte 160 // Battle Arena: Plinth Panic!
//.byte 161 // Battle Arena: Pinnacle Palaver!
//.byte 162 // Battle Arena: Shockwave Showdown!
//.byte 163 // Creepy Castle: Basement
//.byte 164 // Creepy Castle: Tree
//.byte 165 // K. Rool Barrel: Diddy's Kremling Game // TODO: Test
//.byte 166 // Creepy Castle: Chunky's Toolshed
//.byte 167 // Creepy Castle: Trash Can
//.byte 168 // Creepy Castle: Greenhouse
//.byte 169 // Jungle Japes Lobby
//.byte 170 // Hideout Helm Lobby
//.byte 171 // DK's House
//.byte 172 // Rock (Intro Story) // Note: Handled by cutscene check
//.byte 173 // Angry Aztec Lobby
//.byte 174 // Gloomy Galleon Lobby
//.byte 175 // Frantic Factory Lobby
//.byte 176 // Training Grounds
//.byte 177 // Dive Barrel
//.byte 178 // Fungi Forest Lobby
//.byte 179 // Gloomy Galleon: Submarine
//.byte 181 // Orange Barrel
//.byte 182 // Barrel Barrel
//.byte 183 // Vine Barrel
//.byte 184 // Creepy Castle: Crypt
.byte 185 // Enguarde Arena // TODO: Test
.byte 186 // Creepy Castle: Car Race // TODO: Test
.byte 187 // Crystal Caves: Barrel Blast
.byte 188 // Creepy Castle: Barrel Blast
.byte 189 // Fungi Forest: Barrel Blast
//.byte 180 // Fairy Island
.byte 190 // Kong Battle: Arena 2 // TODO: Would be really cool to get multiplayer working, currently just voids you out when activated
.byte 191 // Rambi Arena // TODO: Test
.byte 192 // Kong Battle: Arena 3 // TODO: Would be really cool to get multiplayer working, currently just voids you out when activated
//.byte 193 // Creepy Castle Lobby
//.byte 194 // Crystal Caves Lobby
//.byte 195 // DK Isles: Snide's Room
//.byte 196 // Crystal Caves: Army Dillo
//.byte 197 // Angry Aztec: Dogadon
//.byte 198 // Training Grounds (End Sequence) // Note: Handled by cutscene check
.byte 199 // Creepy Castle: King Kut Out // Note: Doesn't break the kong order but since this fight is explicitly about tagging we might as well disable
//.byte 200 // Crystal Caves: Shack (Diddy, upper part)
//.byte 201 // K. Rool Barrel: Diddy's Rocketbarrel Game
//.byte 202 // K. Rool Barrel: Lanky's Shooting Game
.byte 203 // K. Rool Fight: DK Phase // Note: Enabling here breaks the fight and may cause softlocks
.byte 204 // K. Rool Fight: Diddy Phase // Note: Enabling here breaks the fight and may cause softlocks
.byte 205 // K. Rool Fight: Lanky Phase // Note: Enabling here breaks the fight and may cause softlocks
.byte 206 // K. Rool Fight: Tiny Phase // Note: Enabling here breaks the fight and may cause softlocks
.byte 207 // K. Rool Fight: Chunky Phase // Note: Enabling here breaks the fight and may cause softlocks
//.byte 208 // Bloopers Ending // Note: Handled by cutscene check
.byte 209 // K. Rool Barrel: Chunky's Hidden Kremling Game
.byte 210 // K. Rool Barrel: Tiny's Pony Tail Twirl Game
.byte 211 // K. Rool Barrel: Chunky's Shooting Game
.byte 212 // K. Rool Barrel: DK's Rambi Game
//.byte 213 // K. Lumsy Ending // Note: Handled by cutscene check
.byte 214 // K. Rool's Shoe
//.byte 215 // K. Rool's Arena // Note: Handled by cutscene check?
.byte 0 // NULL TERMINATOR (ends loop)

ExplicitDisableMovementStates:
.byte 0x06 // Locked (Bonus Barrel)
.byte 0x18 // Baboon Blast Pad
.byte 0x31 // Damaged
.byte 0x32 // Stunlocked
.byte 0x33 // Damaged
.byte 0x35 // Damaged
.byte 0x36 // Death
.byte 0x37 // Damaged (Underwater)
.byte 0x38 // Damaged
.byte 0x39 // Shrinking
.byte 0x42 // Barrel
.byte 0x43 // Barrel (Underwater)
.byte 0x44 // Baboon Blast Shot
.byte 0x45 // Cannon Shot
.byte 0x52 // Bananaporter
.byte 0x53 // Monkeyport
.byte 0x54 // Bananaporter (Multiplayer)
.byte 0x56 // Locked
.byte 0x67 // Instrument
.byte 0x69 // Car
//.byte 0x6A // Learning Gun // Note: Handled by map check
.byte 0x6B // Locked
//.byte 0x6C // Feeding T&S // Note: Handled by map check
.byte 0x6D // Boat
.byte 0x70 // GB Dance
.byte 0x71 // Key Dance
.byte 0x72 // Crown Dance
.byte 0x73 // Loss Dance
.byte 0x74 // Victory Dance
.byte 0x78 // Gorilla Grab
//.byte 0x79 // Learning Move // Note: Handled by map check
.byte 0x7A // Locked
.byte 0x7B // Locked
.byte 0x7C // Trapped (spider miniBoss)
//.byte 0x7D // Klaptrap Kong (beaver bother) // Note: Handled by map check
.byte 0x83 // Fairy Refill
.byte 0x87 // Entering Portal
.byte 0x88 // Exiting Portal
.byte 0 // NULL TERMINATOR (ends loop)