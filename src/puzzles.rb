$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "asm"

TICKS_PER_FRAME = 30
TICK_RATE = 1
TICK_RATE_FAST = 10

FRAMES_PER_SECOND = 120
GAME_SECONDS = 150

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
load_sprite "next.png"
load_sprite "score.png"
load_sprite "over.png"
load_sprite "number.png"

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

allocate_var "smashSP"
allocate_var "smashCheckSP"
allocate_var "smashCheckedSP"

allocate_var "scoreUnits"
allocate_var "scoreTens"
allocate_var "scoreHundreds"
allocate_var "scoreThousands"

allocate_var "smashThisTick"
allocate_var "smashCombo"

allocate_var "framesRemaining"
allocate_var "secondsRemaining"

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

  ld        "scratch_a_1"
  addi      GEM_SIZE
  st        "scratch_a_1"
  xori      board_pixel_address(0, 12) >> 8
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

  ldw      "currentGem_posX"
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

  ldi       73
  call      "playTone"
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
  ld        "scratch_b_1"
  subi      GEM_SIZE
  st        "scratch_b_1"
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
  ld        "currentGem_colorA"
  st        "scratch_d"
  ld        "currentGem_colorB"
  bra       "drawCurrentGem_checkDone"

  label     "drawCurrentGem_order0"
  ld        "currentGem_colorB"
  st        "scratch_d"
  ld        "currentGem_colorA"
  label     "drawCurrentGem_checkDone"

  addwi     "gemPointers"
  deek
  stw       "sysArgs0"

  ldw       "currentGem_posX"
  stw       "scratch_b"
  sys       64

  ld        "scratch_d"
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
  ld        "scratch_b_1"
  subi      GEM_SIZE
  st        "scratch_b_1"
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

gt_procedure "drawNextGem" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ld        "nextGem_colorA"
  addwi     "gemPointers"
  deek
  stw       "sysArgs0"
  ldwi      board_pixel_address(9, 2) - 0x0201
  sys       64

  ld        "nextGem_colorB"
  addwi     "gemPointers"
  deek
  stw       "sysArgs0"
  ldwi      board_pixel_address(10, 2) - 0x0201
  sys       64
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
  ld        "scratch_a_1"
  subi      GEM_SIZE
  st        "scratch_a_1"
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
  ld        "scratch_a_1"
  subi      GEM_SIZE
  st        "scratch_a_1"
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
  ld        "scratch_a_1"
  subi      GEM_SIZE
  st        "scratch_a_1"
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
  push

  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      board_pixel_address(5, 10)
  stw       "scratch_a"

  ldi       1
  st        "scratch_d"

  label     "gravity_loop"
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  stw       "scratch_c"
  peek
  bne       "gravity_nextCell"

  ldwi      0x0202
  addw      "scratch_a"
  peek
  beq       "gravity_nextCell"
  stw       "scratch_b"
  ldwi      "gemPointers_reverse"
  addw      "scratch_b"
  peek
  stw       "scratch_b"
  ldwi      "gemPointers"
  addw      "scratch_b"
  deek
  stw       "scratch_b"

  label     "gravity_blankCell"
  ldwi      "gems_0"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  label     "gravity_findBase"
  ldw       "scratch_c"
  peek
  bne       "gravity_drawCell"
  ld        "scratch_c_1"
  addi      GEM_SIZE
  st        "scratch_c_1"
  bra       "gravity_findBase"

  label     "gravity_drawCell"
  ld        "scratch_c_1"
  subi      GEM_SIZE
  st        "scratch_c_1"
  ldw       "scratch_b"
  stw       "sysArgs0"
  ldw       "scratch_c"
  sys       64

  ldi       0
  st        "scratch_d"
  bra       "gravity_nextCell"

  label     "gravity_nextCell"
  ld        "scratch_a"
  subi      GEM_SIZE
  st        "scratch_a"
  xori      board_pixel_address(-1, 0) & 0xff
  bne       "gravity_loop"

  ldi       board_pixel_address(5, 0) & 0xff
  st        "scratch_a"

  ld        "scratch_a_1"
  subi      GEM_SIZE
  st        "scratch_a_1"
  xori      board_pixel_address(0, -1) >> 8
  bne       "gravity_loop"

  ld        "scratch_d"
  bne       "gravity_noTone"
  ldi       73
  call      "playTone"
  label     "gravity_noTone"

  pop
