$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "asm"

TICKS_PER_FRAME = 30
TICK_RATE = 1
TICK_RATE_FAST = 10

BOARD_ORIGIN_X = 62
BOARD_ORIGIN_Y = 24
BOARD_WIDTH = 6
BOARD_HEIGHT = 12

RED = rgb_convert(255, 0, 0)
RED_SMASHER = rgb_convert(170, 0, 0)
BLUE = rgb_convert(0, 85, 255)
BLUE_SMASHER = rgb_convert(0, 0, 255)
ORANGE = rgb_convert(255, 170, 0)
ORANGE_SMASHER = rgb_convert(170, 85, 0)
PURPLE = rgb_convert(170, 0, 255)
PURPLE_SMASHER = rgb_convert(85, 0, 170)

GEM_SIZE = 6

SMASHED_GEM =

name        "puzzles"

initialize!

load_sprite "gems.png"

allocate_var "lastFrame"

allocate_var "scratch_a"
allocate_var "scratch_b"
allocate_var "scratch_c"

allocate_var "tickCounter", 1
allocate_var "tickRate"

allocate_var "currentGem_colorA", 1
allocate_var "currentGem_colorB", 1
allocate_var "currentGem_posX", 1
allocate_var "currentGem_posY", 1
allocate_var "currentGem_rotation", 1
allocate_var "currentGem_order", 1

allocate_var "nextGem_colorA", 1
allocate_var "nextGem_colorB", 1

def board_address(x, y)
  value_of("board") + x + ( y * BOARD_WIDTH )
end

def board_pixel_address(x, y)
  x = BOARD_ORIGIN_X + (x * GEM_SIZE)
  y = BOARD_ORIGIN_Y + (y * GEM_SIZE)
  pixel_address(x, y)
end

org         0x0200

gt_procedure "waitFrame" do |start_label, return_label|
  ld        "frameCount"
  xorw      "lastFrame"
  beq       start_label
  ld        "frameCount"
  st        "lastFrame"
end

gt_procedure "clearScreen" do
  ldwi      "SYS_Draw4_30"
  stw       "sysFn"

  ldi       rgb_convert(0, 0, 0)
  stw       "sysArgs0"
  stw       "sysArgs2"

  ldwi      pixel_address(0, 0)
  stw       "sysArgs4"

  label     "clearScreen_nextPixel"
  sys       30

  ld        "sysArgs4"
  addi      4
  st        "sysArgs4"

  xori      160
  bne       "clearScreen_nextPixel"
  st        "sysArgs4"

  ld        "sysArgs5"
  addi      1
  st        "sysArgs5"

  ldwi      pixel_address(0,120)
  xorw      "sysArgs4"
  bne       "clearScreen_nextPixel"
end

gt_procedure "drawBoard" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      board_pixel_address(-1, -1)
  stw       "scratch_a"

  label     "drawTop_nextCell"
  ldwi      "gems_1"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  ld        "scratch_a"
  addi      GEM_SIZE
  st        "scratch_a"

  xori      board_pixel_address(7, 0) & 0xff
  bne       "drawTop_nextCell"

  ldwi      board_pixel_address(-1, 0)
  stw       "scratch_a"

  label     "drawEdge_nextRow"
  ldwi      "gems_1"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  ld        "scratch_a"
  addi      GEM_SIZE * 7
  st        "scratch_a"

  ldwi      "gems_1"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  ldi       board_pixel_address(-1, 0) & 0xff
  st        "scratch_a"

  ld        -> { value_of("scratch_a") + 1 }
  addi      GEM_SIZE
  st        -> { value_of("scratch_a") + 1 }

  ldwi      board_pixel_address(-1, 12)
  xorw      "scratch_a"
  bne       "drawEdge_nextRow"

  label     "drawBottom_nextCell"
  ldwi      "gems_1"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  ld        "scratch_a"
  addi      GEM_SIZE
  st        "scratch_a"

  xori      board_pixel_address(7, 0) & 0xff
  bne       "drawBottom_nextCell"
end

gt_procedure "generateGem" do
  ldwi      "SYS_Random_34"
  stw       "sysFn"
  sys       34
  # Random value between 0-3 for gem color
  ld        -> { value_of("entropy") + 0 }
  andi      3
  addi      2
  stw       "scratch_a"
  # Random value between 0-3 for smasher. if == 0 then smasher.
  ld        -> { value_of("entropy") + 1 }
  andi      3
  bne       "returnGem"
  ldi       4
  addw      "scratch_a"
  st        "scratch_a"
  label     "returnGem"
  ld        "scratch_a"
