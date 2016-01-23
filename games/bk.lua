local Game = {};

--------------------
-- Region/Version --
--------------------

-- Only patch US 1.0
-- TODO - Figure out how to patch other versions
local allowFurnaceFunPatch = false;

local slope_timer;
local moves_bitfield;

local x_vel;
local y_vel;
local z_vel;

-- Velocity required to clip on the Y axis
local clip_vel = -3500;

local x_pos;
local y_pos;
local z_pos;

local x_rot;
local y_rot;
local facing_angle;
local moving_angle;
local z_rot;

local camera_rot;

local map;
local frame_timer;
local object_array_pointer;
local ff_question_pointer;

local notes;

-- Relative to notes
-- TODO: Add jinjos
local eggs = 4;
local red_feathers = 12;
local gold_feathers = 16;
local health = 32;
local health_containers = 36;
local lives = 40;
local air = 44;
local mumbo_tokens_on_hand = 64;
local mumbo_tokens = 100;
local jiggies = 104;

local max_notes = 100;
local max_eggs = 200; -- TODO: How do you get this information out of the game?
local max_red_feathers = 50; -- TODO: How do you get this information out of the game?
local max_gold_feathers = 10; -- TODO: How do you get this information out of the game?
local max_lives = 9;
local max_air = 6 * 600;
local max_mumbo_tokens = 99;
local max_jiggies = 100;

local previous_movement_state;
local current_movement_state;

local eep_checksum_offsets = {
	0x74,
	0xEC,
	0x164,
	0x1DC,
	0x1FC
};

local eep_checksum_values = {
	0x00000000,
	0x00000000,
	0x00000000,
	0x00000000,
	0x00000000
}