end

ldwi        0x0600
call        "vAC"

org         0x0600

gt_procedure "detectSmasher" do
  push

  ldwi      "smashStack"
  stw       "smashSP"
  ldi       0
  doke      "smashSP"

  ldwi      board_pixel_address(0, 0)
  stw       "scratch_a"

  label     "detectSmasher_loop"
  ldwi      0x0202
  addw      "scratch_a"
  peek
  beq       "detectSmasher_nextCell"
  stw       "scratch_b"
  ldwi      "gemPointers_isSmasher"
  addw      "scratch_b"
  peek
  bne       "detectSmasher_nextCell"

  ldi       1
  st        "scratch_c"
  call      "detectSmasher_detectAdjacent"
  ld        "scratch_c"
  bne       "detectSmasher_nextCell"

  inc       "smashSP"
  inc       "smashSP"
  ldw       "scratch_a"
  doke      "smashSP"

  label     "detectSmasher_nextCell"
  ld        "scratch_a"
  addi      GEM_SIZE
  st        "scratch_a"
  xori      board_pixel_address(6, 0) & 0xff
  bne       "detectSmasher_loop"

  ldi       board_pixel_address(0, 0) & 0xff
  st        "scratch_a"

  ld        "scratch_a_1"
  addi      GEM_SIZE
  st        "scratch_a_1"
  xori      board_pixel_address(0, 13) >> 8
  bne       "detectSmasher_loop"

  label     "detectSmasher_done"
  pop
end

gt_procedure "createGroup" do
  push

  # set sprite draw function
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  # reset check stack
  ldwi      "smashCheckStack"
  stw       "smashCheckSP"
  ldi       0
  doke      "smashCheckSP"

  # reset checked stack
  ldwi      "smashCheckedStack"
  stw       "smashCheckedSP"

  # pop smasher off stack
  label     "createGroup_loop"
  ldw       "smashSP"
  deek
  beq       "createGroup_done"
  inc       "smashCheckSP"
  inc       "smashCheckSP"
  doke      "smashCheckSP"
  peek
  stw       "scratch_b"
  ld        "smashSP"
  subi      2
  st        "smashSP"

  # get matching smashed sprite
  ldwi      "gemPointers_getSmashed"
  addw      "scratch_b"
  peek
  stw       "scratch_d"
  ldwi      "gemPointers"
  addw      "scratch_d"
  deek
  stw       "scratch_d"

  # start flood fill from stacker position
  label     "createGroup_fillLoop"
  ldw       "smashCheckSP"
  deek
  beq       "createGroup_fillDone"
  stw       "scratch_a"
  ld        "smashCheckSP"
  subi      2
  st        "smashCheckSP"

  # do not fill already filled cells
  ldwi      "smashCheckedStack"
  stw       "scratch_e"

  label     "createGroup_checkLoop"
  ldw       "scratch_e"
  xorw      "smashCheckedSP"
  beq       "createGroup_checkLoopDone"
  ldw       "scratch_e"
  deek
  xorw      "scratch_a"
  beq       "createGroup_fillLoop"
  inc       "scratch_e"
  inc       "scratch_e"
  bra       "createGroup_checkLoop"
  label     "createGroup_checkLoopDone"

  # return unless matching cell
  ldw       "scratch_a"
  peek
  xorw      "scratch_b"
  bne       "createGroup_fillLoop"

  # fill cell
  ldw       "scratch_d"
  stw       "sysArgs0"
  ldw       "scratch_a"
  sys       64

  # mark cell as checked
  ldw       "scratch_a"
  doke      "smashCheckedSP"
  inc       "smashCheckedSP"
  inc       "smashCheckedSP"

  # push adjacent cells onto the check stack
  call      "createGroup_checkNorthWest"
  call      "createGroup_checkSouthEast"

  bra       "createGroup_fillLoop"
  label     "createGroup_fillDone"
  bra       "createGroup_loop"

  label     "createGroup_done"
  pop
