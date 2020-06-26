$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "asm"

name      "lines"

allocate_var "lastFrame"
allocate_var "scratch"

allocate_var "pixel"
allocate_var "screenX"
allocate_var "screenY"
allocate_var "color"

org       0x0200

ldwi      "screenMemory"
stw       "pixel"
ldwi      0xffff
stw       "lastFrame"
ldi       0xff
stw       "color"
ldi       0
stw       "screenX"
stw       "screenY"

macro :procedure, "waitFrames" do |start_label, return_label|
  ld      "frameCount"
  xorw    "lastFrame"
  beq     start_label
  ld      "frameCount"
  stw     "lastFrame"
  ldw     "scratch"
  subi    1
  stw     "scratch"
  bne     start_label
end

macro :procedure, "drawPixel" do |start_label, return_label|
  ldw     "color"
  poke    "pixel"

  inc     "pixel"

  inc     "screenX"

  ldw     "screenX"
  xori    160
  bne     return_label

  stw     "screenX"

  ldwi    0x0100
  addw    "screenY"
  stw     "screenY"

  ldwi    "screenMemory"
  addw    "screenY"
  stw     "pixel"

  ldw     "color"
  subi    1
  stw     "color"

  ldwi    0x7800
  xorw    "screenY"
  bne     return_label

  stw     "screenY"

  ldwi    "screenMemory"
  stw     "pixel"
end

ldwi      0x0300
call      "vAC"

org       0x0300

macro :loop, "main" do |start_label|
  ldi     1
  stw     "scratch"
  call    "waitFrames"
  call    "drawPixel"
end

done      0x0200