Game.maps = { -- TODO: These values don't work properly in some places for PAL, likely other versions too
	"SM - Spiral Mountain",
	"MM - Mumbo's Mountain",
	"Unknown 0x03",
	"Unknown 0x04",
	"TTC - Blubber's Ship",
	"TTC - Nipper's Shell",
	"TTC - Treasure Trove Cove",
	"Unknown 0x08",
	"Unknown 0x09",
	"TTC - Sandcastle",
	"CC - Clanker's Cavern",
	"MM - Ticker's Tower",
	"BGS - Bubblegloop Swamp",
	"Mumbo's Skull (MM)",
	"Unknown 0x0F",
	"BGS - Mr. Vile",
	"BGS - Tiptup",
	"GV - Gobi's Valley",
	"GV - Matching Game",
	"GV - Maze",
	"GV - Water",
	"GV - Snake",
	"Unknown 0x17",
	"Unknown 0x18",
	"Unknown 0x19",
	"GV - Sphinx",
	"MMM - Mad Monster Mansion",
	"MMM - Church",
	"MMM - Cellar",
	"Start - Nintendo",
	"Start - Rareware",
	"End Scene 2: Not 100",
	"End Scene 2: Not 100",
	"CC - Witch Switch Room",
	"CC - Inside Clanker",
	"CC - Gold Feather Room",
	"MMM - Tumblar's Shed",
	"MMM - Well",
	"MMM - Dining Room (Napper)",
	"FP - Freezeezy Peak",
	"MMM - Room 1",
	"MMM - Room 2",
	"MMM - Room 3: Fireplace",
	"MMM - Church",
	"MMM - Room 4: Bathroom",
	"MMM - Room 5: Bedroom",
	"MMM - Room 6: Floorboards",
	"MMM - Barrel",
	"Mumbo's Skull (MMM)",
	"RBB - Rusty Bucket Bay",
	"Unknown 0x32",
	"Unknown 0x33",
	"RBB - Engine Room",
	"RBB - Warehouse 1",
	"RBB - Warehouse 2",
	"RBB - Container 1",
	"RBB - Container 3",
	"RBB - Crew Cabin",
	"RBB - Boss Boom Box",
	"RBB - Store Room",
	"RBB - Kitchen",
	"RBB - Navigation Room",
	"RBB - Container 2",
	"RBB - Captain's Cabin",
	"CCW - Start",
	"FP - Boggy's Igloo",
	"Unknown 0x42",
	"CCW - Spring",
	"CCW - Summer",
	"CCW - Autumn",
	"CCW - Winter",
	"Mumbo's Skull (BGS)",
	"Mumbo's Skull (FP)",
	"Unknown 0x49",
	"Mumbo's Skull (CCW Spring)",
	"Mumbo's Skull (CCW Summer)",
	"Mumbo's Skull (CCW Autumn)",
	"Mumbo's Skull (CCW Winter)",
	"Unknown 0x4E",
	"Unknown 0x4F",
	"Unknown 0x50",
	"Unknown 0x51",
	"Unknown 0x52",
	"FP - Inside Xmas Tree",
	"Unknown 0x54",
	"Unknown 0x55",
	"Unknown 0x56",
	"Unknown 0x57",
	"Unknown 0x58",
	"Unknown 0x59",
	"CCW - Zubba's Hive (Summer)",
	"CCW - Zubba's Hive (Spring)",
	"CCW - Zubba's Hive (Autumn)",
	"Unknown 0x5D",
	"CCW - Nabnut's House (Spring)",
	"CCW - Nabnut's House (Summer)",
	"CCW - Nabnut's House (Autumn)",
	"CCW - Nabnut's House (Winter)",
	"CCW - Nabnut's Room 1 (Winter)",
	"CCW - Nabnut's Room 2 (Autumn)",
	"CCW - Nabnut's Room 2 (Winter)",
	"CCW - Top (Spring)",
	"CCW - Top (Summer)",
	"CCW - Top (Autumn)",
	"CCW - Top (Winter)",
	"Lair - MM Lobby",
	"Lair - TTC/CC Puzzle",
	"Lair - CCW Puzzle & 180 Note Door",
	"Lair - Red Cauldron Room",
	"Lair - TTC Lobby",
	"Lair - GV Lobby",
	"Lair - FP Lobby",
	"Lair - CC Lobby",
	"Lair - Statue",
	"Lair - BGS Lobby",
	"Unknown 0x73",
	"Lair - GV Puzzle",
	"Lair - MMM Lobby",
	"Lair - 640 Note Door Room",
	"Lair - RBB Lobby",
	"Lair - RBB Puzzle",
	"Lair - CCW Lobby",
	"Lair - Flr 2, Area 5a: Crypt inside",
	"Intro - Lair 1 - Scene 1",
	"Intro - Banjo's House 1 - Scenes 3,7",
	"Intro - Spiral 'A' - Scenes 2,4",
	"Intro - Spiral 'B' - Scenes 5,6",
	"FP - Wozza's Cave",
	"Lair - Flr 3, Area 4a",
	"Intro - Lair 2",
	"Intro - Lair 3 - Machine 1",
	"Intro - Lair 4 - Game Over",
	"Intro - Lair 5",
	"Intro - Spiral 'C'",
	"Intro - Spiral 'D'",
	"Intro - Spiral 'E'",
	"Intro - Spiral 'F'",
	"Intro - Banjo's House 2",
	"Intro - Banjo's House 3",
	"RBB - Anchor room",
	"SM - Banjo's House",
	"MMM - Inside Loggo",
	"Lair - Furnace Fun",
	"TTC - Sharkfood Island",
	"Lair - Battlements",
	"File Select Screen",
	"GV - Secret Chamber",
	"Lair - Dingpot",
	"Intro - Spiral 'G'",
	"End Scene 3: All 100",
	"End Scene",
	"End Scene 4",
	"Intro - Grunty Threat 1",
	"Intro - Grunty Threat 2"
}