end

gt_procedure "spawnGem" do
  push

  # Set current gem:
  #   - colors from next gem A and B
  #   - position, rotation, and order are reset
  ld        "nextGem_colorA"
  st        "currentGem_colorA"
  ld        "nextGem_colorB"
  st        "currentGem_colorB"
  ldi       2 * GEM_SIZE
  st        "currentGem_posX"
  ldi       0
  st        "currentGem_posY"
  st        "currentGem_rotation"
  st        "currentGem_order"

  # Generate next gem A
  call      "generateGem"
  st        "currentGem_colorA"

  # Generate next gem B
  call      "generateGem"
  st        "currentGem_colorB"

  pop
end

ldwi        0x0300
call        "vAC"

org         0x0300

gt_procedure "eraseCurrentGem" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "gems_0"
  stw       "sysArgs0"

  ldwi      board_pixel_address(0, 0)
  addw      "currentGem_posX"
  stw       "scratch_b"

  sys       64

  ldwi      "gems_0"
  stw       "sysArgs0"

  ld        "currentGem_rotation"
  beq       "eraseCurrentGem_rotation_0"
  subi      1
  beq       "eraseCurrentGem_rotation_1"
  subi      1
  beq       "eraseCurrentGem_rotation_2"

  label     "eraseCurrentGem_rotation_3"
  ld        -> { value_of("scratch_b") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_b") + 1 }
  ldw       "scratch_b"
  sys       64
  bra       "eraseCurrentGem_rotationDone"

  label     "eraseCurrentGem_rotation_2"
  ldw       "scratch_b"
  subi      GEM_SIZE
  sys       64
  bra       "eraseCurrentGem_rotationDone"

  label     "eraseCurrentGem_rotation_1"
  ldwi      GEM_SIZE << 8
  addw      "scratch_b"
  sys       64
  bra       "eraseCurrentGem_rotationDone"

  label     "eraseCurrentGem_rotation_0"
  ldw       "scratch_b"
  addi      GEM_SIZE
  sys       64
  label     "eraseCurrentGem_rotationDone"
end

gt_procedure "drawCurrentGem" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ld        "currentGem_order"
  beq       "gemA_order0"
  ld        "currentGem_colorB"
  bra       "gemA_checkDone"
  label     "gemA_order0"
  ld        "currentGem_colorA"
  label     "gemA_checkDone"
  lslw
  addwi     "gemPointers"
  deek
  stw       "sysArgs0"

  ldwi      board_pixel_address(0, 0)
  addw      "currentGem_posX"
  stw       "scratch_b"

  sys       64

  ld        "currentGem_order"
  beq       "gemB_order0"
  ld        "currentGem_colorA"
  bra       "gemB_checkDone"
  label     "gemB_order0"
  ld        "currentGem_colorB"
  label     "gemB_checkDone"
  lslw
  addwi     "gemPointers"
  deek
  stw       "scratch_a"
  ld        "currentGem_rotation"
  beq       "drawCurrentGem_rotation_0"
  subi      1
  beq       "drawCurrentGem_rotation_1"
  subi      1
  beq       "drawCurrentGem_rotation_2"

  label     "drawCurrentGem_rotation_3"
  ldw       "scratch_a"
  stw       "sysArgs0"
  ld        -> { value_of("scratch_b") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_b") + 1 }
  ldw       "scratch_b"
  sys       64
  bra       "drawCurrentGem_rotationDone"

  label     "drawCurrentGem_rotation_2"
  ldw       "scratch_a"
  stw       "sysArgs0"
  ldw       "scratch_b"
  subi      GEM_SIZE
  sys       64
  bra       "drawCurrentGem_rotationDone"

  label     "drawCurrentGem_rotation_1"
  ldw       "scratch_a"
  stw       "sysArgs0"
  ldwi      GEM_SIZE << 8
  addw      "scratch_b"
  sys       64
  bra       "drawCurrentGem_rotationDone"

  label     "drawCurrentGem_rotation_0"
  ldw       "scratch_a"
  stw       "sysArgs0"
  ldw       "scratch_b"
  addi      GEM_SIZE
  sys       64
  label     "drawCurrentGem_rotationDone"
end

ldwi        0x0400
call        "vAC"

org         0x0400

gt_procedure "check" do
  push

  ldwi      board_pixel_address(0, 0)
  addw      "currentGem_posX"
  stw       "scratch_a"

  ld        "currentGem_rotation"
  beq       "check_rotation_0"
  subi      1
  beq       "check_rotation_1"
  subi      1
  beq       "check_rotation_2"

  label     "check_rotation_3"
  ldw       "scratch_a"
  peek
  bne       "check_true"
  bra       "check_false"

  label     "check_rotation_2"
  ldw       "scratch_a"
  peek
  bne       "check_true"
  ldw       "scratch_a"
  subi      GEM_SIZE
  peek
  bne       "check_true"
  bra       "check_false"

  label     "check_rotation_1"
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  peek
  bne       "check_true"
  bra       "check_false"

  label     "check_rotation_0"
  ldw       "scratch_a"
  peek
  bne       "check_true"
  ldw       "scratch_a"
  addi      GEM_SIZE
  peek
  bne       "check_true"
  bra       "check_false"

  label     "check_true"
  ldi       0
  bra       "check_done"
  label     "check_false"
  ldi       1
  label     "check_done"
  pop
end

gt_procedure "checkAndDrop" do
  push

  call      "check"
  bne       "checkAndDrop_done"

  label     "checkAndDrop_drop"
  ld        "currentGem_posY"
  subi      GEM_SIZE
  st        "currentGem_posY"


  call      "drawCurrentGem"
  call      "spawnGem"

  label     "checkAndDrop_done"
  pop
end

ldwi        0x0500
call        "vAC"

org         0x0500

gt_procedure "handleInputRotate" do
  ld        "buttonState"
  andi      BUTTON_A
  bne       "handleInputRotate_done"
  ld        "buttonState"
  xori      BUTTON_A
  st        "buttonState"

  ldwi      board_pixel_address(0, 0)
  addw      "currentGem_posX"
  stw       "scratch_a"

  ld        "currentGem_rotation"
  beq       "handleInputRotate_rotation_0"
  subi      1
  beq       "handleInputRotate_rotation_1"
  subi      1
  beq       "handleInputRotate_rotation_2"

  label     "handleInputRotate_rotation_3"
  ldw       "scratch_a"
  addi      GEM_SIZE
  peek
  beq       "handleInputRotate_rotate"
  ldw       "scratch_a"
  subi      GEM_SIZE
  peek
  bne       "handleInputRotate_done"
  ld        "currentGem_posX"
  subi      GEM_SIZE
  st        "currentGem_posX"
  bra       "handleInputRotate_rotate"

  label     "handleInputRotate_rotation_2"
  ld        -> { value_of("scratch_a") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_a") + 1 }
  ldw       "scratch_a"
  peek
  beq       "handleInputRotate_rotate"
  bra       "handleInputRotate_done"

  label     "handleInputRotate_rotation_1"
  ldw       "scratch_a"
  subi      GEM_SIZE
  peek
  beq       "handleInputRotate_rotate"
  ldw       "scratch_a"
  addi      GEM_SIZE
  peek
  bne       "handleInputRotate_done"
  ld        "currentGem_posX"
  addi      GEM_SIZE
  st        "currentGem_posX"
  bra       "handleInputRotate_rotate"

  label     "handleInputRotate_rotation_0"
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  peek
  beq       "handleInputRotate_rotate"
  bra       "handleInputRotate_done"

  label     "handleInputRotate_rotate"
  ld        "currentGem_rotation"
  addi      1
  st        "currentGem_rotation"
  xori      4
  bne       "handleInputRotate_done"
  st        "currentGem_rotation"

  label     "handleInputRotate_done"
end

gt_procedure "handleInputLeft" do
  ld        "buttonState"
  andi      BUTTON_LEFT
  bne       "handleInputLeft_done"
  ld        "buttonState"
  xori      BUTTON_LEFT
  st        "buttonState"

  ldwi      board_pixel_address(0, 0)
  addw      "currentGem_posX"
  stw       "scratch_a"

  ld        "currentGem_rotation"
  beq       "handleInputLeft_rotation_0"
  subi      1
  beq       "handleInputLeft_rotation_1"
  subi      1
  beq       "handleInputLeft_rotation_2"

  label     "handleInputLeft_rotation_3"
  ldw       "scratch_a"
  subi      GEM_SIZE
  peek
  bne       "handleInputLeft_done"
  ld        -> { value_of("scratch_a") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_a") + 1 }
  addw      "scratch_a"
  subi      GEM_SIZE
  peek
  bne       "handleInputLeft_done"
  bra       "handleInputLeft_move"

  label     "handleInputLeft_rotation_2"
  ldw       "scratch_a"
  subi      GEM_SIZE * 2
  peek
  bne       "handleInputLeft_done"
  bra       "handleInputLeft_move"

  label     "handleInputLeft_rotation_1"
  ldw       "scratch_a"
  subi      GEM_SIZE
  peek
  bne       "handleInputLeft_done"
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  subi      GEM_SIZE
  peek
  bne       "handleInputLeft_done"
  bra       "handleInputLeft_move"

  label     "handleInputLeft_rotation_0"
  ldw       "scratch_a"
  subi      GEM_SIZE
  peek
  bne       "handleInputLeft_done"

  label     "handleInputLeft_move"
  ld        "currentGem_posX"
  subi      GEM_SIZE
  st        "currentGem_posX"

  label     "handleInputLeft_done"
end

ldwi        0x0600
call        "vAC"

org         0x0600

gt_procedure "handleInputRight" do
  ld        "buttonState"
  andi      BUTTON_RIGHT
  bne       "handleInputRight_done"
  ld        "buttonState"
  xori      BUTTON_RIGHT
  st        "buttonState"

  ldwi      board_pixel_address(0, 0)
  addw      "currentGem_posX"
  stw       "scratch_a"

  ld        "currentGem_rotation"
  beq       "handleInputRight_rotation_0"
  subi      1
  beq       "handleInputRight_rotation_1"
  subi      1
  beq       "handleInputRight_rotation_2"

  label     "handleInputRight_rotation_3"
  ldw       "scratch_a"
  addi      GEM_SIZE
  peek
  bne       "handleInputRight_done"
  ld        -> { value_of("scratch_a") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_a") + 1 }
  addw      "scratch_a"
  addi      GEM_SIZE
  peek
  bne       "handleInputRight_done"
  bra       "handleInputRight_move"

  label     "handleInputRight_rotation_2"
  ldw       "scratch_a"
  addi      GEM_SIZE
  peek
  bne       "handleInputRight_done"
  bra       "handleInputRight_move"

  label     "handleInputRight_rotation_1"
  ldw       "scratch_a"
  addi      GEM_SIZE
  peek
  bne       "handleInputRight_done"
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  addi      GEM_SIZE
  peek
  bne       "handleInputRight_done"
  bra       "handleInputRight_move"

  label     "handleInputRight_rotation_0"
  ldw       "scratch_a"
  addi      GEM_SIZE * 2
  peek
  bne       "handleInputRight_done"

  label     "handleInputRight_move"
  ld        "currentGem_posX"
  addi      GEM_SIZE
  st        "currentGem_posX"

  label     "handleInputRight_done"
end

gt_procedure "gravity" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      board_pixel_address(5, 10)
  stw       "scratch_a"

  label     "gravity_loop"
  ldw       "scratch_a"
  peek
  beq       "gravity_nextCell"

  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  stw       "scratch_b"
  peek
  bne       "gravity_nextCell"

  ldwi      0x0202
  addw      "scratch_a"
  peek
  lslw
  stw       "scratch_c"
  ldwi      "gemPointers_color"
  addw      "scratch_c"
  deek
  stw       "sysArgs0"
  ldw       "scratch_b"
  sys       64
  ldwi      "gems_0"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64
  bra       "gravity_nextCell"

  label     "gravity_nextCell"
  ldw       "scratch_a"
  subi      GEM_SIZE
  stw       "scratch_a"
  ldwi      board_pixel_address(-1, 10)
  xorw      "scratch_a"
  bne       "gravity_loop"
end

ldwi        0x08a0
call        "vAC"

org         0x08a0

gt_procedure "handleInputSwitch" do
  ld        "buttonState"
  andi      BUTTON_B
  bne       "handleInputSwitch_done"
  ld        "buttonState"
  xori      BUTTON_B
  st        "buttonState"
  ld        "currentGem_order"
  beq       "setOrder_1"
  ldi       0
  bra       "storeOrder"
  label     "setOrder_1"
  ldi       1
  label     "storeOrder"
  st        "currentGem_order"
  label     "handleInputSwitch_done"
end

ldwi        0x09a0
call        "vAC"

org         0x09a0

gt_procedure "handleInputUp" do
  push

  ld        "buttonState"
  andi      BUTTON_UP
  bne       "handleInputUp_done"
  ld        "buttonState"
  xori      BUTTON_UP
  st        "buttonState"

  label     "handleInputUp_loop"
  ld        "currentGem_posY"
  addi      GEM_SIZE
  st        "currentGem_posY"
  call      "check"
  bne       "handleInputUp_loop"

  ld        "currentGem_posY"
  subi      GEM_SIZE
  st        "currentGem_posY"

  label     "handleInputUp_done"
  pop
end

ldwi        0x0aa0
call        "vAC"

org         0x0aa0

gt_procedure "handleInputDown" do
  ld        "buttonState"
  andi      BUTTON_DOWN
  bne       "handleInputDown_slow"
  ldi       TICK_RATE_FAST
  bra       "handleInputDown_done"
  label     "handleInputDown_slow"
  ldi       TICK_RATE
  label     "handleInputDown_done"
  st        "tickRate"
end

ldwi        0x0ba0
call        "vAC"

org         0x0ba0

gt_procedure "drawGem" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ld        "scratch_a"
  lslw
  addwi     "gemPointers"
  deek
  stw       "sysArgs0"

  ldw       "scratch_b"
  sys       64
end

gt_procedure "blankGem" do
  stw       "scratch_a"

  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "gems_0"
  stw       "sysArgs0"

  ldw       "scratch_a"

  sys       64
end

ldwi        0x0ca0
call        "vAC"

org         0x0ca0

gt_procedure "reset" do
  push

  call      "clearScreen"
  call      "drawBoard"

  ld        "frameCount"
  stw       "lastFrame"

  ldi       TICKS_PER_FRAME
  st        "tickCounter"

  ldi       TICK_RATE
  stw       "tickRate"

  ldi       0
  st        "currentGem_colorA"
  st        "currentGem_colorB"
  st        "currentGem_posX"
  st        "currentGem_posY"
  st        "currentGem_rotation"
  st        "currentGem_order"
  st        "nextGem_colorA"
  st        "nextGem_colorB"

  call      "spawnGem"
  call      "spawnGem"

  pop
end

ldwi        0x0da0
call        "vAC"

org         0x0da0

call        "reset"

gt_loop "main" do
  call      "waitFrame"

  call      "eraseCurrentGem"

  call      "handleInputRotate"
  call      "handleInputSwitch"
  call      "handleInputUp"
  call      "handleInputDown"
  call      "handleInputLeft"
  call      "handleInputRight"

  ld        "tickCounter"
  subw      "tickRate"
  st        "tickCounter"
  bgt       "tickDone"
  ldi       TICKS_PER_FRAME
  st        "tickCounter"

  ld        "currentGem_posY"
  addi      GEM_SIZE
  st        "currentGem_posY"

  call      "checkAndDrop"
  call      "gravity"

  label     "tickDone"

  call      "drawCurrentGem"
end

halt

org         0x0ea0

label       "gemPointers"
10.times do |i|
  byte      -> { value_of("gems_#{i}") & 0xff }
  byte      -> { value_of("gems_#{i}") >> 8 }
end

label       "gemPointers_color", 0x0fa0

org         0x0fa0 + RED * 2
byte        -> { value_of("gems_2") & 0xff }
byte        -> { value_of("gems_2") >> 8 }

org         0x0fa0 + BLUE * 2
byte        -> { value_of("gems_3") & 0xff }
byte        -> { value_of("gems_3") >> 8 }

org         0x0fa0 + ORANGE * 2
byte        -> { value_of("gems_4") & 0xff }
byte        -> { value_of("gems_4") >> 8 }

org         0x0fa0 + PURPLE * 2
byte        -> { value_of("gems_5") & 0xff }
byte        -> { value_of("gems_5") >> 8 }

org         0x0fa0 + RED_SMASHER * 2
byte        -> { value_of("gems_6") & 0xff }
byte        -> { value_of("gems_6") >> 8 }

org         0x0fa0 + BLUE_SMASHER * 2
byte        -> { value_of("gems_7") & 0xff }
byte        -> { value_of("gems_7") >> 8 }

org         0x0fa0 + ORANGE_SMASHER * 2
byte        -> { value_of("gems_8") & 0xff }
byte        -> { value_of("gems_8") >> 8 }

org         0x0fa0 + PURPLE_SMASHER * 2
byte        -> { value_of("gems_9") & 0xff }
byte        -> { value_of("gems_9") >> 8 }

done        0x0200
