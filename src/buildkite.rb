$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "asm"

name      "buildkite"

light_green = rgb_convert(49, 239, 157)
dark_green = rgb_convert(29, 197, 121)

line = 0x0800

16.times do
  org      line

  160.times do
    byte   0xff
  end

  line += 0x0100
end

pixel_count = 1

22.times do
  org       line

  13.times do
    byte    0xff
  end

  pixel_count.times do
    byte    light_green
  end

  (90 - 2 * pixel_count).times do
    byte    0xff
  end

  pixel_count.times do
    byte    dark_green
  end

  pixel_count.times do
    byte    light_green
  end

  (57 - pixel_count).times do
    byte    0xff
  end

  line += 0x0100
  pixel_count += 2
end

23.times do
  org       line

  13.times do
    byte    0xff
  end

  45.times do
    byte    light_green
  end

  45.times do
    byte    dark_green
  end

  pixel_count.times do
    byte    light_green
  end

  (45 - pixel_count).times do
    byte    dark_green
  end

  12.times do
    byte    0xff
  end

  line += 0x0100
  pixel_count -= 2
end

pixel_count = 1

20.times do
  org       line

  (13 + pixel_count).times do
    byte    0xff
  end

  (45 - pixel_count).times do
    byte    light_green
  end

  (45 - pixel_count).times do
    byte    dark_green
  end

  pixel_count.times do
    byte    0xff
  end

  45.times do
    byte    dark_green
  end

  12.times do
    byte    0xff
  end

  line += 0x0100
  pixel_count += 2
end

3.times do
  line += 0x0100
end

pixel_count -= 2

21.times do
  org       line

  103.times do
    byte    0xff
  end

  pixel_count.times do
    byte    dark_green
  end

  (57 - pixel_count).times do
    byte    0xff
  end

  line += 0x0100
  pixel_count -= 2
end

15.times do
  org      line

  160.times do
    byte   0xff
  end

  line += 0x0100
end

org       0x0200

halt

done      0x0200
