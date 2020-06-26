$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "asm"

STAR_COUNT = 20

GUN_COOLDOWN = 10

name      "parsec"

initialize!

loading_screen "loading.png", 40, 20

load_sprite "ship.png"

allocate_var "lastFrame"

allocate_var "scratchA"
allocate_var "scratchB"
allocate_var "scratchC"
allocate_var "scratchD"

allocate_var "shipPos"

allocate_var "gunCooldown"
allocate_var "bulletPointer"

org       0x0200

macro :procedure, "drawShip_idle" do
  ldwi    "SYS_Sprite6_v3_64"
  stw     "sysFn"

  ldwi    "ship_0"
  stw     "sysArgs0"
  ldw     "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_1"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "drawShip_burn" do
  ldwi    "SYS_Sprite6_v3_64"
  stw     "sysFn"

  ldwi    "ship_2"
  stw     "sysArgs0"
  ldw     "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_1"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "drawShip_brake" do
  ldwi    "SYS_Sprite6_v3_64"
  stw     "sysFn"

  ldwi    "ship_3"
  stw     "sysArgs0"
  ldw     "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_1"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "drawShip_left" do
  ldwi    "SYS_Sprite6_v3_64"
  stw     "sysFn"

  ldwi    "ship_4"
  stw     "sysArgs0"
  ldw     "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_5"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "drawShip_left_burn" do
  ldwi    "SYS_Sprite6_v3_64"
  stw     "sysFn"

  ldwi    "ship_6"
  stw     "sysArgs0"
  ldw     "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_5"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "drawShip_left_brake" do
  ldwi    "SYS_Sprite6_v3_64"
  stw     "sysFn"

  ldwi    "ship_7"
  stw     "sysArgs0"
  ldw     "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_5"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "drawShip_right" do
  ldwi    "SYS_Sprite6y_v3_64"
  stw     "sysFn"

  ldwi    "ship_4"
  stw     "sysArgs0"
  ldwi    0x0100 * 11
  addw    "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_5"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

ldwi      0x0300
call      "vAC"

org       0x0300

macro :procedure, "drawShip_right_burn" do
  ldwi    "SYS_Sprite6y_v3_64"
  stw     "sysFn"

  ldwi    "ship_6"
  stw     "sysArgs0"
  ldwi    0x0100 * 11
  addw    "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_5"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "drawShip_right_brake" do
  ldwi    "SYS_Sprite6y_v3_64"
  stw     "sysFn"

  ldwi    "ship_7"
  stw     "sysArgs0"
  ldwi    0x0100 * 11
  addw    "shipPos"
  sys     64
  stw     "scratchA"
  ldwi    "ship_5"
  stw     "sysArgs0"
  ldw     "scratchA"
  sys     64
end

macro :procedure, "moveShip_burn" do |start_label, return_label|
  ld      "shipPos"
  xori    160 - 12
  beq     return_label
  inc     "shipPos"
end

macro :procedure, "moveShip_brake" do |start_label, return_label|
  ld      "shipPos"
  xori    0
  beq     return_label
  dec     "shipPos"
end

macro :procedure, "moveShip_left" do |start_label, return_label|
  ldwi    0xff00
  andw    "shipPos"
  xorwi   pixel_address(0, 0)
  beq     return_label
  dec     -> { value_of("shipPos") + 1 }
end

macro :procedure, "moveShip_right" do |start_label, return_label|
  ldwi    0xff00
  andw    "shipPos"
  xorwi   pixel_address(0, 108)
  beq     return_label
  inc     -> { value_of("shipPos") + 1 }
end

macro :procedure, "drawStars" do
  ldwi    "stars"
  stw     "scratchA"

  label   "drawStar"
  ldw     "scratchA"
  deek
  stw     "scratchB"

  ldw     "scratchA"
  peek
  bne     "fillStar"
  ldi     rgb_convert(0, 0, 0)
  doke    "scratchB"
  bra     "updateStarPos"
  label   "fillStar"
  ldwi    (rgb_convert(0, 0, 0) << 8) + rgb_convert(85, 85, 85)
  doke    "scratchB"

  label   "updateStarPos"
  ldw     "scratchA"
  peek
  bne     "skipStarPosAdjust"
  ldi     159
  label   "skipStarPosAdjust"
  subi    1
  poke    "scratchA"

  inc     "scratchA"
  inc     "scratchA"

  ldwi    -> { value_of("stars") + STAR_COUNT * 2 }
  xorw    "scratchA"
  bne     "drawStar"
end

ldwi      0x0400
call      "vAC"

org       0x0400

macro :procedure, "waitFrame" do |start_label, return_label|
  ld      "frameCount"
  xorw    "lastFrame"
  beq     start_label
  ld      "frameCount"
  st      "lastFrame"
end

macro :procedure, "clearScreen" do
  ldwi      "SYS_Draw4_30"
  stw       "sysFn"

  ldi       rgb_convert(0, 0, 0)
  stw       "sysArgs0"
  stw       "sysArgs2"

  ldwi      pixel_address(0, 0)
  stw       "sysArgs4"

  label     "nextPixel"
  sys       30

  ld        "sysArgs4"
  addi      4
  st        "sysArgs4"

  andi      0xff
  xori      160
  bne       "nextPixel"

  ldwi      0xff00
  andw      "sysArgs4"
  addwi     0x0100
  stw       "sysArgs4"

  ldwi      pixel_address(0,120)
  xorw      "sysArgs4"
  bne       "nextPixel"
end

# macro :procedure, "inRange" do
#   ld      "scratchB"
#   subw    "scratchC"
#   blt     "notInRange"

