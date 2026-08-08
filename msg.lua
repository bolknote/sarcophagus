msg = {}

msg.game = {
	[1] = '{#3e8948ff}Game saved',
	[2] = '{#3e8948ff}Game loaded',
	[3] = '{#3e8948ff}Saving game...',
	[4] = 'You had some rest. (Rest quality: _1_)',
	[5] = 'You are too hungry to rest.',
	[6] = "{#ff0044ff}It's too hot to pick up.",
	[7] = "{#fee761ff}∙ {#ead4aaff}_1_{#8b9bb4ff}. _2_",
	[8] = "{#ff0044ff}Don't stand in the fire!",
	[9] = 'You must stand in water to fill it.',
	[10] = "You took a sip of water.",
	[11] = "Sand slips away. You need a container.",
	[12] = "{#feae34ff}Loading game. Press 1-9 to pick a slot, 0 or Esc to cancel.{#ffffffff}",
	[13] = "{#3e8948ff}Saving game. Press 1-9 to pick a slot, 0 or Esc to cancel.{#ffffffff}",
	[14] = "There are too many items on the ground.",
	[15] = "You shook the tree.",
	[16] = "Ouch.",
	[17] = "Power source is required.",
	[18] = "Gained {#feae34ff}_1_{#ffffffff}: _2_",
	[19] = "Lost {#feae34ff}_1_{#ffffffff}.",
	[20] = "You passed out.",
	[21] = "{#ead4aaff}_1_{#ffffffff} added to the inventory.",
	[22] = "{#fee761ff}∙{#ffffffff} You examined {#ead4aaff}_1_{#ffffffff}. _2_",
	[23] = "{#ead4aaff}_1_{#ffffffff} turned into {#ead4aaff}_2_{#ffffffff}.",
	[24] = "{#ead4aaff}_1_{#ffffffff} expired.",
	[25] = "{#0095e9ff}You defecated.",
	[26] = "It's too heavy.",
	[27] = "{#0095e9ff}This plant died of neglect (lack of light, water).",
	[28] = "{#0095e9ff}This plant died of old age.",
	[29] = "You can't craft anything using items you have.",
	[30] = "You harvested it too early.",
	[31] = "{#0095e9ff}This plant died.",
	[32] = "Ready. Charges: _1_",
	[33] = "Use +/- keys to switch inventory pages.",
	[34] = "{#0095e9ff}You scared the fish away.",
	[35] = "Maps are random, so they're not equal and fair, don't be afraid to restart.{#feae34ff}\nIMPORTANT: Tha world is deceptively empty. *Deceptively*. Knowledge is power. Inspect everything you can.\nSome items/blocks can be brought to the Machine for useful info and transformations - pay attention to ≈ sign.{#ffffffff}\nPress {#fee761ff}W, A, S, D{#ffffffff} to move, {#fee761ff}Space{#ffffffff} to dig/drop (you can also press dig+up or dig+down)",
	[36] = "Not enough power.",
	[37] = "You just can't put this away.",
	[38] = "You bite yourself.",
	[39] = " {#c28569ff}[Locked tip]",
	[40] = "  {#c28569ff}You can't use this item in crafting.",
	[41] = " Screenshot saved ",
	[42] = "You prayed with no result (faith decreased to 0). You had _1_% chance to success. (Confused? Talk to golem).",
	[43] = "You're so tired you started to bleed.",
	[44] = "Inventory is full.",
	[45] = "Equipped weapons are used to calculate damage in combat. You don't have to equip working tools.",
	[46] = '{#3e8948ff}#seed{#ffffffff}'
	

	

	

}


msg.key = 
{
	w = 'Up/Jump',
	s = "Down",
	a = 'Left',
	d = "Right",
	space = 'Dig/pick/drop',
	q = "Pick ground item",
	tab = 'Cycle ground items',
	z = 'Put down selected item from the inventory',
	[']'] = 'Cycle inventory forward',
	['['] = 'Cycle inventory back',
	e = "Attack/examine block",
	r = 'Throw/empty',
	kp8 = 'Cursor up (playing without a mouse)',
	kp2 = 'Cursor down (playing without a mouse)',
	kp6 = 'Cursor right (playing without a mouse)',
	kp4 = 'Cursor left (playing without a mouse)',
	lctrl = "Find similar items on the ground",
	ralt = 'Find all items',
	lalt = 'Find problems in plants',
	rshift = 'Run/Speed up',
	c = 'Craft [k]',
	['return'] = 'Enter/use/consume item [k]',
	i = 'Examine item [k]',
	v = 'Use block',
	f1 = 'Show quest',
	f2 = 'Show diet',
	f3 = 'Self-harm',
	f4 = 'Show keys'
}

msg.keyinfo = [[
-----------------------------------------------------------------
Pay attention to the right menu, it shows the keys you can press.
Some other keys are (can be redefined in start menu):

W,A,S,D - move,
Shift - running/speed up,
Space - dig/drop block (you can press dig+up or dig+down to direct digging),
E or mouse button - attack,
R or mouse button 2 - throw/empty,
1-9 - select an item in the inventory (you can also use mouse wheel and ],[ or +/- keys),
Q - pick ground item, you can also pick ground item by pressing Shift+number,
Left ctrl - highlight items on the ground silimar to selected one in inventory,
Right alt - highlight all items on the ground,
Left alt - show problems with plants.
N - show achievements
[Use mouse wheel here to scroll text]
]]

msg.escmenu = {
	[1] = 'Resume',
	[2] = "Save and quit",
	[3] = "",
	[4] = "Fullscreen",
	[5] = "Double size",
	[6] = "",
	[7] = "Invert stereo",
	[8] = "Volume",
	[9] = "",
	[10] = 'No autosave',
	[11] = "Discord channel",
	}



msg.mapgen = {
	'Generating new map',
	'Filling with dirt',
	'Finding the boy a new home',
	'Home not found, abort the baby',
	'Home found',
	'Writing funny texts instead of a progress bar',
	"Don't you hate when they do this?",
	'Estimated time: unknown',
	'{#d87644ff}*heavy breathing*',
	'AAaalmost done',
	'Done!'
}

msg.combat= {
	'{#d87644ff}MISS',
	'{#d87644ff}BLOCK',
	'{#d87644aa}SLOWED',
	'{#265c42aa}POISONED',
	'{#265c42aa}ON FIRE',
	'{#feae34ff}* BEEP * '

}


msg.stats = 
{
	power = 'power',
	arms = 'grit',
	body = 'body',
	heat = 'heat',
	filth = 'clean',
	food = 'food',
	water = 'water',
	faith = 'faith'

}

msg.gui = 
{
	[1] = '{#fee761ff}V]{#ffffffff} to use',
	[2] = ' ╔═[Equipped]═════════════════════╗',
	[3] = ' ╔═[Inventory]═══════════',
	[4] = "\n{#fee761ff}0] {#ffffffff}Equipped items\n", --na
	[5] = "Food  ",
	[6] = "Water ",
	[7] = "Body  ",
	[8] = "Grit  ",
	[9] = "Clean ",
	[10] = "\n{#fee761ff}0] {#ffffffff}Cycle\n",--na
	[11] = "└────────── {#fee761ff}Q] {#ffffffff}Pick {#fee761ff}Tab] {#ffffffff}Cycle ──┘\n",
	[12] = "└────────────────── {#fee761ff}Q] {#ffffffff}Pick ─────┘\n",
	[13] = "Throw     ",
	[14] = "Put       ",
	[15] = "Consume   ",
	[16] = "Equip     ",
	[17] = "Unequip   ",
	[18] = "┌─[On the ground]────────",
	[19] = "Use       ", --new
	[20] = "Empty     ", --new
	[21] = 'Press {#fee761ff}V]{#ffffffff} to drink\n(_1_% dirty)',
	[22] = "\n{#c0cbdcff}on equip:\n",
	[23] = "{#5a6988ff}0] ",
	[24] = "Examine   ", --new
	[25] = "┌─[Carrying]─────────────────────┐\n",
	[26] = "└────────────────────────────────┘\n",
	[27] = "Use       ", --new
	[28] = "Craft     ", --new
	[29] = "Power ",
	[30] = "Heat  ",
	[31] = "Fertility ",
	[32] = "Moisture  ",
	[33] = "┌─[txt]───────────",
	[34] = "┌─[Crafting]──────",
	[35] = "Mulch     ",
	[36] = '(_1_% dirty)',
	[37] = '{#fee761ff}F1] {#ffffffff}Quest',
	[38] = "└[Score: ",
	[39] = "Total score: ",
	[40] = "Days since last accident: ",
	--[41] = "└ F1] Quest ──── F2] Diet ──── F6] Save ──── F9] Load ",
	[41] = "└ F1] Quest ── F2] Diet ── F3] Self-harm ── F4] Keys ── F5] Screenshot ── F7] Pray ── F8] Achievements ",
	[42] = "Faith ",
	[43] = "Achievements",
	[44] = 'Water (_1_% dirty)',

	

	
	

	
}


msg.gui.diet = {
		veggies =	'│ veggies ',
		fruits =	'│ fruits  ',
		carbs = 	'│ carbs   ',
		protein = 	'│ protein ',
		exotic = 	'│ exotic  ',
		fat =	 	'│ fat     ',
		fish =	 	'│ fish    ',
		[1] = "{#fee761ff}∙{#ead4aaff} _1_{#ffffffff}_2_{#ffffffff}. Eating will restore _8__3_{#b86f50ff}_4_{#0095e9ff}_5_{#ffffffff} _6_ _7_ _9_",
		[2] = '{#5a6988ff}Food efficiency depends on its {#b86f50ff}age{#5a6988ff} and {#0095e9ff}your diet{#8b9bb4ff}:',
		[3] = "{#5a6988ff}Eating same kind of food decreases its value. There's {#feae34ff}2× bonus{#5a6988ff} for a meal you've tasted for 1st time.",
		[4] = "{#fee761ff}∙{#ead4aaff} _1_{#ffffffff}_2_{#ffffffff}. Restored _8__3_{#b86f50ff}_4_{#0095e9ff}_5_{#ffffffff} _6_ _7_ _9_",
		[5] = "",
}

msg.gui.item = 
{
	dps = "dps: ",
	digspeed = "spd: ",
	dighands = "fatigue: ",
	dmg =    'dmg: ',
	dig =    '#dig: ',
	cut =    '#cut: ',
	chop =   '#chop: ',
	smash =  '#smash: ',
	pierce = '#pierce: ',
	water = '#water: ',
	oil = '#oil: ',
	vinegar = '#vinegar:'
}