function Game.detectVersion(romName)
	if bizstring.contains(romName, "Europe") then
		frame_timer = 0x280700;
		slope_timer = 0x37CCB4;
		moves_bitfield = 0x37CD70;
		x_vel = 0x37CE88;
		clip_vel = -2900;
		x_pos = 0x37CF70;
		x_rot = 0x37CF10;
		moving_angle = 0x37D064;
		camera_rot = 0x37E578;
		z_rot = 0x37D050;
		current_movement_state = 0x37DB34;
		map = 0x37F2C5;
		allowFurnaceFunPatch = false;
		ff_question_pointer = 0x383AC0;
		notes = 0x386940;
		object_array_pointer = 0x36EAE0;
	elseif bizstring.contains(romName, "Japan") then
		frame_timer = 0x27F718;
		slope_timer = 0x37CDE4;
		moves_bitfield = 0x37CEA0;
		x_vel = 0x37CFB8;
		x_pos = 0x37D0A0;
		x_rot = 0x37D040;
		moving_angle = 0x37D194;
		camera_rot = 0x37E6A8;
		z_rot = 0x37D180;
		current_movement_state = 0x37DC64;
		map = 0x37F405;
		allowFurnaceFunPatch = false;
		ff_question_pointer = 0x383C20;
		notes = 0x386AA0;
		object_array_pointer = 0x36F260;
	elseif bizstring.contains(romName, "USA") and bizstring.contains(romName, "Rev A") then
		frame_timer = 0x27F718;
		slope_timer = 0x37B4E4;
		moves_bitfield = 0x37B5A0;
		x_vel = 0x37B6B8;
		x_pos = 0x37B7A0;
		x_rot = 0x37B740;
		moving_angle = 0x37B894;
		camera_rot = 0x37CDA8;
		z_rot = 0x37B880;
		current_movement_state = 0x37C364;
		map = 0x37DAF5;
		allowFurnaceFunPatch = false;
		ff_question_pointer = 0x382300;
		notes = 0x385180;
		object_array_pointer = 0x36D760;
	elseif bizstring.contains(romName, "USA") then
		frame_timer = 0x2808D8;
		slope_timer = 0x37C2E4;
		moves_bitfield = 0x37C3A0;
		x_vel = 0x37C4B8;
		x_pos = 0x37C5A0;
		x_rot = 0x37C540;
		moving_angle = 0x37C694;
		camera_rot = 0x37D96C;
		z_rot = 0x37C680;
		current_movement_state = 0x37D164;
		map = 0x37E8F5;
		allowFurnaceFunPatch = true;
		ff_question_pointer = 0x3830E0;
		notes = 0x385F60;
		object_array_pointer = 0x36E560;
	else
		return false;
	end

	y_pos = x_pos + 4;
	z_pos = y_pos + 4;

	y_vel = x_vel + 4;
	z_vel = y_vel + 4;

	facing_angle = moving_angle - 4;
	y_rot = moving_angle;

	previous_movement_state = current_movement_state - 4;

	-- Read EEPROM checksums
	if memory.usememorydomain("EEPROM") then
		local i;
		for i = 1, #eep_checksum_offsets do
			eep_checksum_values[i] = memory.read_u32_be(eep_checksum_offsets[i]);
		end
	end
	memory.usememorydomain("RDRAM");

	return true;
end

local options_toggle_neverslip;

local function neverSlip()
	mainmemory.writefloat(slope_timer, 0.0, true);
end

-----------------
-- Moves stuff --
-----------------

local options_moves_dropdown;
local options_moves_button;

local move_levels = {
	["0. None"]                 = 0x00000000,
	["1. Spiral Mountain 100%"] = 0x00009DB9,
	["2. FFM Setup"]            = 0x000BFDBF,
	["3. All"]                  = 0x000FFFFF,
	["3. Demo"]                 = 0xFFFFFFFF
};

local function unlock_moves()
	local level = forms.gettext(options_moves_dropdown);
	mainmemory.write_u32_be(moves_bitfield, move_levels[level]);
end

--------------------
-- Movement state --
--------------------

local movementStates = {
	[0] = "Null",
	[1] = "Idle",
	[2] = "Walking", -- Slow
	[3] = "Walking",
	[4] = "Walking", -- Fast
	[5] = "Jumping",
	[6] = "Bear punch",
	[7] = "Crouching",
	[8] = "Jumping", -- Talon Trot
	[9] = "Shooting Egg",
	[10] = "Pooping Egg",

	[12] = "Skidding",
	[14] = "Knockback",
	[15] = "Beak Buster",
	[16] = "Feathery Flap",
	[17] = "Rat-a-tat rap",
	[18] = "Backflip", -- Flap Flip
	[19] = "Beak Barge",

	[20] = "Entering Talon Trot",
	[21] = "Idle", -- Talon Trot
	[22] = "Walking", -- Talon Trot
	[23] = "Leaving Talon Trot",

	[26] = "Entering Wonderwing",
	[27] = "Idle", -- Wonderwing
	[28] = "Walking", -- Wonderwing
	[29] = "Jumping", -- Wonderwing
	[30] = "Leaving Wonderwing",

	[31] = "Creeping",
	[32] = "Landing", -- After Jump
	[33] = "Charging Shock Spring Jump",
	[34] = "Shock Spring Jump",
	[35] = "Taking Flight",
	[36] = "Flying",
	[37] = "Entering Wading Boots",
	[38] = "Idle", -- Wading Boots
	[39] = "Walking", -- Wading Boots

	[40] = "Jumping", -- Wading Boots
	[41] = "Leaving Wading Boots",
	[42] = "Beak Bomb",
	[43] = "Idle", -- Underwater
	[44] = "Swimming (B)",
	[45] = "Idle", -- Treading water
	[46] = "Paddling",

	[47] = "Falling", -- After pecking
	[48] = "Diving",

	[49] = "Rolling",
	[50] = "Slipping",

	[53] = "Idle", -- Termite
	[54] = "Walking", -- Termite
	[55] = "Jumping", -- Termite
	[56] = "Falling", -- Termite
	[57] = "Swimming (A)",

	[62] = "Knockback", -- Termite

	[65] = "Death",
	[68] = "Jiggy Jig",
	[69] = "Slipping", -- Talon Trot

	[76] = "Landing", -- In water

	[79] = "Idle", -- Holding tree, pole, etc.
	[80] = "Climbing", -- Tree, pole, etc.

	[85] = "Slipping", -- Wading Boots
	[86] = "Knockback", -- Successful enemy damage
	[87] = "Beak Bomb", -- Ending

	[90] = "Loading Zone",

	[94] = "Idle", -- Croc
	[95] = "Walking", -- Croc
	[96] = "Jumping", -- Croc
	[97] = "Falling", -- Croc
	[99] = "Knockback", -- Croc

	[103] = "Idle", -- Walrus
	[104] = "Walking", -- Walrus
	[105] = "Jumping", -- Walrus
	[106] = "Falling", -- Walrus
	[108] = "Knockback", -- Walrus
	[109] = "Death", -- Walrus

	[110] = "Biting", -- Croc

	[113] = "Falling", -- Talon Trot
	[114] = "Recovering", -- Getting up after taking damage, eg. fall famage
	[115] = "Locked", -- Cutscene? -- TODO
	[116] = "Locked", -- Jiggy pad, Mumbo transformation, Bottles

	[121] = "Locked", -- Holding Jiggy, Talon Trot
	[123] = "Knockback", -- Talon Trot

	[141] = "Locked", -- Mumbo transformation, Mr. Vile
	[142] = "Locked", -- Jiggy podium, Bottles' text outside Mumbo's
	[148] = "Locked", -- Mumbo transformation
	[149] = "Locked", -- Walrus?

	[152] = "Locked", -- Loading zone, Mumbo transformation
	[162] = "Knockback", -- Walrus
};