#   ld      "scratchB"
#   subw    "scratchD"
#   bgt     "notInRange"

#   ldi     0
#   ret

#   label   "notInRange"
#   ldi     1
# end

ldwi      0x0500
call      "vAC"

org       0x0500

macro :procedure, "spawnBullet" do
  ldwi    0x0100 + 8
  addw    "shipPos"
  doke    "bulletPointer"

  inc     "bulletPointer"
  inc     "bulletPointer"

  ld      "bulletPointer"
  bne     "skipBulletPointerAdjust"
  ldi     -> { value_of("bullets") & 0x00ff }
  st      "bulletPointer"
  label   "skipBulletPointerAdjust"
end

macro :procedure, "drawBullets" do
  ldwi    "SYS_Draw4_30"
  stw     "sysFn"

  ldi     rgb_convert(0, 0, 0)
  stw     "sysArgs0"
  ldwi    (rgb_convert(255, 0, 85) << 8) + rgb_convert(170, 0, 85)
  stw     "sysArgs2"

  ldwi    "bullets"
  stw     "scratchA"

  label   "drawBullet"
  ldw     "scratchA"
  deek
  beq     "nextBullet"

  ldw     "scratchA"
  peek
  subi    159 - 4
  blt     "fillBullet"

  ldi     rgb_convert(0, 0, 0)
  stw     "sysArgs2"
  ldw     "scratchA"
  deek
  stw     "sysArgs4"
  sys     30
  ldwi    0x0900
  addw    "sysArgs4"
  stw     "sysArgs4"
  sys     30
  ldi     0
  doke    "scratchA"
  ldwi    (rgb_convert(170, 0, 85) << 8) + rgb_convert(255, 0, 85)
  stw     "sysArgs2"
  bra     "nextBullet"

  label   "fillBullet"
  ldw     "scratchA"
  peek
  addi    2
  poke    "scratchA"
  ldw     "scratchA"
  deek
  stw     "sysArgs4"
  sys     30
  ldwi    0x0900
  addw    "sysArgs4"
  stw     "sysArgs4"
  sys     30

  label   "nextBullet"
  inc     "scratchA"
  inc     "scratchA"

  ldwi    -> { (value_of("bullets") & 0xff00) }
  xorw    "scratchA"
  bne     "drawBullet"
end

ldwi      0x0600
call      "vAC"

org       0x0600

ldi       0
stw       "lastFrame"

ldwi      pixel_address(74, 54)
stw       "shipPos"

ldi       GUN_COOLDOWN
stw       "gunCooldown"

ldwi      "bullets"
stw       "bulletPointer"

ldwi      "SYS_SetMode_v2_80"
stw       "sysFn"
ldi       2
sys       80

call      "clearScreen"

macro :loop, "main" do |start_label|
  # call    "waitFrame"

  call    "drawStars"

  label   "checkLeftBurn"
  ld      "buttonState"
  andi    BUTTON_UP | BUTTON_RIGHT
  bne     "checkLeftBrake"
  call    "drawShip_left_burn"
  call    "moveShip_burn"
  call    "moveShip_left"
  bra     "moveDone"

  label   "checkLeftBrake"
  ld      "buttonState"
  andi    BUTTON_UP | BUTTON_LEFT
  bne     "checkRightBurn"
  call    "drawShip_left_brake"
  call    "moveShip_brake"
  call    "moveShip_left"
  bra     "moveDone"

  label   "checkRightBurn"
  ld      "buttonState"
  andi    BUTTON_DOWN | BUTTON_RIGHT
  bne     "checkRightBrake"
  call    "drawShip_right_burn"
  call    "moveShip_burn"
  call    "moveShip_right"
  bra     "moveDone"

  label   "checkRightBrake"
  ld      "buttonState"
  andi    BUTTON_DOWN | BUTTON_LEFT
  bne     "checkBurn"
  call    "drawShip_right_brake"
  call    "moveShip_brake"
  call    "moveShip_right"
  bra     "moveDone"

  label   "checkBurn"
  ld      "buttonState"
  andi    BUTTON_RIGHT
  bne     "checkBrake"
  call    "drawShip_burn"
  call    "moveShip_burn"
  bra     "moveDone"

  label   "checkBrake"
  ld      "buttonState"
  andi    BUTTON_LEFT
  bne     "checkLeft"
  call    "drawShip_brake"
  call    "moveShip_brake"
  bra     "moveDone"

  label   "checkLeft"
  ld      "buttonState"
  andi    BUTTON_UP
  bne     "checkRight"
  call    "drawShip_left"
  call    "moveShip_left"
  bra     "moveDone"

  label   "checkRight"
  ld      "buttonState"
  andi    BUTTON_DOWN
  bne     "idle"
  call    "drawShip_right"
  call    "moveShip_right"
  bra     "moveDone"

  label   "idle"
  call    "drawShip_idle"

  label   "moveDone"

  label   "checkShoot"
  ld      "gunCooldown"
  xori    GUN_COOLDOWN
  bne     "updateCooldown"

  ld      "buttonState"
  andi    BUTTON_A
  bne     "shootDone"

  call    "spawnBullet"
  ldi     0
  st      "gunCooldown"
  bra     "shootDone"

  label   "updateCooldown"
  inc     "gunCooldown"

  label   "shootDone"

  call    "drawBullets"
end

halt

org       0x08a0

label     "stars"
STAR_COUNT.times do |i|
  byte    rand(159), rand(119) + 8
end

org       0x09f0

label     "bullets"
16.times do
  byte    0
end

done      0x0200