msg.gui.itemlack = 
{
	dig = '{#ff0044ff}You need a tool with more #dig (_1_) equipped.',
	cut = '{#ff0044ff}You need a tool with more #cut (_1_) equipped.',
	chop = '{#ff0044ff}You need a tool with more #chop (_1_) equipped.',
	smash = '{#ff0044ff}You need a tool with more #smash (_1_) equipped.',
	pierce = '{#ff0044ff}You need a tool with more #pierce (_1_) equipped.',
}

msg.plantproblem = 
{
	[1] = "{#e43b44ff}Too much water",
	[2] = "{#e43b44ff}Needs watering",
	[3] = "{#e43b44ff}Soil is too poor",
	[4] = "{#e43b44ff}Needs light",
	[5] = "{#e43b44ff}Dead",
	[6] = "{#e43b44ff}Frozen",
	[7] = "{#e43b44ff}It can't grow here",
	[8] = "{#e43b44ff}No free space (left)",
	[9] = "{#e43b44ff}Reached full height",
	[10]= "{#e43b44ff}Only grows indoors"
	

}

msg.craft =
{
	[1] = " {#124e89ff}recipes containing {#e8b796ff}_1_{#ffffffff}:\n\n{#8b9bb4ff}  Product ........................[ Reagents (tools) crafting time ]\n\n",
	[2] = " {#124e89ff}using ground and inventory items:\n\n{#8b9bb4ff}  Product ........................[ Reagents (tools) crafting time ]\n\n",
	[3] = "\n\n{#ffffffff}{#fee761ff}W]{#ffffffff},{#fee761ff}S]{#ffffffff} to select, {#fee761ff}Enter]{#ffffffff} to craft, {#fee761ff}C]{#ffffffff} to cancel",

}

msg.dispenser = {
[1] = 'Analyzing... _1_',
[2] = 'Transformation is complete.',
[3] = 'You are standing too close. Move.',
[4] = 'Invalid input.',
[5] = 'Put one item at a time if you want to transform or analyse it.',
[6] = 'The Machine says: {#e4a672ff}',
[7] = 'The Machine provided you some tips: ',
[8] = 'You can bring it to The Machine to unlock some tips (one tip per specimen): ',
[9] = 'The Machine {#feae34ff}can ≈transform≈{#ffffffff} it to something completely different for {#e4a672ff}_1_{#ffffffff} power.',
[10] = "You put {#ead4aaff}_1_{#ffffffff} into The Machine.",
[11] = "I've got no power. Actually I'm very powerful but not at the moment. Come back later.",
[12] = 'You have no quests.',
[13] = '\nCurrent quest:\n',
[14] = '{#63c74dff}There are more tips, bring more of this.',


}

msg.quest = {}
msg.quest[1] = {'Pss, <blank>!', 'Are you in optimal condition down here?', 'Take this vision enhancement.'}

msg.quest[2] = {'You look overdriven.', '', "Resting will increase your lifespan expectancy.", "I'm obligated to say this:","„It's too dangerous to rest alone. Take this“.","Ugh."}

msg.quest[3] = {"On a more personal note, I'm not just an item dispenser, you know.", "I AM THE SOURCE OF KNOWLEDGE.","Bring me something to inspect!","Make me something to inspect.","OK, I believe it's more like a crafting tutorial."}

msg.quest[4] = {"1. Find Ice shard", "2. Break Ice shard", "3. Get loot","4. Figure out how to make use of it", "5. Repeat"}

msg.quest[5] = {"It was observed that “quests” give purpose and involve “players” in dopamine feedback loops increasing desire for more “quests”.", "Look! A quest! A life-changing quest chain.", "Bring me 7 regular stones for no reason at all.","Just pile them all up here together and wait.", "I'll reward you somehow eventually."}

msg.quest[6] = {"Did you like the quest? How would you rate it on a scale from 1 to 10?                  ",
"Say it.                                                                 ",
"...            ",
"So, you're the silent type.             ", 
"I see. I see.                                "}

msg.quest[7] = {"Pss, hey! Yes, you.", "Looks like you're freezing. Avoid stepping on frozen ground and ice with your bare foots.","Get something to wear.","Or you can bring me 3 pyrites and I'll do something about it. ","Just pile them all up here together and wait."}

msg.quest[8] = {
"Hey, those robot shells look really interesting.", 
"Bring me 3 units and I'll try to make something out of it.",
"Just pile them all up here together and wait."
}

msg.quest[9] = {"Do you need a guidance?", "Everyone does.", "Bring me 5 rat tails and I will...","Oh, right, we don't have rats in here, but those pesky stone louses are just as annoying, aren't they? Vermins.","Bring me 5 stingers."}

msg.quest[10] = {"So you're willing to murder and neuter innocent - and probably alive - creatures just because somebody /or something/ told you so?","Noted.                        "}

msg.quest[11] = {"Are you ready to spill some hemolymph?","Bring me 5 chitin plates and I'll reward you as a hero you are.","You have to kill some spiders to get that."}

msg.quest[12] = {
"KILL STUFF.",
"BRING BODY PARTS>",
"YOU'RE IN A CAVE> WHY/                        ",
"...                                     ",
"It wasn't a quest.                                     ",
"I apologize."}

--¯\_(ツ)_/¯ - i2Symbol

msg.quest[13] = {"Your vital functions were consistent for the whole day cycle (28 hours).","Commencing bestowal."}

msg.quest[14] = {"So you talk to *him* but you don't talk to me."}


msg.quest[15] = {"I see you've mined your first copper ore.","The bronze age is near."}


msg.quest[16] = {"Achievements? Don't fool yourself. Yet another way to babysit you.","This game is crap since version 0.10.37."}




msg.buff = {}

msg.buff[1] = { 
name = 'Glowing', 
desc = 'Your body glows in the dark.'
}

msg.buff[2] = { 
name = 'Poisoned', 
desc = 'You are losing health when moving.'
}

msg.buff[3] = { 
name = 'Food poisoning', 
desc = 'You are vomiting and losing water. Stay clean and eat cooked fresh food to avoid it next time.'
}

msg.buff[4] = { 
name = 'Farsight', 
desc = 'You are seeing through space and probably time. Light is still required though.'
}


msg.buff[5] = { 
name = 'Slowed', 
desc = 'You are sloooowed.'
}

msg.buff[6] = { 
name = 'On fire', 
desc = 'You are on fire (not literally).'
}

msg.buff[7] = { 
name = 'Bleeding', 
desc = 'You are slowly losing blood.'
}

msg.buff[8] = { 
name = 'Dark vision', 
desc = 'You see in the dark better than usual.'
}

msg.buff[9] = { 
name = 'Blessing', 
desc = "You dig faster for no apparent reason."
}

msg.buff[10] = { 
name = 'Meteorism', 
desc = "You have a speed of a meteor and can do double jumps now."
}

msg.buff[11] = { 
name = "Ketchup'd", 
desc = "Your next meal will have 100%% efficiency."
}

msg.buff[12] = { 
name = "Chills", 
desc = "You feel uneasy."
}

msg.buff[13] = { 
name = "Webbed", 
desc = "You can't jump."
}

msg.buff[14] = { 
name = "Well fed", 
desc = "You ate properly cooked food and feeling good now."
}

msg.buff[15] = { 
name = "Fever", 
desc = "You feel weak."
}

msg.buff[16] = { 
name = "Diarrhoea", 
desc = "Cha cha cha."
}

msg.buff[17] = { 
name = "Dizziness", 
desc = "You can't think straight. Avoid operating heavy machinery and climbing ladders."
}

msg.buff[18] = { 
name = "Submerged", 
desc = "You can't jump in the water."
}

msg.buff[19] = { 
name = "Holding breath", 
desc = "By the way, you can't swim."
}

msg.buff[20] = { 
name = "Suffocating", 
desc = "You're kind of dying right now."
}


msg.buff[21] = { 
name = "Doctor ward", 
desc = "An apple a day keeps the doctor away."
}

msg.buff[22] = { 
name = "Warpaint", 
desc = "You look scary now and inflict +1 whooping damage."
}

msg.buff[23] = { 
name = "Bandaged", 
desc = "You are recovering health."
}

msg.buff[24] = { 
name = "Good boy!", 
desc = "You are feeling gratification."
}

msg.buff[25] = { 
name = "Hoarding", 
desc = "Anything you can carry!"
}

msg.buff[26] = { 
name = "Coprophagous", 
desc = "It's just a matter of taste."
}

msg.buff[27] = { 
name = "Bad eating habits", 
desc = "Check the diet."
}

msg.item = {}

msg.item[1] = { name = 'Glowing seed', 
info = "It's shaped like a seed and glowing in the dark. It's a glowing {#3e8948ff}seed{#ffffffff}, all right. You should try to {#3e8948ff}bury{#ffffffff} it in a fertile ground.\nThis plant will require: {#e8b796ff}[+] loam {#5a6988ff}[-] light {#5a6988ff}[-] water {#5a6988ff}[-] fertilization.",

}

msg.item[2] = { name = 'Stick', 
info = "",
transform = "Let's make the metaphor complete.",}

msg.item[3] = { name = 'Foliage', 
info = "It's mostly leaves, stems and other parts of various plants.",
tips = {
'So, you managed to grow something! Good for you.',
'You can turn it into hay by drying it. Heat speeds up drying.',
'You can feed it to worms and even make a worm farm, but this one is tricky. Observe worms behavior.'
}
}

msg.item[4] = { name = 'Glowing root', 
info = "It will regrow into a glower if buried."
}

msg.item[5] = { name = 'Stone', 
info = "Heavy and strong, it's the most primitive tool of all. It can #dig and #smash. Other tools can also #pierce and #cut. Different jobs require different tools. Right tools are auto-picked from your inventory. (It means you should carry at least one stone with you)."}

msg.item[6] = { name = 'Worm', 
info = "It's alive and trying to escape.",
transform = "By the power of free association!"}

msg.item[7] = { name = 'Beans',
info = "Some kinds of raw beans contain a harmful tasteless toxin, lectin phytohaemagglutinin, that must be removed by cooking. \nThis plant will require: {#e8b796ff}[+] loam [+] light {#5a6988ff}[-] water {#5a6988ff}[-] fertilization."}