function getCurrentMovementState()
	local currentMovementState = mainmemory.read_u32_be(current_movement_state);
	if type(movementStates[currentMovementState]) ~= "nil" then
		return movementStates[currentMovementState];
	end
	return "Unknown ("..currentMovementState..")";
end

--------------------------
-- Sandcastle positions --
--------------------------

local sandcastle_square_size = 90;
local sandcastlePositions = {
	["A"] = {2, -8},
	["B"] = {0, 6},
	["C"] = {4, -6},
	["D"] = {-4, -2},
	["E"] = {0, -6},
	["F"] = {4, 2},
	["G"] = {-2, -8},
	["H"] = {-4, 6},
	["I"] = {6, 0},
	["J"] = {-6, -8},
	["K"] = {4, 6},
	["L"] = {6, -8},
	["M"] = {-6, -4},
	["N"] = {-2, -4},
	["O"] = {0, -2},
	["P"] = {6, -4},
	-- There's no Q in the sandcastle
	["R"] = {2, -4},
	["S"] = {4, -2},
	["T"] = {0, 2},
	["U"] = {-2, 0},
	["V"] = {-4, -6},
	["W"] = {2, 4},
	["X"] = {-4, 2},
	["Y"] = {2, 0},
	["Z"] = {-6, 0},
};

function gotoSandcastleLetter(letter)
	if type(letter) ~= "string" then
		print("Letter not a string.");
	end

	-- Convert the letter to uppercase
	letter = string.upper(letter);

	if type(sandcastlePositions[letter]) ~= "table" then
		print("Letter not found.");
	end

	Game.setXPosition(sandcastlePositions[letter][1] * sandcastle_square_size);
	Game.setZPosition(sandcastlePositions[letter][2] * sandcastle_square_size);
end

-------------------------------
-- Sandcastle string decoder --
-------------------------------

local sandcastleStringConversionTable = {
	[0x00] = " ",
	[0x30] = "C",
	[0x31] = "M",
	[0x32] = "S",
	[0x33] = "Z",
	[0x34] = "I",
	[0x35] = "G",
	[0x36] = "O",
	[0x37] = "W",
	[0x38] = "K",
	[0x39] = "R",
	[0x61] = "V",
	[0x62] = "L",
	[0x63] = "F",
	[0x64] = "T",
	[0x65] = "Y",
	[0x67] = "U",
	[0x68] = "X",
	[0x69] = "N",
	[0x6A] = "E",
	[0x6B] = "B",
	[0x6C] = "D",
	[0x6D] = "H",
	[0x6E] = "A",
	[0x70] = "J",
	[0x72] = "P",
};