end

ldwi        0x08a0
call        "vAC"

org         0x08a0

gt_procedure "createGroup_checkNorthWest" do
  label     "createGroup_checkNorthWest_west"
  ldw       "scratch_a"
  subi      GEM_SIZE
  stw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkNorthWest_north"
  inc       "smashCheckSP"
  inc       "smashCheckSP"
  ldw       "scratch_c"
  doke      "smashCheckSP"

  label     "createGroup_checkNorthWest_north"
  ldwi      GEM_SIZE << 8
  stw       "scratch_c"
  ldw       "scratch_a"
  subw      "scratch_c"
  stw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkNorthWest_done"
  inc       "smashCheckSP"
  inc       "smashCheckSP"
  ldw       "scratch_c"
  doke      "smashCheckSP"

  label     "createGroup_checkNorthWest_done"
end

ldwi        0x09a0
call        "vAC"

org         0x09a0

gt_procedure "createGroup_checkSouthEast" do
  label     "createGroup_checkSouthEast_east"
  ldi       GEM_SIZE
  addw      "scratch_a"
  stw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkSouthEast_south"
  inc       "smashCheckSP"
  inc       "smashCheckSP"
  ldw       "scratch_c"
  doke      "smashCheckSP"

  label     "createGroup_checkSouthEast_south"
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  stw       "scratch_c"
  peek
  xori      GREY
  beq       "createGroup_checkSouthEast_done"
  inc       "smashCheckSP"
  inc       "smashCheckSP"
  ldw       "scratch_c"
  doke      "smashCheckSP"

  label     "createGroup_checkSouthEast_done"
end

ldwi        0x0aa0
call        "vAC"

org         0x0aa0

gt_procedure "detectSmasher_detectAdjacent" do
  label     "detectSmasher_detectAdjacent_west"
  ldw       "scratch_a"
  subi      GEM_SIZE
  peek
  xorw      "scratch_b"
  bne       "detectSmasher_detectAdjacent_north"
  ldi       0
  st        "scratch_c"

  label     "detectSmasher_detectAdjacent_north"
  ldwi      GEM_SIZE << 8
  stw       "scratch_d"
  ldw       "scratch_a"
  subw      "scratch_d"
  stw       "scratch_d"
  peek
  xorw      "scratch_b"
  bne       "detectSmasher_detectAdjacent_east"
  ldi       0
  st        "scratch_c"

  label     "detectSmasher_detectAdjacent_east"
  ldi       GEM_SIZE
  addw      "scratch_a"
  peek
  xorw      "scratch_b"
  bne       "detectSmasher_detectAdjacent_south"
  ldi       0
  st        "scratch_c"

  label     "detectSmasher_detectAdjacent_south"
  ldwi      GEM_SIZE << 8
  addw      "scratch_a"
  peek
  xorw      "scratch_b"
  bne       "detectSmasher_detectAdjacent_done"
  ldi       0
  st        "scratch_c"

  label     "detectSmasher_detectAdjacent_done"
end

ldwi        0x0ba0
call        "vAC"

org         0x0ba0