msg.item[8] = { name = 'Clay', }

msg.item[9] = { name = 'Giant weed nut',
info = "It's as big as a human head so you decided to call it a nut. Fun fact: it's actually a {#3e8948ff}seed{#ffffffff}. \nThis plant will require: {#e8b796ff}[+] loam [+] light {#5a6988ff}[-] water {#5a6988ff}[-] fertilization.",
tips = {"Beware of the falling nuts.","Weed is a totally legal and valuable source of weed fiber."}
}

msg.item[10] = { name = 'Sharp stone', }
msg.item[11] = { name = 'Bone', }
msg.item[12] = { name = 'Skull',
info = "This skull is a restless spirit and an old soul.",
transform = "Oh! Spooky!",
txt = {'A skull on the ground is awakened.'}
}
msg.item[13] = { name = 'Sinew', 
info = "It's a string-like body tissue that can be used in crafting to hold things together."}

msg.item[14] = { name = 'Raw meat', 
info = "So raw and uncut.",
tips = {'You can feed it to a spider.',
'Long live the new flesh!'}}

msg.item[15] = { name = 'Twig',
info = "It's a small flexible stick."}

msg.item[16] = { name = 'Liana', }
msg.item[17] = { name = 'Token Of Value',
desc = 'Bring it to The Machine', }

msg.item[18] = { name = 'Amoeba',
info = "Light-loving flying creature."
}

msg.item[19] = { name = 'Stone hammer', 
info = "Hammer smash!"}

msg.item[20] = { name = 'Feces', 
info = "It's yours.",
txt = {'You ate a little piece of - well - shit.'}}

msg.item[21] = { name = 'Gold bar', }

msg.item[22] = { name = 'Bread', }

msg.item[23] = { name = 'Apple', 
info = "(Fruit)."}

msg.item[24] = { name = 'Basket', 
info = "Equip: inventory size increased (+5)."}

msg.item[25] = { name = 'Firenut',
info = "It's glowing with soft reddish light. You wonder if it's edible.\nThis plant will require: {#e8b796ff}[+] loam {#5a6988ff}[-] {#5a6988ff}light {#5a6988ff}[-] water {#5a6988ff}[-] fertilization."
}

msg.item[26] = { name = 'Flashlight', 
transform = "Recharged",
}

msg.item[27] = { name = 'Drained flashlight',
info = "It can be recharged if you bring it to The Machine.",
transform = "Fully recharged",
}

msg.item[28] = { name = 'A glowing „fruit“', 
info = "Yes, A Glowing Fruit. Do you have come up with a better idea for the name? Caveapple? Fuck you."
}

msg.item[29] = { name = 'Flint', 
info = "Flint is a form of quartz, a strong material prone to fragmentation.",
tips = {'You can feed it (and some other stones) to a stone louse.'}
}

msg.item[30] = { name = 'Adze',
info = "An adze is a #chopping and #digging tool similar to an axe but with the edge perpendicular to the handle rather than parallel. It's really a thing, google it.", }

msg.item[31] = { name = 'Small stone', 
info = "It has a perfect size for throwing. So... what else?"}

msg.item[32] = { name = 'Nanoblock',
info = "It's a high-tech looking cube about 7 cm in height. It has a label that says ‘Throw me’"
}

msg.item[33] = { name = 'Charcoal', }


msg.item[34] = { name = 'Big Fucking Stone',
info = 'So heavy, much stone.', }

msg.item[35] = { name = 'Instant water',
info = "The essence of wetness.", }

msg.item[36] = { name = 'Pyrite',
info = "An iron sulfide.",
tips = {
'The name pyrite is derived from the Greek πυρίτης (pyritēs), "of fire" or "in fire". It can be used to make an item that starts a fire (obviously). Just dig more stones.',
'You can extract a sulfur from it (using crucible).'
},
craft = 'You made a lots of sparks and destroyed pyrite.' 
}

msg.item[37] = { name = 'Hay',
info = "There's a beauty in every blade of grass - you just have to look. On a more practical note - it's flammable and can be used as a tinder."}

msg.item[38] = { name = 'Clover seed',
info = 'This plant will require: {#e8b796ff}[+] loam [+] light {#5a6988ff}[-] water {#5a6988ff}[-] fertilization.' }

msg.item[39] = { name = 'Needle', 
info = "This needle needs a pair: a thread."
}

msg.item[40] = { name = 'Ice chunk',
info = "You can turn it into water by the miracle of melting.",
tips = {'Dig a hole. Put it into the hole. Wait.'}}

msg.item[41] = { name = 'Fire starter', 

info = "Use it to start a fire. It's twisted.",
txt = {'You need a tinder (something highly flammable on the ground)',
	'You need an empty space.'}
}

msg.item[42] = { name = 'Wire', }

msg.item[43] = { name = 'Big fucking log', }

msg.item[44] = { name = 'Slug corpse', }
msg.item[45] = { name = 'Corpse',
info = "It looks almost like a real person but a bit less self-centered.",
tips = {"I'll deny everything."} 
}

msg.item[46] = { name = 'Coal', }
msg.item[47] = { name = 'Jug (empty)'}
msg.item[48] = { name = 'Jug (water)',
info = "Counts as #water source in crafting."}
msg.item[49] = { name = 'Jug (raw)',
info = "It's raw and must be fired first." }
msg.item[50] = { name = 'Ceramic scraps', }
msg.item[51] = { name = 'Jug (sand)', 
info = "It's heavy.",
tips = {'Sand is the best base material for aquariums and artificial ponds.'}
}

msg.item[52] = { name = 'Carrot seed', }
msg.item[53] = { name = 'Carrot',
info = "This plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization." }
msg.item[54] = { name = 'Skull cup (empty)',
info = 'Can be used as a drinking cup. Stylish too. ' }
msg.item[55] = { name = 'Skull cup (water)', }
msg.item[56] = { name = 'Pot (empty)',
info = "It's a half of the weed nut shell that can be used as a pot. Pot can hold enough water for cooking or taking long trips." }
msg.item[57] = { name = 'Pot (water)', 
info = "",
craftinfo = 'You can boil water to clean it.'
}
msg.item[58] = { name = 'Bone dust', }
msg.item[59] = { name = 'Fertilizer',
info = 'You can apply it to a soil to make it more fertile.',
tips = {"It's your bread and butter for gardening although it's made mostly of shit.",
"You can get fertilizer from worm bins.",
"Some plants (clover and beans) slowly make the soil more fertile just by growing on it.",
"Mulch increases fertilizer efficiency (actually, it decreases fertilization decay)."
},

txt = {'You applied fertilizer to the ground.',"You can't fertilize the ground you're standing on."}
}

msg.item[60] = { name = 'Copper ore', 
tips = {'Try to throw it into the fire and wait.'}
}

msg.item[61] = { name = 'Mulch', 
info = "It's a layer of organic material applied to the surface of soil. Reasons for applying mulch include conservation of soil moisture and improving fertility and health of the soil.",
txt = {'You applied mulch to the ground.',"You can't apply mulch to the ground you're standing on.","You can't apply any more mulch here."},
}

msg.item[62] = { name = 'Brick (raw)',
craftinfo = "If you're still unable to make bricks by shitting them there's more conventional way.",
info = "Just throw it into the fire." }

msg.item[63] = { name = 'Brick', }
msg.item[64] = { name = 'Limestone', }
msg.item[65] = { name = 'Fossil', }
msg.item[66] = { name = 'Crucible (raw)',
info = "A container in which metals or other substances may be melted or subjected to very high temperatures. Must be fired first.",
tips = {"Here is a very generous tip: C-shaped cob furnace."}
}
msg.item[67] = { name = 'Crucible (empty)', }
msg.item[68] = { name = 'Crucible (copper ore)',
info = "Put it in a warm place. Really warm." }
msg.item[69] = { name = 'Crucible (copper & tin)', 
info = "Melt it together to make bronze."
}
msg.item[70] = { name = 'Crucible (tin ore)', 
info = "Melt it together to make tin."
}
msg.item[71] = { name = 'Crucible (limestone)', 
info = "Melt it to make a cement."}
msg.item[72] = { name = 'Crucible (coal)', 
info = "Making coke (* - not a drug or a drink)."}
msg.item[73] = { name = 'Crucible (copper)', 
info = ""}
msg.item[74] = { name = 'Crucible (bronze)', }
msg.item[75] = { name = 'Crucible (tin)', }
msg.item[76] = { name = 'Crucible (cement)', }
msg.item[77] = { name = 'Crucible (coke)', }
msg.item[78] = { name = 'Tin ore', }
msg.item[79] = { name = 'Copper bar', }
msg.item[80] = { name = 'Tin bar', }
msg.item[81] = { name = 'Crucible (pyrite)',
info = "Making sulfur." }
msg.item[82] = { name = 'Crucible (sulfur)', }
msg.item[83] = { name = 'Crucible (bronze & gold)', 
info = "Melt it together to make tumbaga (a mysterious metal)."}
msg.item[84] = { name = 'Crucible (tumbaga)', }
msg.item[85] = { name = 'Bronze bar', }
msg.item[86] = { name = 'Tumbaga bar', }
msg.item[87] = { name = 'Coke', }
msg.item[88] = { name = 'Sulfur', }

msg.item[89] = { name = 'Web', 
}
msg.item[90] = { name = 'Web piece', 
info = "It's too short to be useful."
}

msg.item[91] = { name = 'Pumpkin', }
msg.item[92] = { name = "Jack-o'-lantern", }
msg.item[93] = { name = 'Pumpkin piece', }
msg.item[94] = { name = 'Pumpkin seed', 
info = 'This plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization.'}
msg.item[95] = { name = 'Broken bone', }
msg.item[96] = { name = 'Spike',
info = "It's a very sharp and unusually hard thorn about 5 cm long." }
msg.item[97] = { name = 'Apple seed', 
info = 'This plant will require: {#e8b796ff}[+] rich soil [+] light [+] water {#5a6988ff}[-] fertilization.',
tips = {'It requires soil (not loam) to germinate.'}
}
msg.item[98] = { name = 'Magic beans', }
msg.item[99] = { name = 'Huge worm', }
msg.item[100] = { name = 'Corn seed',
info = 'This plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization.'}
msg.item[101] = { name = 'Grappling hook',
info = "А long sturdy hemp rope tied to a hook. *Very* useful for rock climbing. ",}
msg.item[102] = { name = 'Mushroom', }
msg.item[103] = { name = 'Spider corpse', }