function decodeSandcastleString(base, length, nullTerminate)
	nullTerminate = nullTerminate or false;
	local i;
	local builtString = "";
	for i = base, base + length do
		local byte = mainmemory.readbyte(i);

		if byte == 0 and nullTerminate then
			break;
		end

		if type(sandcastleStringConversionTable[byte]) ~= "nil" then
			builtString = builtString..sandcastleStringConversionTable[byte];
		else
			builtString = builtString.."?".."("..bizstring.hex(byte).." = "..string.char(byte)..")";
		end
	end
	print(builtString);
end

-----------------------
-- Furnace fun stuff --
-----------------------

local options_allow_ff_patch;

local function applyFurnaceFunPatch()
	if allowFurnaceFunPatch and forms.ischecked(options_allow_ff_patch) then
		mainmemory.write_u16_be(0x320064, 0x080A);
		mainmemory.write_u16_be(0x320066, 0x1840);

		mainmemory.write_u16_be(0x286100, 0xAC86);
		mainmemory.write_u16_be(0x286102, 0x2DC8);
		mainmemory.write_u16_be(0x286104, 0x0C0C);
		mainmemory.write_u16_be(0x286106, 0x8072);

		mainmemory.write_u16_be(0x28610C, 0x080C);
		mainmemory.write_u16_be(0x28610E, 0x801B);
	end
end

-- Relative to question object
local ff_current_answer = 0x13;
local ff_correct_answer = 0x1D;

local ff_question_text_pointer = 0x34;
local ff_answer1_text_pointer = 0x64;
local ff_answer2_text_pointer = 0x54;
local ff_answer3_text_pointer = 0x44;

function getSelectedFFAnswer()
	local ff_question_object = mainmemory.read_u24_be(ff_question_pointer + 1);
	if ff_question_object > 0x000000 and ff_question_object < 0x3FFFFF then
		return mainmemory.readbyte(ff_question_object + ff_current_answer);
	end
end

function getCorrectFFAnswer()
	local ff_question_object = mainmemory.read_u24_be(ff_question_pointer + 1);
	if ff_question_object > 0x000000 and ff_question_object < 0x3FFFFF then
		return mainmemory.readbyte(ff_question_object + ff_correct_answer);
	end
end

ui_ff_x = 100;
ui_ff_y_base = 100;
ui_ff_answer_height = 16;

-- TODO: Finish this
function doFFHelp()
	local selectedAnswer = getSelectedFFAnswer();
	local correctAnswer = getCorrectFFAnswer();
	if type(correctAnswer) == "number" and correctAnswer >= 0 and correctAnswer <= 3 then
		gui.drawText(ui_ff_x, ui_ff_y_base + ui_ff_answer_height * correctAnswer, "ya"..correctAnswer);
	end
end
--event.onframestart(doFFHelp, "FF Helper");

----------------------
-- Vile state stuff --
----------------------

-- Wave UI
local options_wave_button;
local options_heart_button;
local options_fire_all_button;

local game_type = 0x90;

local previous_game_type = 0x91
local player_score = 0x92;
local vile_score = 0x93;

local minigame_timer = 0x94;

local number_of_slots = 25;
-- TODO: Figure out object type for vile slots
local first_slot_base = 0x28;
local slot_base = 0x318;
local slot_size = 0x180;

-- Relative to slot base + (slot number * slot size)

-- 00000 0x00 Disabled
-- 00100 0x04 Idle
-- 01000 0x08 Rising
-- 01100 0x0c Alive
-- 10000 0x10 Falling (not eaten)
-- 10100 0x14 Eaten
local slot_state = 0x00;

-- Float 0-1
local popped_amount = 0x6c;

-- 0x00 = yum, > 0x00 = grum
local slot_type = 0x70;

-- Float 0-15?
local slot_timer = 0x74;

local function getSlotBase(index)
	if index < 12 then
		return slot_base + (index - 1) * slot_size;
	end
	return slot_base + index * slot_size;
end

local function fireSlot(vile_state, index, slotType)
	current_slot_base = getSlotBase(index);
	mainmemory.writebyte(vile_state + current_slot_base + slot_state, 0x08);
	mainmemory.writebyte(vile_state + current_slot_base + slot_type, slotType);
	mainmemory.writefloat(vile_state + current_slot_base + popped_amount, 1.0, true);
	mainmemory.writefloat(vile_state + current_slot_base + slot_timer, 0.0, true);
end

local vileMap = {
	{ 22, 24, 16 },
	{ 21, 23, 14, 15 },
	{ 20, 19, 17, 13, 12 },
	{ 9,  18, 11, 4 },
	{ 10, 7,  8,  2,  1  },
	{ 6,  5,  3,  0 }
};