gt_procedure "incrementScore" do
  ld        "scoreUnits"
  addw      "smashCombo"
  st        "scoreUnits"
  subi      10
  blt       "incrementScore_done"
  st        "scoreUnits"
  inc       "scoreTens"
  ld        "scoreTens"
  xori      10
  bne       "incrementScore_done"
  st        "scoreTens"
  inc       "scoreHundreds"
  ld        "scoreHundreds"
  xori      10
  bne       "incrementScore_done"
  st        "scoreHundreds"
  inc       "scoreThousands"
  ld        "scoreThousands"
  xori      10
  bne       "incrementScore_done"
  st        "scoreThousands"
  label     "incrementScore_done"
end

ldwi        0x22a0
call        "vAC"

org         0x22a0

gt_procedure "drawScore" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "numberPointers_reverse"
  stw       "scratch_a"

  ldwi      "numberPointers"
  stw       "scratch_b"

  # ldw       "scoreThousands"
  # addw      "scratch_a"
  # peek
  # addw      "scratch_b"
  # deek
  # stw       "sysArgs0"
  # ldwi      board_pixel_address(-7, 2)
  # sys       64

  ldw      "scoreHundreds"
  addw     "scratch_a"
  peek
  addw      "scratch_b"
  deek
  stw       "sysArgs0"
  ldwi      board_pixel_address(-6, 2) - 3
  sys       64

  ldw       "scoreTens"
  addw      "scratch_a"
  peek
  addw      "scratch_b"
  deek
  stw       "sysArgs0"
  ldwi      board_pixel_address(-5, 2) - 3
  sys       64

  ldw       "scoreUnits"
  addw      "scratch_a"
  peek
  addw      "scratch_b"
  deek
  stw       "sysArgs0"
  ldwi      board_pixel_address(-4, 2) - 3
  sys       64

  ldwi      "number_0"
  stw       "sysArgs0"
  ldwi      board_pixel_address(-3, 2) - 3
  sys       64
end

ldwi        0x25a0
call        "vAC"

org         0x25a0

gt_procedure "drawGameTime" do
  ldwi      pixel_address(5, 115)
  stw       "scratch_a"

  label     "drawGameTime_nextPixel"
  ldi       rgb_convert(0, 170, 255)
  poke      "scratch_a"

  inc       "scratch_a"
  ld        "scratch_a"
  xori      GAME_SECONDS + 5
  bne       "drawGameTime_nextPixel"
end

ldwi        0x26a0
call        "vAC"

org         0x26a0

gt_procedure "updateGameTime" do
  ld        "framesRemaining"
  subi      1
  st        "framesRemaining"
  bne       "updateGameTime_done"

  ldi       FRAMES_PER_SECOND
  st        "framesRemaining"

  ld        "secondsRemaining"
  subi      1
  st        "secondsRemaining"

  ldwi      pixel_address(5, 115)
  addw      "secondsRemaining"
  stw       "scratch_a"
  ldi       rgb_convert(0, 0, 170)
  poke      "scratch_a"

  ld        "secondsRemaining"
  bne       "updateGameTime_done"

  label     "updateGameTime_done"
end

ldwi        0x27a0
call        "vAC"

org         0x27a0

gt_procedure "resetAudio" do
  ldwi      ["channel1", "wavA"]
  stw       "scratch_a"
  ldwi      0x0100
  doke      "scratch_a"

  ldwi      ["channel2", "wavA"]
  stw       "scratch_a"
  ldwi      0x0200
  doke      "scratch_a"

  ldwi      ["channel3", "wavA"]
  stw       "scratch_a"
  ldwi      0x0000
  doke      "scratch_a"

  ldwi      ["channel4", "wavA"]
  stw       "scratch_a"
  ldwi      0x0000
  doke      "scratch_a"
end

ldwi        0x28a0
call        "vAC"

org         0x28a0