msg.item[104] = { name = 'Spidersilk thread',
info = "It's a thin and extremely strong thread."
}


msg.item[105] = { name = 'Timber',
info = "It's a processed wood ready to be used in woodworking. (You can also burn it).",}
msg.item[106] = { name = 'Wooden handle',
info = "A tool is as good as its handle."}
msg.item[107] = { name = 'Wood shavings',
info = 'As they say, лес рубят - щепки летят.' }
msg.item[108] = { name = 'Firewood',
info = "This piece of wood is ruined and can only be used as a fuel. Unless you were trying to make a firewood on purpose, good job then!"
}

msg.item[109] = { name = 'Moss',
info = "It's a wet sponge-like organic matter.",
}

msg.item[110] = { name = 'Dry moss',
info = "It's a sponge-like organic matter, very soft and tender.",
use = "Nothing happened.",
tips = {
'You can use it to stop bleeding.'
}
}

msg.item[111] = { name = 'Peat',
info = "It's flammable."
}

msg.item[112] = { name = 'Berries',
info = ""
}

msg.item[113] = { name = 'Bog-berry seed',
info = "This plant will require: {#e8b796ff}[+] peat [+] patience {#5a6988ff}[-] light [-] water [-] fertilization.",
tips = {"It grows in peat."}
}

msg.item[114] = { name = 'Dead pixel',
info = "This plant will require: {#e8b796ff}[?] ####",
}

msg.item[115] = { name = 'A pinch of salt',
info = "Then you took your time trying to find something meaningful in examining a salt."}

msg.item[116] = { name = 'Burned meat',
info = "Exceptionally terrible. You have to find some other means to cook it."}

msg.item[117] = { name = 'Salt-cured meat',
info = "It won't spoil easily but will leave you thirsty."}

msg.item[118] = { name = 'Clay-covered meat',
info = "Throw it in the fire."}

msg.item[119] = { name = 'Clay-roasted meat',
info = "Surprisingly soft and tasty."}

msg.item[120] = { name = 'Apple log'}
msg.item[121] = { name = 'Ruined ore',
info = "That's not how you smelt an ore. It should inspire you to do things differently next time."}

msg.item[122] = { name = 'Water chip',
info = "Great, yet another video game reference. So meta."}

msg.item[123] = { name = 'G.E.C.K.',
info = "It's a closed briefcase with big letters on its side."}

msg.item[124] = { name = 'Shovel',
info = 'Equip: you dig faster with less fatigue.'}
msg.item[125] = { name = 'Briefcase',
info = "Equip it to increase inventory size (+7)"}

msg.item[126] = { name = 'Corn'}
msg.item[127] = { name = 'Popcorn'}

msg.item[128] = { name = 'Copper knife',
info = "Equip: +haste"}
msg.item[129] = { name = 'Bronze knife',
info = "Equip: +haste"}
msg.item[130] = { name = 'Tumbaga knife',
info = "Equip: +haste"}

msg.item[131] = { name = 'Gold ore'}
msg.item[132] = { name = 'Crucible (gold ore)',
info = "Melt it to make gold, sweet precious gold."}
msg.item[133] = { name = 'Crucible (gold)'}

msg.item[134] = { name = 'Copper axe'}
msg.item[135] = { name = 'Bronze axe'}
msg.item[136] = { name = 'Tumbaga axe'}

msg.item[137] = { name = 'Copper hammer',
info = "Equip: +body"}
msg.item[138] = { name = 'Bronze hammer',
info = "Equip: +body"}
msg.item[139] = { name = 'Tumbaga hammer',
info = "Equip: +body"}

msg.item[140] = { name = 'Copper pickaxe',
info = "Equip: +grit"}
msg.item[141] = { name = 'Bronze pickaxe',
info = "Equip: +grit"}
msg.item[142] = { name = 'Tumbaga pickaxe',
info = "Equip: +grit"}

msg.item[143] = { name = 'Nails',
info = "They're about 9 inches long."}
msg.item[144] = { name = 'Spear'}

msg.item[145] = { name = 'Spiked club'}
msg.item[146] = { name = 'Weighted club'}

msg.item[147] = { name = 'Hemp fiber'}

msg.item[148] = { name = 'Ruined fiber',
craftinfo = 'Fiber extracted from the twig by smashing it. You feel it is important somehow.',
info = 'Small fragmented pieces of fiber that are useless. You have to find some other ways to extract a fiber from this godsend plant.',
tips = {
"Aww, you helpless little bastard. Try retting twigs (soak them in water for a long period of time).",
"You can use it as a tinder.",
}
}

msg.item[149] = { name = 'Hemp thread',
info = "It's too thick to be used for sewing but perfect for making ropes."}

msg.item[150] = { name = 'Rope',}

msg.item[151] = { name = 'Spider leg',
info = "This giant spider leg is covered in hooks and spikes.",
}

msg.item[152] = { name = 'Hook',}
msg.item[153] = { name = 'Wooden frame',}

msg.item[154] = { name = 'Weed nut kernel',
info = "It's an oily substance with rich earthy smell.",
eat = "Ewww. It's not really an edible."
}

msg.item[155] = { name = 'Pot (hemp oil)',
info = "Used in cooking."}

msg.item[156] = { name = 'Gardening manual',
txt = "You read the fucking manual and learned some things:\n- To plant a seed you must bury it *in* a fertile ground.\n- Almost all plants need light.\n- Some plants need water (a plant will inform you).\n- Some plants deplete the soil and stop growing.\n- Some plants (clover and beans) slowly make the soil more fertile just by growing on it.\n- There is a right time to gather plants (yellow is for eating, orange is for the seeds)."
}

msg.item[157] = { name = 'Plastic',}

msg.item[158] = { name = 'Soap',
info = "Did the joke went too far? Return it to The Machine.",
transform = "Here is another matching item for the rope.",
}


msg.item[159] = { name = 'Chitin plate',}
msg.item[160] = { name = 'Venom sack',}
msg.item[161] = { name = 'Spider eyes',}
msg.item[162] = { name = 'frostie meat',
info = "It feels hot to the touch yet looks fresh."}
msg.item[163] = { name = 'frostie shell',
info = "This one is not made of calcium."}

msg.item[164] = { name = 'Snake nut can',
info = "A practical joke device that closely resembles a can of nuts, but contains... a snake!"
}

msg.item[165] = { name = 'Dead snake',}
msg.item[166] = { name = 'Snake leather',
info = 'You can make fancy leather clothes with this (just need a thread and needle).'}
msg.item[167] = { name = 'Snake fang',}
msg.item[168] = { name = 'Bone pickaxe',}
msg.item[169] = { name = 'Needle and thread',
craftinfo = "„Where can I find a needle?“",
info = "Sewing kit. You'll need that to make clothes."}

msg.item[170] = { name = 'Snake leather boots',
info = "These boots are made for walking. Equip: +haste"
}


msg.item[171] = { name = 'Manna',
info = "It's a fine, flake-like thing."}
msg.item[172] = { name = 'Cactus piece',
info = 'You can replant it in a proper growing medium.'}
msg.item[173] = { name = 'Dragonfruit' }
msg.item[174] = { name = 'Cactus seed',
info = 'This plant will require: {#e8b796ff}[+] sand [+] light {#5a6988ff}[-] water [-] fertilization.'}
msg.item[175] = { name = 'Chard'}
msg.item[176] = { name = 'Chard seed',
info = "This plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization."}
msg.item[177] = { name = 'Bone axe'}
msg.item[178] = { name = 'Copper shovel',
info = 'Equip: you dig faster with less fatigue.'}
msg.item[179] = { name = 'Bronze shovel',
info = 'Equip: you dig faster with less fatigue.'}
msg.item[180] = { name = 'Tumbaga shovel',
info = 'Equip: you dig faster with less fatigue.'}
msg.item[181] = { name = 'Bowl (raw)',
info = "Some food just can't be served without a bowl, you are a civilized man after all. Bowl must be fired first."}
msg.item[182] = { name = 'Bowl',
info = "Some food just can't be served without a bowl, you are a civilized man after all."}

msg.item[183] = { name = 'Wet ectoplasm',
info = "\nThis „plant“ will require: {#e8b796ff}[+] dirt {#5a6988ff}[-] burying [-] light [?] water [-] fertilization.",
tips = {"It's a living thing. Unlike #seed you can just put in on the dirt and it will start to grow on it."}
}
msg.item[184] = { name = 'Dry ectoplasm',
info = "It's a white dandruff-like substance. It's not wet.",
tips = {"It's dry. make it wet, but it's dry now. D-R-Y."}
}

msg.item[185] = { name = "Bin (raw)",
info = "A general purpose container. Must be fired before use."}

msg.item[186] = { name = "Bin (empty)"}
msg.item[187] = { name = "Revitalizer",
info = "It transforms dirt into soil.",
txt = {'You applied Revitalizer to the ground.',"You can't revitalize the ground you're standing on."}
}

msg.item[188] = { name = "Rice portion"}
msg.item[189] = { name = "Rice seed",
info = 'This plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization.'}
msg.item[190] = { name = "Tomato"}
msg.item[191] = { name = "Tomato seed",
info = "This plant will require: {#e8b796ff}[+] loam [+] indoors [+] light [+] water [+] fertilization.",
tips = {"This delicate plant grows only indoors and you'll need a door to make in-doors. Am I subtle enough?"}
}

msg.item[192] = { name = "Cave jelly"}

msg.item[193] = { name = "Hearthstone",
info = 'Use: Returns you to The Crossroads. Speak to an Innkeeper in a different place to change your home location.'}


msg.item[194] = { name = "Seaweed",
info = 'An edible algae.',
tips = {
"You can't replant this and there's no seaweed sead, but you can move and replant the whole plant, just don't drop it on a dry land.",
"Do you know you can make a worm farm just by... oh, wait, wrong tip. You can also build a seaweed farm in an artificial pond. Actually, you can farm just about every living thing."}
}

msg.item[195] = { name = "Piupiu skirt",
info = "Equip: You feel more secure with your delicate parts protected. (+Grit)." }



msg.item[196] = { name = "Sugar beet seed",
info = 'This plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization.'
}
msg.item[197] = { name = "Sugar beet" }
msg.item[198] = { name = "Sugar",
info = "They say it's as addictive as cocaine but 8 times sweeter."}
msg.item[199] = { name = "Vinegar" }