local heart = {
	{2, 2}, {2, 3},
	{3, 2}, {3, 3}, {3, 4},
	{4, 2}, {4, 3},
	{5, 3}
};

local waveFrames = {
	{ {3, 1}, {5, 1} },
	{ {2, 1}, {4, 1}, {6, 1} },
	{ {1, 1}, {3, 2}, {5, 2} },
	{ {2, 2}, {4, 2}, {6, 2} },
	{ {1, 2}, {3, 3}, {5, 3} },
	{ {2, 3}, {4, 3}, {6, 3} },
	{ {1, 3}, {3, 4}, {5, 4} },
	{ {2, 4}, {4, 4}, {6, 4} },
	{ {3, 5}, {5, 5} }
}

function getSlotIndex(row, col)
	row = math.max(row, 1);
	if row <= #vileMap then
		col = math.max(col, 1);
		col = math.min(col, #vileMap[row]);
		return vileMap[row][col] + 1;
	end
	return 1;
end

local waving = false;
local wave_counter = 0;
local wave_delay = 10;
local wave_frame = 1;
local wave_colour = 0;

local function initWave()
	waving = true;
	wave_frame = 1;
	wave_counter = 0;
	wave_colour = math.random(0, 1);
end

local function updateWave()
	if waving then
		wave_counter = wave_counter + 1;
		if wave_counter == wave_delay then
			local i;
			local vile_state = mainmemory.read_u24_be(object_array_pointer + 1);
			for i=1,#waveFrames[wave_frame] do
				fireSlot(vile_state, getSlotIndex(waveFrames[wave_frame][i][1], waveFrames[wave_frame][i][2]), wave_colour);
			end
			wave_counter = 0;
			wave_frame = wave_frame + 1;
		end
		if wave_frame > #waveFrames then
			waving = false;
		end
	end
end

local function doHeart()
	local vile_state = mainmemory.read_u24_be(object_array_pointer + 1);
	local i;

	local colour = math.random(0, 1);
	for i=1,#heart do
		fireSlot(vile_state, getSlotIndex(heart[i][1], heart[i][2]), colour);
	end
end

local function fireAllSlots()
	local vile_state = mainmemory.read_u24_be(object_array_pointer + 1);
	local i;

	local colour = math.random(0, 1);
	for i=1,number_of_slots do
		fireSlot(vile_state, i, colour);
	end
end

------------------------
-- Roll Flutter stuff --
------------------------

RF_absolute_target_angle = 180;

local RF_max_analog = 127;

function set_angle(num)
	RF_absolute_target_angle = num;
end

local function RF_step()
	local current_camera_rot = mainmemory.readfloat(camera_rot, true) % 360;
	local analog_angle = rotation_to_radians(math.abs(RF_absolute_target_angle - current_camera_rot) % 360);
	local analog_x = math.sin(analog_angle) * RF_max_analog;
	local analog_y = -1 * math.cos(analog_angle) * RF_max_analog;
	--print("camera rot: "..current_camera_rot);
	--print("analog angle: "..analog_angle);
	--print("raw sincos: "..math.sin(analog_angle)..","..math.cos(analog_angle));
	--print("analog inputs: "..analog_x..","..analog_y);
	joypad.setanalog({['X Axis'] = analog_x, ['Y Axis'] = analog_y}, 1);
end

-------------------------------
-- Conga.lua                 --
-- Written by Isotarge, 2015 -- 
-------------------------------

local conga_slot_size = 0x80;
local throw_slot = 0x77;
local orange_timer = 0x1C;

local orange_timer_value = 0.5;

function throwOrange()
	local keyboard_pressed = input.get();
	if keyboard_pressed["C"] then
		local level_object_array_base = mainmemory.read_u24_be(object_array_pointer + 1);
		mainmemory.writefloat(level_object_array_base + throw_slot * conga_slot_size + orange_timer, orange_timer_value, true);
	end
end

--------------
-- Encircle --
--------------

local encircle_checkbox;
local dynamic_radius_checkbox;
local dynamic_radius_factor = 15;

-- Relative to level_object_array
local max_slots = 0x100;
local radius = 1000;

-- Relative to slot
local slot_x_pos = 0x164;
local slot_y_pos = 0x168;
local slot_z_pos = 0x16C;

local function get_num_slots()
	local level_object_array_state = mainmemory.read_u24_be(object_array_pointer + 1);
	return math.min(max_slots, mainmemory.read_u32_be(level_object_array_state));
end

local function get_slot_base(index)
	local level_object_array_state = mainmemory.read_u24_be(object_array_pointer + 1);
	return level_object_array_state + first_slot_base + index * slot_size;
end

local function encircle_banjo()
	local i, x, z;

	local current_banjo_x = Game.getXPosition();
	local current_banjo_y = Game.getYPosition();
	local current_banjo_z = Game.getZPosition();
	local currentPointers = {};

	num_slots = get_num_slots();

	if forms.ischecked(dynamic_radius_checkbox) then
		radius = num_slots * dynamic_radius_factor;
	else
		radius = 1000;
	end

	-- Fill and sort pointer list
	for i = 0, num_slots - 1 do
		table.insert(currentPointers, get_slot_base(i));
	end
	table.sort(currentPointers);

	-- Iterate and set position
	for i = 1, #currentPointers do
		x = current_banjo_x + math.cos(math.pi * 2 * i / #currentPointers) * radius;
		z = current_banjo_z + math.sin(math.pi * 2 * i / #currentPointers) * radius;

		mainmemory.writefloat(currentPointers[i] + slot_x_pos, x, true);
		mainmemory.writefloat(currentPointers[i] + slot_y_pos, current_banjo_y, true);
		mainmemory.writefloat(currentPointers[i] + slot_z_pos, z, true);
	end
end

-------------------
-- Physics/Scale --
-------------------

Game.speedy_speeds = { .1, 1, 5, 10, 20, 35, 50, 75, 100 };
Game.speedy_index = 6;

Game.rot_speed = 5;
Game.max_rot_units = 360;

function Game.isPhysicsFrame()
	local frameTimerValue = mainmemory.read_s32_be(frame_timer);
	return frameTimerValue <= 0 and not emu.islagged();
end

--------------
-- Position --
--------------

function Game.getXPosition()
	return mainmemory.readfloat(x_pos, true);
end

function Game.getYPosition()
	return mainmemory.readfloat(y_pos, true);
end

function Game.getZPosition()
	return mainmemory.readfloat(z_pos, true);
end

function Game.setXPosition(value)
	mainmemory.writefloat(x_pos, value, true);
	mainmemory.writefloat(x_pos + 0x10, value, true);
end

function Game.setYPosition(value)
	mainmemory.writefloat(y_pos, value, true);
	mainmemory.writefloat(y_pos + 0x10, value, true);

	-- Nullify gravity when setting Y position
	Game.setYVelocity(0);
end

function Game.setZPosition(value)
	mainmemory.writefloat(z_pos, value, true);
	mainmemory.writefloat(z_pos + 0x10, value, true);
end

--------------
-- Rotation --
--------------

function Game.getXRotation()
	return mainmemory.readfloat(x_rot, true);
end

function Game.getYRotation()
	return mainmemory.readfloat(moving_angle, true);
end

function Game.getZRotation()
	return mainmemory.readfloat(z_rot, true);
end

function Game.setXRotation(value)
	mainmemory.writefloat(x_rot, value, true);

	-- Also set the target
	mainmemory.writefloat(x_rot + 4, value, true);
end

function Game.setYRotation(value)
	mainmemory.writefloat(moving_angle, value, true);
	mainmemory.writefloat(facing_angle, value, true);
end

function Game.setZRotation(value)
	mainmemory.writefloat(z_rot, value, true);

	-- Also set the target
	mainmemory.writefloat(z_rot + 4, value, true);
end

--------------
-- Velocity --
--------------

function Game.getXVelocity()
	return mainmemory.readfloat(x_vel, true);
end

function Game.getYVelocity()
	return mainmemory.readfloat(y_vel, true);
end

function Game.getZVelocity()
	return mainmemory.readfloat(z_vel, true);
end

function Game.setXVelocity(value)
	return mainmemory.writefloat(x_vel, value, true);
end

function Game.setYVelocity(value)
	return mainmemory.writefloat(y_vel, value, true);
end

function Game.setZVelocity(value)
	return mainmemory.writefloat(z_vel, value, true);
end

------------------
-- CC Early bot --
------------------

CCBotRunning = false;
local bestVelocity = 0;
local requiredVelocity = -2900;

local xParams = {["min"] = 10, ["max"] = 127};
local yParams = {["min"] = 10, ["max"] = 127};

function setRandomJoystick()
	joypad.setanalog({['X Axis'] = math.random(xParams.min, xParams.max), ['Y Axis'] = math.random(yParams.min, yParams.max)}, 1);
end

function CCBot()
	if CCBotRunning then
		savestate.loadslot(0);
		setRandomJoystick();
		emu.frameadvance();
		emu.frameadvance();
		emu.frameadvance();
		emu.frameadvance();
		emu.frameadvance();
		emu.frameadvance();

		local currentVelocity = Game.getYVelocity();
		if currentVelocity <= bestVelocity then
			bestVelocity = currentVelocity;
			savestate.saveslot(0);
		end
	end
end

--event.onframestart(CCBot, "CCBot");

local options_pulse_clip_velocity;
local pulseClipVelocityCounter = 0;
pulseClipVelocityInterval = 5;

function pulseClipVelocity()
	pulseClipVelocityCounter = pulseClipVelocityCounter + 1;
	local currentVelocity = Game.getYVelocity();
	if forms.ischecked(options_pulse_clip_velocity) and pulseClipVelocityCounter >= pulseClipVelocityInterval and y >= 5 and currentVelocity > clip_vel then
		Game.setYVelocity(clip_vel);
		pulseClipVelocityCounter = 0;
	end
end

------------
-- Events --
------------

function Game.setMap(value)
	if value >= 1 and value <= #Game.maps then
		mainmemory.writebyte(map, value);

		-- Force the game to load the map instantly
		mainmemory.writebyte(map - 1, 0x01);
	end
end

function Game.applyInfinites()
	-- We don't apply infinite notes since it messes up note routing
	--mainmemory.write_s32_be(notes, max_notes);
	mainmemory.write_s32_be(notes + eggs, max_eggs);
	mainmemory.write_s32_be(notes + red_feathers, max_red_feathers);
	mainmemory.write_s32_be(notes + gold_feathers, max_gold_feathers);
	mainmemory.write_s32_be(notes + health, mainmemory.read_s32_be(notes + health_containers));
	mainmemory.write_s32_be(notes + lives, max_lives);
	mainmemory.write_s32_be(notes + air, max_air);
	mainmemory.write_s32_be(notes + mumbo_tokens, max_mumbo_tokens);
	mainmemory.write_s32_be(notes + mumbo_tokens_on_hand, max_mumbo_tokens);
	mainmemory.write_s32_be(notes + jiggies, max_jiggies);
end

function Game.initUI(form_handle, col, row, button_height, label_offset, dropdown_offset)
	options_toggle_neverslip = forms.checkbox(form_handle, "Never Slip", col(0) + dropdown_offset, row(6) + dropdown_offset);
	if allowFurnaceFunPatch then
		options_allow_ff_patch = forms.checkbox(form_handle, "Allow FF patch", col(0) + dropdown_offset, row(7) + dropdown_offset);
	end

	encircle_checkbox = forms.checkbox(form_handle, "Encircle (Beta)", col(5) + dropdown_offset, row(4) + dropdown_offset);
	dynamic_radius_checkbox = forms.checkbox(form_handle, "Dynamic Radius", col(5) + dropdown_offset, row(5) + dropdown_offset);
	options_pulse_clip_velocity = forms.checkbox(form_handle, "Pulse Clip Vel.", col(5) + dropdown_offset, row(6) + dropdown_offset);

	-- Vile
	options_wave_button =     forms.button(form_handle, "Wave", initWave,         col(10), row(4), col(2), button_height);
	options_heart_button =    forms.button(form_handle, "Heart", doHeart,         col(12) + 8, row(4), col(2), button_height);
	options_fire_all_button = forms.button(form_handle, "Fire all", fireAllSlots, col(10), row(5), col(4) + 8, button_height);

	-- Moves
	options_moves_dropdown = forms.dropdown(form_handle, { "0. None", "1. Spiral Mountain 100%", "2. FFM Setup", "3. All", "3. Demo" }, col(10) + dropdown_offset, row(7) + dropdown_offset);
	options_moves_button = forms.button(form_handle, "Unlock Moves", unlock_moves, col(5), row(7), col(4) + 8, button_height);
end

function Game.eachFrame()
	applyFurnaceFunPatch();
	updateWave();
	throwOrange();
	pulseClipVelocity();

	if forms.ischecked(options_toggle_neverslip) then
		neverSlip();
		--RF_step();
	end

	if forms.ischecked(encircle_checkbox) then
		encircle_banjo();
	end

	-- Check EEPROM checksums
	if memory.usememorydomain("EEPROM") then
		local i, checksum_value;
		for i=1,#eep_checksum_offsets do
			checksum_value = memory.read_u32_be(eep_checksum_offsets[i]);
			if eep_checksum_values[i] ~= checksum_value then
				print("Slot "..i.." Checksum: "..toHexString(eep_checksum_values[i]).." -> "..toHexString(checksum_value));
				eep_checksum_values[i] = checksum_value;
			end
		end
	end
	memory.usememorydomain("RDRAM");
end

return Game;