gt_procedure "playTone" do
  lslw
  stw       "scratch_a"

  ldwi      "notesTable"
  addw      "scratch_a"
  stw       "scratch_a"
  lup       0x00
  st        "scratch_b"
  ldw       "scratch_a"
  lup       0x01
  st        ["scratch_b", 1]

  ldwi      ["channel1", "keyL"]
  stw       "scratch_c"
  ldw       "scratch_b"
  doke      "scratch_c"

  ldwi      ["channel2", "keyL"]
  stw       "scratch_c"
  ldw       "scratch_b"
  doke      "scratch_c"

  ldwi      ["channel3", "keyL"]
  stw       "scratch_c"
  ldi       0
  doke      "scratch_c"

  ldwi      ["channel4", "keyL"]
  stw       "scratch_c"
  ldi       0
  doke      "scratch_c"

  ldi       3
  st        "soundTimer"
end

ldwi        0x19a0
call        "vAC"

org         0x19a0

gt_procedure "drawNextHeading" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "next_0"
  stw       "sysArgs0"
  ldwi      board_pixel_address(8, 0)
  sys       64
  ldwi      "next_1"
  stw       "sysArgs0"
  ldwi      board_pixel_address(9, 0)
  sys       64
  ldwi      "next_2"
  stw       "sysArgs0"
  ldwi      board_pixel_address(10, 0)
  sys       64
  ldwi      "next_3"
  stw       "sysArgs0"
  ldwi      board_pixel_address(11, 0)
  sys       64
end

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

ldwi        0x20a0
call        "vAC"

org         0x20a0

gt_procedure "drawScoreHeading" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "score_0"
  stw       "sysArgs0"
  ldwi      board_pixel_address(-7, 0)
  sys       64
  ldwi      "score_1"
  stw       "sysArgs0"
  ldwi      board_pixel_address(-6, 0)
  sys       64
  ldwi      "score_2"
  stw       "sysArgs0"
  ldwi      board_pixel_address(-5, 0)
  sys       64
  ldwi      "score_3"
  stw       "sysArgs0"
  ldwi      board_pixel_address(-4, 0)
  sys       64
  ldwi      "score_4"
  stw       "sysArgs0"
  ldwi      board_pixel_address(-3, 0)
  sys       64
end

ldwi        0x21a0
call        "vAC"

org         0x21a0

gt_procedure "drawGameOver" do
  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      "over_0"
  stw       "sysArgs0"
  ldwi      board_pixel_address(1, 14) - 0x0200
  sys       64
  ldwi      "over_1"
  stw       "sysArgs0"
  ldwi      board_pixel_address(2, 14) - 0x0200
  sys       64
  ldwi      "over_2"
  stw       "sysArgs0"
  ldwi      board_pixel_address(3, 14) - 0x0200
  sys       64
  ldwi      "over_3"
  stw       "sysArgs0"
  ldwi      board_pixel_address(4, 14) - 0x0200
  sys       64
end

gt_procedure "detectChain" do
  ld        "smashThisTick"
  bne       "detectChain_noChain"
  inc       "smashCombo"
  bra       "detectChain_done"

  label     "detectChain_noChain"
  ld        "smashThisTick"
  beq       "detectChain_done"
  ldi       1
  st        "smashCombo"

  label     "detectChain_done"
end

ldwi        0x0ca0
call        "vAC"

org         0x0ca0

gt_procedure "smash" do
  push

  ldwi      "SYS_Sprite6_v3_64"
  stw       "sysFn"

  ldwi      board_pixel_address(0, 0)
  stw       "scratch_a"

  ldi       1
  st        "smashThisTick"

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

  call      "incrementScore"

  ldi       0
  st        "smashThisTick"

  label     "smash_nextCell"
  ld        "scratch_a"
  addi      GEM_SIZE
  st        "scratch_a"
  xori      board_pixel_address(6, 0) & 0xff
  bne       "smash_loop"

  ldi       board_pixel_address(0, 0) & 0xff
  st        "scratch_a"

  ld        "scratch_a_1"
  addi      GEM_SIZE
  st        "scratch_a_1"
  ldwi      board_pixel_address(0, 13)
  xorw      "scratch_a"
  bne       "smash_loop"

  pop
end

ldwi        0x0da0
call        "vAC"