-- food
msg.item[200] = { name = "Sarma" }
msg.item[201] = { name = "Meat dolma" }
msg.item[202] = { name = "Rice flour" }
msg.item[203] = { name = "Corn flour" }
msg.item[204] = { name = "Cooked rice" }
msg.item[205] = { name = "Golubtsi" }
msg.item[206] = { name = "Fresh tomato salad" }
msg.item[207] = { name = "Wood ash" }
msg.item[208] = { name = "Crucible (sand)",
info = "Melt it to make glass."
} --162
msg.item[209] = { name = "Crucible (glass)"} --163
msg.item[210] = { name = "Bottle",
info = "Do I have to explain what bottle is? Oh well you can make pickled food and store it in a bottle."}
msg.item[211] = { name = "Bin (apple cidre)"}
msg.item[212] = { name = "Apple cidre"}


msg.item[213] = { name = "Pickled carrot"}
msg.item[214] = { name = "Pickled tomatoes"}
msg.item[215] = { name = "Pickled worms"}
msg.item[216] = { name = "Pickled shrooms"}
msg.item[217] = { name = "Nixtamalized corn"}
msg.item[218] = { name = "Bogberry jam"}


msg.item[219] = { name = "Pumpkin & beans soup"}
msg.item[220] = { name = "Grilled pumpkin"}
msg.item[221] = { name = "Candied pumpkin"}
msg.item[222] = { name = "Pumpkin pie"}
msg.item[223] = { name = "Vegan soup"} 


msg.item[224] = { name = "Carrot & apple salad"}
msg.item[225] = { name = "Vegeterian pilaf"}
msg.item[226] = { name = "Pilaf"}
msg.item[227] = { name = "Grilled carrot"}
msg.item[228] = { name = "„Beef“ stew"}


msg.item[229] = { name = "Apple nut salad"}
msg.item[230] = { name = "Apple pie"}
msg.item[231] = { name = "Fruit salad"}
msg.item[232] = { name = "Apple stew"} 

msg.item[233] = { name = "Giant chilli",
info = "It's a phallic symbol, you know."}
msg.item[234] = { name = "Dry chilli"}
msg.item[235] = { name = "Chilli seed",
info = 'This plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization.',
tips = {"It takes a lot of balls to grow chilli"}}
msg.item[236] = { name = "Chilli powder"}

msg.item[237] = { name = "Ketchup",
info = "Everything is better with a ketchup."
}

msg.item[238] = { name = "Tortilla"}
msg.item[239] = { name = "Rice noodles"}
msg.item[240] = { name = "Grilled corn"}
msg.item[241] = { name = "Corn and tomato soup"}

msg.item[242] = { name = "Refried beans"}
msg.item[243] = { name = "Chilli beans"}
msg.item[244] = { name = "Cooked beans"}

msg.item[245] = { name = "Tortilla soup"}
msg.item[246] = { name = "Tortilla chips"}
msg.item[247] = { name = "Nachos"}

msg.item[248] = { name = "Sweet pitha"}
msg.item[249] = { name = "Chili con carne"}

msg.item[250] = { name = "Crispy breaded worms"}
msg.item[251] = { name = "Deep fried worms"}
msg.item[252] = { name = "Worms'n'noodles"}

msg.item[253] = { name = "Fruit jelly"}
msg.item[254] = { name = "Steak"}
msg.item[255] = { name = "Quesadilla"}

msg.item[256] = { name = "Vegan burrito"}
msg.item[257] = { name = "Burrito"}
msg.item[258] = { name = "Salsa"}

msg.item[259] = { name = "Fried dragonfruit"}
msg.item[260] = { name = "Laghman"}

msg.item[261] = { name = "Cheburek"}
msg.item[262] = { name = "Pickled chard"}
msg.item[263] = { name = "Power shard",
info = "It looks exactly like AAAA battery without any marking. And yes, it's negative power on transformation.",
transform = "Power overwhelming!"}

msg.item[264] = { name = "Stone pouch (empty)",
info = "You can put stones inside."}
msg.item[265] = { name = "Stone pouch"}

msg.item[266] = { name = "Spider omelette" }

msg.item[267] = { name = "Filth colon",
info = 'Elastic but very unstable substance.',
tips = {"You should never store valuable items on the ground (try stonework blocks)",
"Filth colon can't undermine you from within if you're in the room."}
}

msg.item[268] = { name = "Cured intestine",
info = 'Rubber-like organic matter.'}

msg.item[269] = { name = "Snake skin"}
msg.item[270] = { name = "Sling",
info = "Equipped: Increases range while throwing small stones and bullets."}
msg.item[271] = { name = "Sling +1",
info = "Equipped: Increases range while throwing stones and bullets."}

msg.item[272] = { name = "Chitin armor",
info = "Equip: Reduces damage by 20%%."}

msg.item[273] = { name = "Stone louse corpse"}
msg.item[274] = { name = "Stinger"}
msg.item[275] = { name = "Spider egg",
info = "An egg is an egg, right?"}
msg.item[276] = { name = "Throwing web",
info = "Slows monsters down."}
msg.item[277] = { name = "Kidney",
info = "Is it even legal? You belive it has some other value besides nutritional."}

msg.item[278] = { name = "Poisonous stinger",
info = ''}

msg.item[279] = { name = "Pwned worm",
info = "Wow, you really showed it, but it's more useful to can capture worms alive.",
tips = {
'You can pick worms (and some other creatures) without killing them using dig key.',
'You can put worms in a can. Yes, you can. But people have been putting worms in a bin.',
"You should craft a worm bin, dummy. Yet you can also craft a worm can. It's a tip, allright?"}
}

msg.item[280] = { name = "Robot shell",
info = "Almost impenetrable metal box with tiny sharp legs. It does not look alive.",
tips = {"What? I have nothing to do with this."}
}

msg.item[281] = { name = "Fire's hot: a manual",
info = "Theory is great, but this manual is also a piece of paper you can use to start a fire. What a coincidence!",
txt = "You read the fucking manual and learned some things:\n- To start a fire you need something highly flammable. You can add other fuel to the tinder.\n- Some burning things produce more heat than others.\n- Melting points of things also differer. \n- To melt something you must build a furnace (like a little room) using blocks with low thermal conductivity to keep a heat inside."
}

msg.item[282] = { name = "Crunchy spider legs"}

msg.item[283] = { name = "Rope belt",
info = "It's an ingenious device to hold pants up. If you don't have pants it can also hold tools and items. (+3 to inventory size)."
}

msg.item[284] = { name = "Headlight"}
msg.item[285] = { name = "Drained headlight"}


msg.item[286] = { name = 'Apple timber',
info = "It's a processed wood ready to be used in woodworking. (You can also burn it).",}
msg.item[287] = { name = 'Masterwork handle',
info = 'It has a smell of an apple wood.'}
msg.item[288] = { name = 'Quarterstaff'}

msg.item[289] = { name = 'Fishing pole',
info = "To catch a fish search for fish schools in water.",
txt = {
'To start fishing you must stand on a dry shore near a water pool.',
'Water not found',
'{#0095e9ff}Looking for fish',
'{#0095e9ff}Fish found, waiting for fish to hook up',
'{#0095e9ff}You missed the fish. Use (U) the fishing pole when the bobber goes down.',
'{#0095e9ff}You missed the fish.',
'{#0095e9ff}You caught something.',
'{#0095e9ff}You need a worm as a bait.',
'{#0095e9ff}There is no fish here.',
}
}

msg.item[290] = { name = 'Cavebass',
info = "Fish also known as Dinopercidae."
}

msg.item[291] = { name = 'Spicy fish stew' }
msg.item[292] = { name = 'Grilled fish' }
msg.item[293] = { name = 'Sushi' }
msg.item[294] = { name = "Fisherman's pie"}
msg.item[295] = { name = "Fish with noodles"}
msg.item[296] = { name = "Four weeds salad"}
msg.item[297] = { name = "Seaweed salad"}
msg.item[298] = { name = "„Sesame seeds“ bread"}


msg.item[299] = { name = "Empty can",
info = "You can put worms inside."}
msg.item[300] = { name = "Can of worms",
info = "Literally a can of worms, not a variation of Pandora's box."}


msg.item[301] = { name = "Craftable mass",
info = "You should _craft_something_."}

msg.item[302] = { name = "Something to inspect",
craftinfo = "You should craft it and bring it to The Machine for the inspection. It's a 5-minute craft that requires a stone (#smash).",
info = "You {#fee761ff}should{#ffffffff} bring it to the Machine.",
tips = {'Receiving new tips from The Machine restores <her> power, because knowledge is power or maybe because she loves to be useful.'}
}


msg.item[303] = { name = "Philosopher's stone",
info = "Like a regular stone, but smarter.",
txt = 'The stone said: {#e4a672ff}„Death is the most certain possibility“.'
}

msg.item[304] = { name = "Clay bullet (raw)",
craftinfo = 'You can literally throw excessive clay away. Must be fired (turned into ceramics) after the craft.',
info = "You should fire it. As in firing ceramics."
}

msg.item[305] = { name = "Ceramic bullet",
info = "Fragile but deadly throwing bullet. "
}

msg.item[306] = { name = 'Crude spear'}

msg.item[307] = { name = 'Sense of direction',
txt = {'It is silent.','This way: '}
}

msg.item[308] = { name = 'Tail trimmer',
info = "Only for cutting tails off."
}

msg.item[309] = { name = 'Pet rock',
info = "Yes, you can keep it."
}

msg.item[310] = { name = "Spinner corpse" }

msg.item[311] = { name = "Silk",
info = "It's as soft as itself. It can be used to make clothes."}

msg.item[312] = { name = "Skintight trousers",
info = "Equip: makes you jump higher. Look out, here comes the spidersilk." }

msg.item[313] = { name = "Slick gloves",
info = "Equip: reduces crafting time by 10%%." }

msg.item[314] = { name = "Breathing T-shirt",
info = "Equip: reduces fatigue from digging." }

msg.item[315] = { name = "Silk bandage",
info = "Stops bleeding and speeds up recovery." }

msg.item[316] = { name = "Silk socks",
info = "Equip: rest quality increased." }

msg.item[317] = { name = "Copper sword"}

msg.item[318] = { name = "Antidote",
info = "Removes poison."}

msg.item[319] = { name = "Sting"}

