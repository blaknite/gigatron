# This is the (back end for) a minimalistic vCPU assembler in Ruby.
# Use Ruby itself as the front end.
#
# Special words:
#       org     address       # Start new segment
#       label   'Name'        # Define a label
#       byte    byte, ...     # Insert data
#       done    address       # Finish assembly, address is execution address

require "json"
require "mini_magick"
require "securerandom"

BUTTON_RIGHT  = 0b00000001
BUTTON_LEFT   = 0b00000010
BUTTON_DOWN   = 0b00000100
BUTTON_UP     = 0b00001000
BUTTON_START  = 0b00010000
BUTTON_SELECT = 0b00100000
BUTTON_B      = 0b01000000
BUTTON_A      = 0b10000000

$_name = "out"

# Program segments are defined as follows:
# [addr, [byte, ...], addr, [byte, ...], ...]
$_data = [0x200, []]

# Pre-load system-defined labels:
# { name => addr }
$_labels = -> {
  file = File.read(File.join(File.dirname(__FILE__), '..', 'data', 'symbols.json'))
  data = JSON.parse(file)

  data.each.with_object({}) do |(k, v), obj|
    if v.is_a? Integer
      obj[k] = v
    else
      obj[k] = v.to_i(16)
    end
  end
}.call

$_next_var = $_labels["userVars"]

$_next_sprite = 0x8000 - 0x0100 + 160

def initialize!
  allocate_var("sysScratch")
end

def org(address)
  $_data += [address, []]
end

def ldwi(operand)
  byte(0x11, _low_byte(operand), _high_byte(operand))
end

def ld(operand)
  byte(0x1a, operand)
end

def ldw(operand)
  byte(0x21, operand)
end

def stw(operand)
  byte(0x2b, operand)
end

def bra(operand)
  byte(0x90, _branch_adjust(operand))
end

def beq(operand)
  byte(0x35, 0x3f, _branch_adjust(operand))
end

def bgt(operand)
  byte(0x35, 0x4d, _branch_adjust(operand))
end

def blt(operand)
  byte(0x35, 0x50, _branch_adjust(operand))
end

def bge(operand)
  byte(0x35, 0x53, _branch_adjust(operand))
end

def ble(operand)
  byte(0x35, 0x56, _branch_adjust(operand))
end

def bne(operand)
  byte(0x35, 0x72, _branch_adjust(operand))
end

def ldi(operand)
  byte(0x59, operand)
end

def st(operand)
  byte(0x5e, operand)
end

def pop
  byte(0x63)
end

def push
  byte(0x75)
end

def lup(operand)
  byte(0x7f, operand)
end

def andi(operand)
  byte(0x82, operand)
end

def ori(operand)
  byte(0x88, operand)
end

def xori(operand)
  byte(0x8c, operand)
end

def inc(operand)
  byte(0x93, operand)
end

def addw(operand)
  byte(0x99, operand)
end

def peek
  byte(0xad)
end

def sys(operand)
  byte(0xb4, 270 - [14, operand / 2].max)
end

def subw(operand)
  byte(0xb8, operand)
end

def defp(operand)
  byte(0xcd, _branch_adjust(operand))
end

def call(operand)
  byte(0xcf, operand)
end

def alloc(operand)
  byte(0xdf, operand)
end

def addi(operand)
  byte(0xe3, operand)
end

def subi(operand)
  byte(0xe6, operand)
end

def lslw(operand)
  byte(0xe9, operand)
end

def stlw(operand)
  byte(0xec, operand)
end

def ldlw(operand)
  byte(0xee, operand)
end

def poke(operand)
  byte(0xf0, operand)
end

def doke(operand)
  byte(0xf3, operand)
end

def deek
  byte(0xf6)
end

def andw(operand)
  byte(0xf8, operand)
end

def orw(operand)
  byte(0xfa, operand)
end

def xorw(operand)
  byte(0xfc, operand)
end

def ret
  byte(0xff)
end

def halt
  byte(0xb4, 0x80)
end

def byte(*bytes)
  bytes.each do |byte|
    $_data[-1] << _low_byte(byte)
  end
end

def label(key, value = nil)
  err("Label `#{key}` already defined") if label?(key)
  $_labels[key] = value ? value : $_data[-2] + $_data[-1].count
end

def label?(key)
  $_labels.key?(key)
end

def value_of(key)
  _eval_byte(key)
end

def _var_address(length = 2)
  var = $_next_var
  next_var = var + length

  if var <= 0x0080 && 0x0080 < next_var
    $_next_var = 0x0081
    _var_address(length)
  else
    err("Unable to allocate user variable") if next_var > 0x0100
    $_next_var = next_var
    var
  end
