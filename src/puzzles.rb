$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "asm"

TICKS_PER_FRAME = 30
TICK_RATE = 1
TICK_RATE_FAST = 10

BOARD_ORIGIN_X = 62
BOARD_ORIGIN_Y = 24
BOARD_WIDTH = 6
BOARD_HEIGHT = 12

BLACK = rgb_convert(0, 0, 0)
GREY = rgb_convert(85, 85, 85)
RED = rgb_convert(255, 0, 0)
BLUE = rgb_convert(0, 85, 255)
ORANGE = rgb_convert(255, 170, 0)
PURPLE = rgb_convert(170, 0, 255)
RED_SMASHER = rgb_convert(170, 0, 0)
BLUE_SMASHER = rgb_convert(0, 0, 255)
ORANGE_SMASHER = rgb_convert(170, 85, 0)
PURPLE_SMASHER = rgb_convert(85, 0, 170)

GEM_SIZE = 6

name        "puzzles"

initialize!

load_sprite "gems.png"

allocate_var "lastFrame"

allocate_var "scratch_a"
allocate_var "scratch_b"
allocate_var "scratch_c"
allocate_var "scratch_d"
allocate_var "scratch_e"

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

allocate_var "smasherPos"
allocate_var "smashSP"
allocate_var "smashCheckedSP"

def board_address(x, y)
  value_of("board") + x + ( y * BOARD_WIDTH )
end

def board_pixel_address(x, y)
  x = BOARD_ORIGIN_X + (x * GEM_SIZE)
  y = BOARD_ORIGIN_Y + (y * GEM_SIZE)
  pixel_address(x, y)
end

org         0x0200

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

gt_procedure "check" do
  push

  ldw       "currentGem_posX"
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

ldwi        0x0300
call        "vAC"

org         0x0300

gt_procedure "eraseCurrentGem" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "gems_0"
  stw       "sysArgs0"

  ldw       "currentGem_posX"
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
  beq       "drawCurrentGem_order0"

  label     "drawCurrentGem_order1"
  ld        "currentGem_colorB"
  st        "scratch_d"
  ld        "currentGem_colorA"
  bra       "drawCurrentGem_checkDone"

  label     "drawCurrentGem_order0"
  ld        "currentGem_colorA"
  st        "scratch_d"
  ld        "currentGem_colorB"
  label     "drawCurrentGem_checkDone"

  lslw
  addwi     "gemPointers"
  deek
  stw       "sysArgs0"

  ldw       "currentGem_posX"
  stw       "scratch_b"
  sys       64

  ld        "scratch_d"
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

gt_procedure "handleInputRotate" do
  ld        "buttonState"
  andi      BUTTON_A
  bne       "handleInputRotate_done"
  ld        "buttonState"
  xori      BUTTON_A
  st        "buttonState"

  ldw       "currentGem_posX"
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

  ldw       "currentGem_posX"
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

ldwi        0x0500
call        "vAC"

org         0x0500