msg.item[320] = { name = "Wormhole generator",
info = "Returns you to the Machine for 5 power."}

msg.item[321] = { name = "Four leaf clover",
info = "It's so random."}

msg.item[322] = { name = "Lucky charm",
info = "Made of gold. Equip: 7%% chance to prevent damage.",
txt = {'Lucky save'}
}

msg.item[323] = { name = "Abdominal armor",
info = "Equip: Reduces damage by 10%%."}

msg.item[324] = { name = "Kiribati armor",
info = "Equip: Reduces damage by 1 (if it's more than 1)."}

msg.item[325] = { name = "Copper armor",
info = "Equip: Reduces damage by up to 25%%. Reduces inventory size by 2 because of loss of some pockets, what's why."}

msg.item[326] = { name = "LED",
info = "Also known as light-emitting diode."}

msg.item[327] = { name = "Hand grenade",
info = "Impact = assplode."}

msg.item[328] = { name = "Bouncing grenade",
info = "Bounces off the walls and explodes."}

msg.item[329] = { name = "Grenade shell (raw)",
info = "Must be fired first. It's a component to make grenades (obviously)."}
msg.item[330] = { name = "Grenade shell",
tips = {"Grenades can be used for mining stuff without meeting the tool requirements, insta-killing stuff, fubar'ing the base and performing spectacular suicides."}}



msg.item[331] = { name = "Broth",
info = "Soup so simple it can't be ruined. You still can call it consommé though.",
tips = {'It cures fever'}
}

msg.item[332] = { name = "Haed assploded" }

msg.item[333] = { name = "Tuber",
info = "U-shaped tuber with a sour taste. You can even call it U-tuber, I won't judge. It's probably edible despite being visually unappealing.\nThis plant will require: {#e8b796ff}[+] loam [+] light [+] water [+] fertilization.'",
tips = {"Where did you get that? You'd want to cook it just to be safe."}
}

msg.item[334] = { name = "Baked tuber",
info = ""}
msg.item[335] = { name = "Effs",
info = "Short for „Existential Freedom Fries“."}
msg.item[336] = { name = "Mashed tuber" }
msg.item[337] = { name = "Steak & fries" }


msg.item[338] = { name = "Tough cookie" }
msg.item[339] = { name = "Instant chest" }
msg.item[340] = { name = "Survival t-shirt",
info = "It's lousy." }

msg.item[341] = { name = "Playperson magazine",
info = "It is filled with non-offensive gender-neutral articles." }

msg.item[342] = { name = "Blink dagger",
craftinfo = 'Teleports you on short distances.',
info = "„Throw me“." }

msg.item[343] = { name = "Shrapnel grenade",
craftinfo = "Does no damage to blocks, only to living creatures.",
info = "„Shrapnel was invented by an Englishman of the same name. Don't you wish you could have something named after you?“ - Kurt Vonnegut"}


msg.item[344] = { name = "Cry'o'genic device",
info = "{#0095e9ff}It's cold as hell.",
tips = {
"„If I fall asleep, wake up 100 years later and somebody asks me, what is going on...“ — Mikhail Saltykov-Shchedrin",
'I am tired, I am weary\nI could sleep for a thousand years\nA thousand dreams that would awake me\nDifferent colors made of tears'}
}


msg.item[345] = { name = "Butler Bot <year+50>",
info = "World's smartest cleaning bot. Throw to activate."
}

msg.item[346] = { name = "Ceiling light",
info = "Artificial light source. Must be mounted on a ceiling, duh." }

msg.item[347] = { name = "Empty ceiling light",
info = "Artificial light source, requires power source." }

msg.item[348] = { name = "Sets of wires",
info = "Wires of color" }

msg.item[349] = { name = "Nunchucks",
info = "Whoosh whoosh whoosh." }

msg.item[350] = { name = "Crown of thorns",
info = "Equip: proclaim yourself the king of the cave." }

msg.item[351] = { name = "Snake ring",
info = "Equip: +2 inventory size, +health." }

msg.item[352] = { name = "Bin (vinegar)"}

msg.item[353] = { name = "Doctor sausage",
info = '100%% organic meat'}

msg.item[354] = { name = "The burning man",
info = 'It smells like freedom.'}

msg.item[355] = { name = "Dandelion"}

msg.item[356] = { name = "Moss-stuffed boots",
info = "Very warm."}

msg.item[357] = { name = "Fireproof gloves",
info = "Equip: you can pick up hot blocks and hot items."}

msg.item[358] = { name = "Chicken",
info = "It's two-legged animal with feathers.",
tips = {"Diet: seeds & worms, output: eggs", "„I cannot be caged. I cannot be controlled“. Some chickens are free-loving birds."}
}

msg.item[359] = { name = "Chicken egg",
info = "Obviously the egg came first.",
tips = {'Some eggs will turn into chickens after some time. You can speed it up and increase the chance of success by keeping eggs in a warm place.'}
}

msg.item[360] = { name = "Boiled egg",
info = ""}

msg.item[361] = { name = "Egg shell"}

msg.item[362] = { name = "Chicken shit"}

msg.item[363] = { name = "Rotten egg",
info = "Something is rotten in the state of Denmark.",
tips = {"Are you into a chemical warfare?","You can use it as a throwing weapon."}}

msg.item[364] = { name = "Feathers"}

msg.item[365] = { name = "Little chick",
info = "One day it will grow into mature chicken.",
}

msg.item[366] = { name = "Dead chicken",
info = "Meat is murder."
}

msg.item[367] = { name = "Omelette",
info = ""
}

msg.item[368] = { name = "Cargo pants",
info = "You can wear them now, nobody will judge. +5 inventory size."
}


msg.stone = {}
msg.stone[1] = { name = 'Lifeless dirt', 
info = "You wonder if it can sustain any life at all."
}
msg.stone[2] = { name = 'Dug up lifeless dirt',
info = "You've got a feeling that it has been dead for thousands of years.",
}
msg.stone[3] = { name = 'The Immovable Object', 
info = "You can't do anything about it. Or can you?",
tips = {"Yes you can't."}
}
msg.stone[4] = { name = 'Gigablock', 
info = "What kind of sorcery is this?"
}

msg.stone[5] = { name = 'Young glower',
info = "It's self-sufficient and does not need watering." }
msg.stone[6] = { name = 'Glower',
info = "Attracts slugs." }
msg.stone[7] = { name = 'Mature glower',
info = "This plant emits enough light to support other plants' growth." }

msg.stone[8] = { name = 'Some stones',
info = "Stones of different varieties." }
msg.stone[9] = { name = 'Clay', }
msg.stone[10] = { name = 'Rope', }
msg.stone[11] = { name = 'Hook', }
msg.stone[12] = { name = 'Soil',
info = "It's a fertilized soil." }
msg.stone[13] = { name = 'Rich Soil', 
info = "It's a thoroughly fertilized soil." 
}
msg.stone[14] = { name = 'Giant weed', }
msg.stone[15] = { name = 'Mature weed', }
msg.stone[16] = { name = 'Giant weed seeds', }
msg.stone[17] = { name = 'A pile of dirt', 
info = "It's fresh dug.",
tips = {'This pile of dirt is as useless as you are.','It will disappear after some time or it can be trampled down.', 'You can press dig+up key or dig+down for different results.',
	'Fun fact: most of the tips are actually useful, but not this one.'
}
}
msg.stone[18] = { name = 'Water', }
msg.stone[19] = { name = 'Salt', }
msg.stone[20] = { name = 'A heap of salt', 
info = "",
tip = {"Slugs hate salt. You can use heaps of salt to block their way."}
}

msg.stone[21] = { name = 'Roots', }
msg.stone[22] = { name = 'Dying roots', }
msg.stone[23] = { name = 'Dry roots', }
msg.stone[24] = { name = 'Firewood sapling', }
msg.stone[25] = { name = 'Firewood', }
msg.stone[26] = { name = 'Firewood', }
msg.stone[27] = { name = 'Firewood crown', }
msg.stone[28] = { name = 'Firewood', }
msg.stone[29] = { name = 'Firewood', }
msg.stone[30] = { name = 'Roots', }
msg.stone[31] = { name = 'Heavy dirt', }
msg.stone[32] = { name = 'Dense dirt', }
msg.stone[33] = { name = 'Big Fucking Stone',
info = "It has unnaturally smooth surface like a table top.",
}
msg.stone[34] = { name = 'Stone table', 
info = "It can be used as a primitive workbench."
}
msg.stone[35] = { name = 'Stone block', 
info = "It has tiny cracks at the side.",
tips = {"The bigger they are, the harder they fall.",
"Harder is 7 blocks or higher.",
"Drop it from a great height, is it clear enough?",
"It has high thermal conductivity and high heat capacity. Use it in a furnace to store and distribute heat evenly.",
"You can put worms under the rock to store them. Be careful not to smash them though."
}
}
msg.stone[36] = { name = 'Clover', 
info = "It's an invasive stoloniferous plant. Leave it unchecked and it'll grow all over the place (that is probably good)."}
msg.stone[37] = { name = 'Withered clover',
info = "Cause of death: the lack of light." }
msg.stone[38] = { name = 'Cob', 
info = "A building block you can stick to the sides of other blocks.",
tips = {"It has quite low thermal conductivity. You can use it to build a furnace to keep high temperature inside.",
"For starters try building a C-shaped furnace."}
}
msg.stone[39] = { name = 'Haystack',
craftinfo = 'You can rest inside with moderate level of comfort.',
info = "You wonder if there's a needle in it.",
transform = "A freakin miracle!"
 }
msg.stone[40] = { name = 'Up', }
msg.stone[41] = { name = 'Right', }
msg.stone[42] = { name = 'Down', }
msg.stone[43] = { name = 'Left', }
msg.stone[44] = { name = 'Digger', }
msg.stone[45] = { name = 'Ice shards',
info = "There is something inside." }
msg.stone[46] = { name = 'Icicle', }
msg.stone[47] = { name = 'Ice cube', 
info = "It has tiny cracks at the side.",
tips = {"You can melt it to get water", "You can preserve #freezable food by putting ice cube on top of it."},
txt = {"Ice cube shattered."}
}
msg.stone[48] = { name = 'Frozen dirt', }
msg.stone[49] = { name = 'Skeleton', }
msg.stone[50] = { name = 'Pyrite heater',
txt = {"Pyrite is required."} }
msg.stone[51] = { name = 'Office chair',
info = "You can get some rest if you put your ass on it. Grit recovers while you walk or rest. Body recovers during a rest only. Rest quality is very important can be increased by making better beds and resting in rooms and warm conditions."}
msg.stone[52] = { name = 'Hi-tech stuff', 
msg = "Something powerful nearby is preventing you from digging this."}
msg.stone[53] = { name = 'mob spawner', }
msg.stone[54] = { name = 'Base brick', }
msg.stone[55] = { name = 'Fire',
info = "Fire indeed hot.",
tips = {'Are you trying to burn me?',
"So, look. There are flammable items in the ga...me. The game of making a good fire, that's it.\nThey all have different burning temperatures and provide different amount of heat - that's something for you to discover.",
"If you want to build a furnace you should use building blocks (like cob)."
}
}