org         0x0da0

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

  ldi       0
  st        "tickCounter"

  label     "handleInputUp_done"
  pop
end

ldwi        0x0ea0
call        "vAC"

org         0x0ea0

gt_procedure "checkGameOver" do
  ldwi      board_pixel_address(2, 0)
  peek
  bne       "checkGameOver_done"
  ldwi      board_pixel_address(3, 0)
  peek
  bne       "checkGameOver_done"
  label     "checkGameOver_done"
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

ldwi        0x0fa0
call        "vAC"

org         0x0fa0

gt_procedure "generateGem" do
  ldwi      "SYS_Random_34"
  stw       "sysFn"
  sys       34
  # Random value between 0-3 for gem color
  ld        "entropy"
  andi      3
  addi      2
  stw       "scratch_a"
  # Random value between 0-3 for smasher. if == 0 then smasher.
  ld        ["entropy", 1]
  andi      3
  bne       "returnGem"
  ldi       4
  addw      "scratch_a"
  st        "scratch_a"
  label     "returnGem"
  ld        "scratch_a"
  lslw
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
  st        "nextGem_colorA"

  # Generate next gem B
  call      "generateGem"
  st        "nextGem_colorB"

  call      "drawNextGem"

  pop
end

ldwi        0x10a0
call        "vAC"

org         0x10a0

gt_procedure "reset" do
  push

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
  stw       "scoreUnits"
  stw       "scoreTens"
  stw       "scoreHundreds"
  stw       "scoreThousands"

  ldi       1
  stw       "smashThisTick"
  stw       "smashCombo"

  ldi       FRAMES_PER_SECOND
  stw       "framesRemaining"

  ldi       GAME_SECONDS
  stw       "secondsRemaining"

  call      "resetAudio"

  call      "clearScreen"
  call      "drawBoard"
  call      "drawScoreHeading"
  call      "drawNextHeading"
  call      "drawScore"
  call      "drawGameTime"

  call      "spawnGem"
  call      "spawnGem"

  pop
end

ldwi        0x11a0
call        "vAC"

org         0x11a0

call        "reset"

gt_loop "main" do
  ld        "buttonState"
  ori       0b00110000
  xori      0b11111111
  beq       "handleInputDone"
  call      "eraseCurrentGem"
  call      "handleInputRotate"
  call      "handleInputSwitch"
  call      "handleInputUp"
  call      "handleInputDown"
  call      "handleInputLeft"
  call      "handleInputRight"
  label     "handleInputDone"

  ld        "frameCount"
  xorw      "lastFrame"
  beq       "frameDone"
  ld        "frameCount"
  st        "lastFrame"

  call      "updateGameTime"
  beq       "gameOver"

  ld        "tickCounter"
  subw      "tickRate"
  st        "tickCounter"
  bgt       "tickDone"
  ldi       TICKS_PER_FRAME
  st        "tickCounter"

  call      "eraseCurrentGem"

  ld        "currentGem_posY"
  addi      GEM_SIZE
  st        "currentGem_posY"

  call      "checkAndDrop"
  call      "gravity"
  call      "detectSmasher"
  call      "createGroup"
  call      "smash"
  call      "detectChain"
  call      "drawScore"

  call      "checkGameOver"
  bne       "gameOver"

  label     "tickDone"
  label     "frameDone"

  call      "drawCurrentGem"
end

label       "gameOver"
ldwi        0x29a0
call        "vAC"

org         0x29a0

ldi         TICK_RATE
st          "tickRate"
call        "drawGameOver"
ldi         36
stw         "scratch_d"
ldi         37
stw         "scratch_e"