end

def allocate_var(name, length = 2)
  label name, _var_address(length)
end

def name(name)
  $_name = name
end

def done(start_address = 0x200)
  program = []

  puts "Assembling #{$_name}.gt1..."

  while (address, bytes = $_data.shift(2)) do
    break if address.nil?
    next if bytes.empty?

    puts " └─ Segment 0x#{address.to_s(16)} (#{bytes.count} bytes)"

    if (address + bytes.count) > ((address | 255) + 1)
      err("Page overrun in segment 0x#{address.to_s(16)}!")
    end

    bytes = bytes.map{ |byte| _eval_byte(byte) }

    program << (address >> 8)
    program << (address & 255)
    program << (bytes.count & 255)

    program += bytes
  end

  program << 0
  program << (start_address >> 8)
  program << (start_address & 255)

  File.open("dist/#{$_name}.gt1", 'w') do |f|
    f.write(program.pack('C*'))
  end

  puts "\nAssembly of #{$_name}.gt1 complete! (#{program.size} bytes)"
end

# Low byte of word
def _low_byte(operand)
  # operand & 255
  -> { _eval_byte(operand) & 255 }
end

# High byte of word
def _high_byte(operand)
  # operand >> 8
  -> { _eval_byte(operand) >> 8 }
end

def err(*args)
  puts("\nError: #{args.join(' ')}")
  exit(1)
end

# Adjust for pre-increment of vPC
def _branch_adjust(byte)
  -> { _eval_byte(byte) - 2 }
end

def _eval_byte(byte)
  byte = byte.call if byte.respond_to? :call
  if byte.is_a?(String) && byte.length > 1
    err("Undefined label `#{byte}`") unless label?(byte)
    byte = $_labels[byte]
  end
  byte.ord
end

def macro(method, *args, &block)
  send("macro_#{method}", *args, &block)
end

def macro_procedure(name, &block)
  start_label = "#{name}--start"
  return_label = "#{name}--return"
  store_label = "#{name}--store"

  allocate_var name

  defp      store_label
  label     start_label

  yield(start_label, return_label)

  label     return_label
  ret
  label     store_label
  stw       name
end

def macro_loop(name, &block)
  label     name

  yield(name)

  bra       name
end

def rgb_convert(red, green, blue)
  red = (red.to_f / 255 * 3).round.to_i
  green = (green.to_f / 255 * 3).round.to_i << 2
  blue = (blue.to_f / 255 * 3).round.to_i << 4

  red + green + blue
end

def pixel_address(x, y)
  $_labels["screenMemory"] + x + ( y * 0x0100)
end

def load_sprite(file)
  image = MiniMagick::Image.open("assets/#{file}")

  err("Image `#{file}` must be a multiple of 6 pixels wide") if image.width % 6 != 0

  basename = File.basename(file, File.extname(file))

  pixels = []

  image.get_pixels.each do |row|
    row.each_slice(6).with_index do |slice, index|
      pixels[index] = [] unless pixels[index]
      pixels[index] += slice.map { |pixel| rgb_convert(*pixel) }
    end
  end

  pixels.each.with_index do |sprite_pixels, sprite_index|
    sprite_name = "#{basename}_#{sprite_index}"

    if ($_next_sprite + sprite_pixels.length + 1) > (($_next_sprite & 0xff00) + 0x0100)
      $_next_sprite = ($_next_sprite & 0xff00) - 0x0100 + 160
    end

    org     $_next_sprite

    $_next_sprite += sprite_pixels.length + 1

    label   sprite_name
    byte    *sprite_pixels
    byte    -image.height
  end
end

def loading_screen(file, x, y)
  address = pixel_address(x, y)

  image = MiniMagick::Image.open("assets/#{file}")


  image.get_pixels.each do |row|
    org       address

    row.each do |pixel|
      byte    rgb_convert(*pixel)
    end

    address += 0x0100
  end
end

def bytes_for(value)
  value.divmod(256)
end

def dec(operand)
  ld(operand)
  subi(1)
  st(operand)
end

def addwi(operand)
  stw("sysScratch")
  ldwi(operand)
  addw("sysScratch")
end

def subwi(operand)
  stw("sysScratch")
  ldwi(operand)
  subw("sysScratch")
end

def andwi(operand)
  stw("sysScratch")
  ldwi(operand)
  andw("sysScratch")
end

def orwi(operand)
  stw("sysScratch")
  ldwi(operand)
  orw("sysScratch")
end

def xorwi(operand)
  stw("sysScratch")
  ldwi(operand)
  xorw("sysScratch")
end