msg.stone[56] = { name = 'Stonework', 
info = "A building block you can stick to the sides of other blocks.",
tips = {"Thanks to the stones it has quite high thermal conductivity so it's useless for building furnaces."}
}
msg.stone[57] = { name = 'Jug (empty)'}
msg.stone[58] = { name = 'Jug (water)'}
msg.stone[59] = { name = 'Jug (raw)',
info = "You can store a large quantity of water in it. It's even large enough to hold a sand block. Must be fired first."
}
msg.stone[60] = { name = 'Sand',
tips = {'You can make a glass or a glass block using two different ways.'}
}

msg.stone[61] = { name = 'Jug (sand)',
info = "It's heavy.",
tips = {'Sand is the best base material for aquariums and artificial ponds.'}
}
msg.stone[62] = { name = 'Carrot'}
msg.stone[63] = { name = 'Copper ore', 
info = 'Copper can be extracted from the ore.'
}

msg.stone[64] = { name = 'Brick wall', 
tips = {"It has very low thermal conductivity. Use it to build a furnace."}
}
msg.stone[65] = { name = 'Limestone',
info = "It has tiny cracks at the side."}
msg.stone[66] = { name = 'Crucible (raw)',
info = "A container in which metals or other substances may be melted or subjected to very high temperatures. Must be fired first.",
tips = {"Here is a very generous tip: C-shaped cob furnace."}
}
msg.stone[67] = { name = 'Crucible (empty)', }
msg.stone[68] = { name = 'Crucible (copper ore)', }
msg.stone[69] = { name = 'Crucible (copper & tin)', }
msg.stone[70] = { name = 'Crucible (tin ore)', }
msg.stone[71] = { name = 'Crucible (limestone)', }
msg.stone[72] = { name = 'Crucible (coal)', }
msg.stone[73] = { name = 'Crucible (copper)', }
msg.stone[74] = { name = 'Crucible (bronze)', }
msg.stone[75] = { name = 'Crucible (tin)', }
msg.stone[76] = { name = 'Crucible (cement)', }
msg.stone[77] = { name = 'Crucible (coke)', }
msg.stone[78] = { name = 'Anvil',
info = "It's so heavy.",
}
msg.stone[79] = { name = 'Tin ore', }
msg.stone[80] = { name = 'Coal', }
msg.stone[81] = { name = 'Crucible (pyrite)', }
msg.stone[82] = { name = 'Crucible (sulfur)', }
msg.stone[83] = { name = 'Crucible (bronze & gold)', }
msg.stone[84] = { name = 'Crucible (tumbaga)', }
msg.stone[85] = { name = 'Cobweb', }
msg.stone[86] = { name = 'Webstring', }
msg.stone[87] = { name = 'Webstring', }
msg.stone[88] = { name = 'Pumpkin', }
msg.stone[89] = { name = "Jack-o'-lantern", }
msg.stone[90] = { name = 'Pumpkin', }
msg.stone[91] = { name = 'Apple sapling',
info = "Right now it's just a stick with some leaves. Someday it will become a tree. Perhaps it will."
}
msg.stone[92] = { name = 'Apple sapling',
info = "It requires watered Rich Soil to grow into a tree."}
msg.stone[93] = { name = 'Apple', 
info = "You can make some fine high density wood if you chop this beauty down. You don't feel good about it though."
}
msg.stone[94] = { name = 'Apple crown', }
msg.stone[95] = { name = 'Spiny bush', 
info = "It's a dry leafless bush with enormous thorns."}
msg.stone[96] = { name = 'Bean',
info = "These beans are made of this.",
 }
msg.stone[97] = { name = 'Bean vine', }
msg.stone[98] = { name = 'Fertile vine', }
msg.stone[99] = { name = 'Thin lifeless dirt', }
msg.stone[100] = { name = 'Corn', }
msg.stone[101] = { name = 'Shroom', }
msg.stone[102] = { name = 'Loam',
info = "It's a poor yet still *fertile* soil with great clay content.",
tips = {"You don't miss the worms. They're awesome."}
}
msg.stone[103] = { name = 'Rock', }
msg.stone[104] = { name = 'Base bottom', }
msg.stone[105] = { name = 'Collider', }
msg.stone[106] = { name = 'Solid', }
msg.stone[107] = { name = 'Peat', 
tips = {"You can build a peat 'farm'. See wiki for more details."}
}


msg.stone[108] = { name = 'Moss',
info = "Moss is the main constituent of peat."}

msg.stone[109] = { name = 'Moss', }
msg.stone[110] = { name = 'Moss', }
msg.stone[111] = { name = 'Compressed peat', }
msg.stone[112] = { name = 'Young bog-berry', }
msg.stone[113] = { name = 'Bog-berry', }
msg.stone[114] = { name = 'Bog-berry with berries', }
msg.stone[115] = { name = 'Power capsule',
msg = "Your digging disturbed unknown entities." }
msg.stone[116] = { name = 'Broken image',
info = "This picture makes no sense at all!",
transform = "I see rainbow and puppies, butter, flies and Rorschach's inkblots... Initiating reboot.",
}

msg.stone[117] = { name = 'Binary tree',
info = "" }
msg.stone[118] = { name = 'Crucible (gold ore)'}
msg.stone[119] = { name = 'Crucible (gold)'}
msg.stone[120] = { name = 'Much Water'}
msg.stone[121] = { name = 'Dry cob',
info = "It dried out, you can only break it now."}
msg.stone[122] = { name = 'Dry stonework',
info = "It dried out, you can only break it now."}
msg.stone[123] = { name = 'Clay golem',
craftinfo = 'You feel almost {#3e8948ff}mystical{#ffffffff} urge to craft this #sculpture.',
info = "It doesn't do anything, it just sits there and looks at me.",
txt = {'You had long but one-sided talk with the clay golem. A man has to believe in something, right? The faith *is hidden* and works in mysterious ways.\nSo, basically:\n— You build #sculptures and visit them daily (or put them on your regular paths) to increase your faith.\n— Faith gain differs from sculptures types.\n— You chance of successful prayer is your_faith_level %.\n'}
}

msg.stone[124] = { name = 'Chest',
info = "Sort things out! Put something inside and each time you pass the chest by it will transfer similar items from your inventory to the chest automatically. Chest can store up to 30 items."}

msg.stone[125] = { name = 'Moss bed',
info = "It's super cozy and provides extra rest quality."}


msg.stone[126] = { name = 'Dying glowin tree',
info = "Dig it out to allow it to regrow from the roots."}

msg.stone[127] = { name = 'Manna'}


msg.stone[128] = { name = 'Cactus'}

msg.stone[129] = { name = 'Bone ladder',
info = "It's 100%% organic and only 74%% disturbing."}

msg.stone[130] = { name = 'Wooden ladder'}

msg.stone[131] = { name = 'Sun',
info = "It's not that hot."}


msg.stone[132] = { name = 'Sun'}
msg.stone[133] = { name = 'Reptiloid painting'}
msg.stone[134] = { name = 'Animal remains'}
msg.stone[135] = { name = 'Chard'}
msg.stone[136] = { name = 'Pure clay'}
msg.stone[137] = { name = 'Insulator door',
info = "A door that blocks not only mobs but also a heat transfer!"}
msg.stone[138] = { name = 'Mini-Machine',
txt = {'Stay... '}}

msg.stone[139] = { name = 'Cauldron (raw)',
info = 'A cooking vessel. Must be fired first.'}
msg.stone[140] = { name = 'Cauldron',
info = "It's not hot enough too cook."}
msg.stone[141] = { name = 'Hot cauldron'}
msg.stone[142] = { name = 'Firewood table',
info = 'A stylish cooking table made of red wood.'}
msg.stone[143] = { name = "Gleb's table"}
msg.stone[144] = { name = "Seaweed",
info = "It grows only in water and provides habitat for fishies."}
msg.stone[145] = { name = "Water"}
msg.stone[146] = { name = "Stone mill",
info = 'Used to grind things.'}
msg.stone[147] = { name = "Ectoplasm",
info = "It's bouncy-bouncy."}

msg.stone[148] = { name = "Frostbite"}
msg.stone[149] = { name = "Toxic waste",
info = "Careful examination revealed it's not a person. Aren't you lonely?",
tips = {"You can burn it."}
}
msg.stone[150] = { name = "Bin (raw)",
info = "A general purpose container. Must be fired before use."}
msg.stone[151] = { name = "Bin (empty)"}
msg.stone[152] = { name = "Worm bin",
craftinfo = "It produces fertilizer from foliage and hay.",
info = "Keep it full. Bring foliage and hay.",
txt = { "Keep it full. Bring foliage.", "Composting..."}
}
msg.stone[153] = { name = "Waste heap",
info = "This looks unsettling.",
tips = {"Keep out of the reach of children!","No, really, you should store it somewhere safe or it will leak into the environment.","Artificial blocks will work fine."}
}

msg.stone[154] = { name = "Rice",
txt = {'You need a pot to hold it.'}
}

msg.stone[155] = { name = "Tomato"}
msg.stone[156] = { name = "Depleted heater"}
msg.stone[157] = { name = "Sugar beet"}
msg.stone[158] = { name = "Comal",
info = "A comal is a smooth, flat griddle typically used in Mexico, Central and parts of South America to cook tortilla and arepas, toast spices and nuts, sear meat, and generally prepare food."}
msg.stone[159] = { name = "Hot comal"}
msg.stone[160] = { name = "Bin (rice flour)"}
msg.stone[161] = { name = "Bin (corn flour)"}
msg.stone[162] = { name = "Crucible (sand)"}
msg.stone[163] = { name = "Crucible (glass)"}