gt_procedure "handleInputRight" do
  ld        "buttonState"
  andi      BUTTON_RIGHT
  bne       "handleInputRight_done"
  ld        "buttonState"
  xori      BUTTON_RIGHT
  st        "buttonState"

  ldw       "currentGem_posX"
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

  ldwi      0x0202
  addw      "scratch_a"
  peek
  stw       "scratch_b"
  ldwi      "gemPointers_reverse"
  addw      "scratch_b"
  peek
  stw       "scratch_b"
  ldwi      "gemPointers"
  addw      "scratch_b"
  deek
  stw       "scratch_b"

  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  peek
  bne       "gravity_nextCell"

  label     "gravity_blankCell"
  ldwi      "gems_0"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  ldw       "scratch_a"
  stw       "scratch_c"

  label     "gravity_findBase"
  ldw       "scratch_c"
  peek
  bne       "gravity_drawCell"
  ldwi      GEM_SIZE << 8
  addw      "scratch_c"
  stw       "scratch_c"
  bra       "gravity_findBase"

  label     "gravity_drawCell"
  ld        -> { value_of("scratch_c") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_c") + 1 }
  ldw       "scratch_b"
  stw       "sysArgs0"
  ldw       "scratch_c"
  sys       64
  bra       "gravity_nextCell"

  label     "gravity_nextCell"
  ld        "scratch_a"
  subi      GEM_SIZE
  st        "scratch_a"
  ld        "scratch_a"
  xori      board_pixel_address(-1, 0) & 255
  bne       "gravity_loop"

  ldi       board_pixel_address(5, 0) & 255
  st        "scratch_a"

  ld        -> { value_of("scratch_a") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_a") + 1 }
  ldwi      board_pixel_address(5, -1)
  xorw      "scratch_a"
  bne       "gravity_loop"
end

ldwi        0x0600
call        "vAC"

org         0x0600

gt_procedure "detectSmasher" do
  ldwi      "smashStack"
  stw       "smashSP"
  ldi       0
  doke      "smashSP"

  ldwi      board_pixel_address(5, 12)
  stw       "scratch_a"

  label     "detectSmasher_loop"
  ldwi      0x0202
  addw      "scratch_a"
  peek
  stw       "scratch_b"
  ldwi      "gemPointers_isSmasher"
  addw      "scratch_b"
  peek
  bne       "detectSmasher_nextCell"

  inc       "smashSP"
  inc       "smashSP"
  ldw       "scratch_a"
  doke      "smashSP"
  bra       "detectSmasher_done"

  label     "detectSmasher_nextCell"
  ld        "scratch_a"
  subi      GEM_SIZE
  st        "scratch_a"
  xori      board_pixel_address(-1, 0) & 255
  bne       "detectSmasher_loop"

  ldi       board_pixel_address(5, 0) & 255
  st        "scratch_a"

  ld        -> { value_of("scratch_a") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_a") + 1 }
  ldwi      board_pixel_address(5, -1)
  xorw      "scratch_a"
  bne       "detectSmasher_loop"

  label     "detectSmasher_done"
end

gt_procedure "createGroup" do
  push

  ldw       "smashSP"
  deek
  beq       "createGroup_done"
  peek
  stw       "scratch_b"

  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "smashCheckedStack"
  stw       "smashCheckedSP"

  label     "createGroup_loop"
  ldw       "smashSP"
  deek
  beq       "createGroup_done"
  stw       "scratch_a"
  ldw       "smashSP"
  subi      2
  stw       "smashSP"

  ldwi      "smashCheckedStack"
  stw       "scratch_e"
  label     "createGroup_checkLoop"
  ldw       "scratch_e"
  xorw      "smashCheckedSP"
  beq       "createGroup_checkLoopDone"
  ldw       "scratch_e"
  deek
  xorw      "scratch_a"
  beq       "createGroup_loop"
  ldw       "scratch_e"
  addi      2
  stw       "scratch_e"
  bne       "createGroup_checkLoop"
  label     "createGroup_checkLoopDone"

  ldw       "scratch_a"
  peek
  xorw      "scratch_b"
  bne       "createGroup_loop"

  ldwi      "gemPointers_getSmashed"
  addw      "scratch_b"
  peek
  stw       "scratch_d"
  ldwi      "gemPointers"
  addw      "scratch_d"
  deek
  stw       "scratch_d"

  ldw       "scratch_d"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  ldw       "scratch_a"
  doke      "smashCheckedSP"
  inc       "smashCheckedSP"
  inc       "smashCheckedSP"

  call      "createGroup_checkNorth"
  call      "createGroup_checkEast"
  call      "createGroup_checkSouth"
  call      "createGroup_checkWest"

  bra       "createGroup_loop"

  label     "createGroup_done"
  pop
end

ldwi        0x08a0
call        "vAC"

org         0x08a0

gt_procedure "createGroup_checkNorth" do
  ldw       "scratch_a"
  stw       "scratch_c"
  ld        -> { value_of("scratch_c") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_c") + 1 }
  ldw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkNorth_done"
  inc       "smashSP"
  inc       "smashSP"
  ldw       "scratch_c"
  doke      "smashSP"
  label     "createGroup_checkNorth_done"
end

gt_procedure "createGroup_checkEast" do
  ldw       "scratch_a"
  addi      GEM_SIZE
  stw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkEast_done"
  inc       "smashSP"
  inc       "smashSP"
  ldw       "scratch_c"
  doke      "smashSP"
  label     "createGroup_checkEast_done"
end

ldwi        0x09a0
call        "vAC"

org         0x09a0

gt_procedure "createGroup_checkSouth" do
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  stw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkSouth_done"
  inc       "smashSP"
  inc       "smashSP"
  ldw       "scratch_c"
  doke      "smashSP"
  label     "createGroup_checkSouth_done"
end

gt_procedure "createGroup_checkWest" do
  ldw       "scratch_a"
  subi      GEM_SIZE
  stw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkWest_done"
  inc       "smashSP"
  inc       "smashSP"
  ldw       "scratch_c"
  doke      "smashSP"
  label     "createGroup_checkWest_done"
end

ldwi        0x0aa0
call        "vAC"

org         0x0aa0

gt_procedure "smash" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      board_pixel_address(5, 12)
  stw       "scratch_a"

  label     "smash_loop"
  ldwi      0x0101
  addw      "scratch_a"
  peek
  stw       "scratch_b"
  ldwi      "gemPointers_isSmasher"
  addw      "scratch_b"
  peek
  bne       "smash_nextCell"

  ldwi      "gems_0"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  label     "smash_nextCell"
  ld        "scratch_a"
  subi      GEM_SIZE
  st        "scratch_a"
  xori      board_pixel_address(-1, 0) & 255
  bne       "smash_loop"

  ldi       board_pixel_address(5, 0) & 255
  st        "scratch_a"

  ld        -> { value_of("scratch_a") + 1 }
  subi      GEM_SIZE
  st        -> { value_of("scratch_a") + 1 }
  ldwi      board_pixel_address(5, -1)
  xorw      "scratch_a"
  bne       "smash_loop"
end

ldwi        0x0ba0
call        "vAC"

org         0x0ba0

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

  call      "drawCurrentGem"
  call      "spawnGem"

  label     "handleInputUp_done"
  pop
end

ldwi        0x13a0
call        "vAC"

org         0x13a0

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

ldwi        0x14a0
call        "vAC"

org         0x14a0

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
  ldwi      board_pixel_address(2, 0)
  stw       "currentGem_posX"
  ldi       0
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

ldwi        0x0ca0
call        "vAC"

org         0x0ca0

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
  call      "detectSmasher"
  call      "createGroup"
  call      "smash"

  label     "tickDone"

  call      "drawCurrentGem"
end

halt

org         0x0ea0

label       "gemPointers"
14.times do |i|
  byte      -> { value_of("gems_#{i}") & 0xff }
  byte      -> { value_of("gems_#{i}") >> 8 }
end

label       "gemPointers_reverse", 0x0fa0
org         0x0fa0 + BLACK
byte        0
org         0x0fa0 + GREY
byte        2
org         0x0fa0 + RED
byte        4
org         0x0fa0 + BLUE
byte        6
org         0x0fa0 + ORANGE
byte        8
org         0x0fa0 + PURPLE
byte        10
org         0x0fa0 + RED_SMASHER
byte        12
org         0x0fa0 + BLUE_SMASHER
byte        14
org         0x0fa0 + ORANGE_SMASHER
byte        16
org         0x0fa0 + PURPLE_SMASHER
byte        18

label       "gemPointers_isSmasher", 0x10a0
org         0x10a0 + BLACK
byte        1
org         0x10a0 + GREY
byte        1
org         0x10a0 + RED
byte        1
org         0x10a0 + BLUE
byte        1
org         0x10a0 + ORANGE
byte        1
org         0x10a0 + PURPLE
byte        1
org         0x10a0 + RED_SMASHER
byte        0
org         0x10a0 + BLUE_SMASHER
byte        0
org         0x10a0 + ORANGE_SMASHER
byte        0
org         0x10a0 + PURPLE_SMASHER
byte        0

label       "gemPointers_getSmashed", 0x11a0
org         0x11a0 + RED_SMASHER
byte        20
org         0x11a0 + BLUE_SMASHER
byte        22
org         0x11a0 + ORANGE_SMASHER
byte        24
org         0x11a0 + PURPLE_SMASHER
byte        26

org         0x12a0

label       "smashStack"
96.times do
  byte      0
end

org         0x15a0

label       "smashCheckedStack"
96.times do
  byte      0
end

done        0x0200