gt_loop "gameOver_loop" do
  ld        "buttonState"
  andi      BUTTON_START
  beq       "newGame"

  ld        "frameCount"
  xorw      "lastFrame"
  beq       "gameOver_tickDone"
  ld        "frameCount"
  st        "lastFrame"
  ld        "tickCounter"
  subw      "tickRate"
  st        "tickCounter"
  bgt       "gameOver_tickDone"
  ldi       5
  st        "tickCounter"

  ld        "scratch_d"
  beq       "gameOver_tickDone"
  subi      12
  st        "scratch_d"
  addw      "scratch_e"
  call      "playTone"

  label     "gameOver_tickDone"
end

label       "newGame"
ldwi        0x11a0
call        "vAC"

halt

org         0x12a0

label       "gemPointers"
14.times do |i|
  byte      -> { value_of("gems_#{i}") & 0xff }
  byte      -> { value_of("gems_#{i}") >> 8 }
end

GEM_REVERSE_ADDR = 0x13a0
label       "gemPointers_reverse", GEM_REVERSE_ADDR
org         GEM_REVERSE_ADDR + BLACK
byte        0
org         GEM_REVERSE_ADDR + GREY
byte        2
org         GEM_REVERSE_ADDR + RED
byte        4
org         GEM_REVERSE_ADDR + BLUE
byte        6
org         GEM_REVERSE_ADDR + ORANGE
byte        8
org         GEM_REVERSE_ADDR + PURPLE
byte        10
org         GEM_REVERSE_ADDR + RED_SMASHER
byte        12
org         GEM_REVERSE_ADDR + BLUE_SMASHER
byte        14
org         GEM_REVERSE_ADDR + ORANGE_SMASHER
byte        16
org         GEM_REVERSE_ADDR + PURPLE_SMASHER
byte        18

IS_SMASHER_ADDR = 0x14a0
label       "gemPointers_isSmasher", IS_SMASHER_ADDR
org         IS_SMASHER_ADDR + BLACK
byte        1
org         IS_SMASHER_ADDR + GREY
byte        1
org         IS_SMASHER_ADDR + RED
byte        1
org         IS_SMASHER_ADDR + BLUE
byte        1
org         IS_SMASHER_ADDR + ORANGE
byte        1
org         IS_SMASHER_ADDR + PURPLE
byte        1
org         IS_SMASHER_ADDR + RED_SMASHER
byte        0
org         IS_SMASHER_ADDR + BLUE_SMASHER
byte        0
org         IS_SMASHER_ADDR + ORANGE_SMASHER
byte        0
org         IS_SMASHER_ADDR + PURPLE_SMASHER
byte        0

GET_SMASHER_ADDR = 0x15a0
label       "gemPointers_getSmashed", GET_SMASHER_ADDR
org         GET_SMASHER_ADDR + RED_SMASHER
byte        20
org         GET_SMASHER_ADDR + BLUE_SMASHER
byte        22
org         GET_SMASHER_ADDR + ORANGE_SMASHER
byte        24
org         GET_SMASHER_ADDR + PURPLE_SMASHER
byte        26

org         0x16a0

label       "smashStack"
96.times do
  byte      0
end

org         0x17a0

label       "smashCheckStack"
96.times do
  byte      0
end

org         0x18a0

label       "smashCheckedStack"
96.times do
  byte      0
end

org         0x23a0

label       "numberPointers"
10.times do |i|
  byte      -> { value_of("number_#{i}") & 0xff }
  byte      -> { value_of("number_#{i}") >> 8 }
end

NUMBERS_ADDR = 0x24a0
label       "numberPointers_reverse", NUMBERS_ADDR
org         NUMBERS_ADDR + 0
byte        0
org         NUMBERS_ADDR + 1
byte        2
org         NUMBERS_ADDR + 2
byte        4
org         NUMBERS_ADDR + 3
byte        6
org         NUMBERS_ADDR + 4
byte        8
org         NUMBERS_ADDR + 5
byte        10
org         NUMBERS_ADDR + 6
byte        12
org         NUMBERS_ADDR + 7
byte        14
org         NUMBERS_ADDR + 8
byte        16
org         NUMBERS_ADDR + 9
byte        18

done        0x0200