msg.stone[164] = { name = "Bin (making cidre)"}
msg.stone[165] = { name = "Bin (apple cidre)"}
msg.stone[166] = { name = "Bin (making vinegar)"}
msg.stone[167] = { name = "Bin (vinegar)"}
msg.stone[168] = { name = "Bin (nixtamalization)",
info = 'Come back in a day. The corn is nix-ta-ma-li-za-tig!',
craftinfo = 'Nixtamalization is a traditional process in Mexico and Central America whereby corn is treated with lime, cooked, and dried and ground to produce the flour used to make tortilla.'}
msg.stone[169] = { name = "Bin (nixtamalized corn)"}

msg.stone[170] = { name = "„Chilli“"}
msg.stone[171] = { name = "Skull on a stick",
txt = {"Memories emerged from deep corners of your mind. Stats increased.","You feel nothing.","It remains silent."},
tips = {"Woah, Woah. Sick fuckery. Fun fact: gravestones were initially used to prevent the deceased from rising up and not as a memorial."},
info = "Long memory. #sculpture"
}

msg.stone[172] = { name = "Magic bean top" }
msg.stone[173] = { name = "Bean vine" }

msg.stone[174] = { name = "Vagina Dentata" }
msg.stone[175] = { name = "Some minerals" }
msg.stone[176] = { name = "Some minerals" }

msg.stone[177] = { name = "Stone louse" }
msg.stone[178] = { name = "Spider egg sack" }
msg.stone[179] = { name = "Bean vine" }

msg.stone[180] = { name = "Dirty filter" }
msg.stone[181] = { name = "Filter",
info = "To use filter submerge its top into a dirty water. Leave unoccupied space on the bottom for filtered water."}

msg.stone[182] = { name = "Dead beans" }
msg.stone[183] = { name = "Wooden door",
craftinfo = "You need a door to make a room. Build this if you want some privacy.",
info = "Knock knock.",
txt =
{"{#f6757aff}Right room quality: _1_, {#ffffffff}-_2_%{#f6757aff} items decay time. -»",
"{#f6757aff}«- Left  room quality: _1_, {#ffffffff}-_2_%{#f6757aff} items decay time.",
"Room quality depends on its wall material: ",
"Rooms not found. Put door in small closed areas.",
"{#f6757aff}Left room is too big (32 cubic blocks max).",
"{#f6757aff}Right room is too big (32 cubic blocks max).",
},
}


msg.stone[184] = { name = "Power loom",
info = "A machine for making cloth."}

msg.stone[185] = { name = "Glass"}
msg.stone[186] = { name = "Haed sculpture",
info = "It must be art. #sculpture"}
msg.stone[187] = { name = "Lingam statue",
info = "It reminds you of something personal. #sculpture"
}

msg.stone[188] = { name = "Stacked rocks",
info = "Somebody left a perfectly balanced rock installation here."
}

msg.stone[189] = { name = "Tuber plant",
info = "It's a potato-like plant but it's hard to draw a distinguishable potato plant, so here you go - a tuber plant!"
}


msg.stone[190] = { name = "Huītzilōpōchtli altar",
craftinfo = '#statue of Huītzilōpōchtli. Everyone knows Huītzilōpōchtli.',
info = "Waiting for sacrifice."
}


msg.stone[191] = { name = "Huītzilōpōchtli altar",
info = "It's covered in blood. Come back later to gain faith."
}


msg.stone[192] = { name = "Sandbox game",
info = "Yo dawg I heard you like sandbox games. #scuplture"
}

msg.stone[193] = { name = "Ceiling light",
info = "Artificial light source."
}

msg.stone[194] = { name = "Empty ceiling light",
info = "Needs recharging."
}

msg.stone[195] = { name = "Opened door",
info = "Opened door is as good as no door. No door. Nodoor. Nodor. Odor."
}

msg.stone[196] = { name = "The Wicker Man",
craftinfo = 'A man-shaped #statue',
info = "Use a fire starter to burn it."
}

msg.stone[197] = { name = "Dandelion",
info = "Useless weed plant."
}

msg.stone[198] = { name = "Calories burner",
info = ""
}


msg.achi = {}

msg.achi.gui =
{
[1] = '„{#f77622ff}_1_{#ffffffff}“ {#fee761ff}achievement unlocked{#ffffffff}: _2_',
[2] = [[                                   .''.       
       .''.      .        *''*    :_\/_:     . 
      :_\/_:   _\(/_  .:.*_\/_*   : /\ :  .'.:.'.
  .''.: /\ :   ./)\   ':'* /\ * :  '..'.  -=:o:=-
 :_\/_:'.:::.    ' *''*    * '.\'/.' _\(/_'.':'.'
 : /\ : :::::     *_\/_*     -= o =-  /)\    '  *
  '..'  ':::'     * /\ *     .'/.\'.   '
      *            *..*         :
	     *]],

[3] = '{#fee761ff}Unlocked!{#ffffffff}',
[4] = '{#be4a2fff}Failed{#ffffffff}',
[5] = 'Category: ',
[6] = '{#fee761ff}A]{#ffffffff} and {#fee761ff}D]{#ffffffff} to cycle, {#fee761ff}N]{#ffffffff} to hide/show',
[7] = "there's a reward",
[8] = "",

}

msg.achi.gui[2] = string.gsub (msg.achi.gui[2],'*','{#fee761ff}*{#ffffffff}')
msg.achi.gui[2] = string.gsub (msg.achi.gui[2],':','{#f77622ff}:{#ffffffff}')

msg.achitypes =
{
	[1] = 'Getting started',
	[2] = 'Primitive technologies',
	[3] = 'Power in numbers',
	[4] = 'Things we do',
	[5] = 'Biology',
	[6] = 'Means of production'
}

msg.achi[1] =
{
	name = 'Early Bird',
	desc = 'Catch a worm.'
}

msg.achi[2] =
{
	name = 'Let there be light',
	desc = 'Grow a plant from a glowing seed.'
}


msg.achi[3] =
{
	name = 'Knapping 101',
	desc = 'Craft a sharp stone.'
}

msg.achi[4] =
{
	name = 'Ah ah ah ah stayin alive',
	desc = 'Survive for a day in a new game.'
}

msg.achi[5] =
{
	name = 'Stone Table Age',
	desc = 'Craft a stone table (look for stone blocks).'
}

msg.achi[6] =
{
	name = 'Tough cookie',
	desc = 'Withstand 1000 damage in one life.'
}

msg.achi[7] =
{
	name = 'The tool of choice',
	desc = 'Craft an adze.'
}

msg.achi[8] =
{
	name = 'By fire be purged',
	desc = 'Get a charcoal by burning wood.'
}

msg.achi[9] =
{
	name = 'Biology 101',
	desc = "Gain insights on flying amoeba's insides."
}


msg.achi[10] =
{
	name = 'Rest in peace',
	desc = "Have a rest with a quality of 1.3 or higher."
}


msg.achi[11] =
{
	name = 'Mushroom trip',
	desc = "Walk 100 blocks away from The Machine\n  while affected by mushrooms."
}

msg.achi[12] =
{
	name = 'Preserving memories',
	desc = "Get 30 tips from The Machine in one life."
}

msg.achi[13] =
{
	name = 'Garbage collector',
	desc = "Discover 150 different items."
}

msg.achi[14] =
{
	name = 'Jack of all trades',
	desc = "Craft 100 different items."
}

msg.achi[15] =
{
	name = 'Master of nom',
	desc = "Eat 50 different dishes."
}

msg.achi[16] =
{
	name = 'Adobe proficiency',
	desc = "Make 7 cob blocks."
}

msg.achi[17] =
{
	name = 'More ore',
	desc = "Mine 12 copper ores."
}

msg.achi[18] =
{
	name = 'Burn a meat',
	desc = "...and eat it too."
}

msg.achi[19] =
{
	name = 'HODL',
	desc = "Fill jug with water and sand."
}

msg.achi[20] =
{
	name = 'Get one for free',
	desc = "Craft 3 chests."
}


msg.achi[21] =
{
	name = 'Knock knock joke',
	desc = "Craft 2 doors."
}

msg.achi[22] =
{
	name = 'Hang in there',
	desc = "Craft a hemp rope."
}

msg.achi[23] =
{
	name = 'Find a water chip',
	desc = "Really?"
}


msg.achi[24] =
{
	name = 'Ok boomer',
	desc = "„Mine“ 20 items with explosives."
}

msg.achi[25] =
{
	name = 'So long',
	desc = "Catch a fish."
}

msg.achi[26] =
{
	name = 'Fully charged',
	desc = "Let The Machine have 100 power."
}

msg.achi[27] =
{
	name = 'Making friends',
	desc = "Feed 7 spiders (of feed one spider 7 times)."
}

msg.achi[28] =
{
	name = 'Fields of gold',
	desc = "Grow 30 clovers from seeds."
}

msg.achi[29] =
{
	name = 'Human petri dish',
	desc = "Drink dirty water 30 times."
}

msg.achi[30] =
{
	name = 'Balanced diet',
	desc = "Eat 20 dishes in a row restoring\n  10{#63c74dff}■{#8b9bb4ff} or more each dish."
}

msg.achi[31] =
{
	name = 'Slug farm',
	desc = "Let 20 slugs give birth (feed them)."
}


msg.achi[32] =
{
	name = 'All by myself',
	desc = "Have some me-time."
}


msg.achi[33] =
{
	name = 'Ice bucket challenge',
	desc = "Spend 666 hours cryo-frozen."
}


msg.achi[34] =
{
	name = 'Tabula rasa',
	desc = "Get and use Stone Table."
}

msg.achi[35] =
{
	name = 'Feel the beat',
	desc = "Get and use Anvil."
}

msg.achi[36] =
{
	name = "Hell's kitchen",
	desc = "Get and use Hot Cauldron."
}

msg.achi[37] =
{
	name = "Pan pal",
	desc = "Get and use Hot Comal."
}

msg.achi[38] =
{
	name = "Elite furniture",
	desc = "Get and use Firewood Table."
}


msg.achi[39] =
{
	name = "Grinds my gears",
	desc = "Get and use Stone Mill."

}

msg.achi[40] =
{
	name = "Future tech",
	desc = "Get and use Power Loom."
}

msg.achi[41] =
{
	name = "Kurochka Ryaba",
	desc = "Hatch 10 eggs into chicks."
}



