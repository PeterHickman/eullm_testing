#!/usr/bin/env ruby

FILENAME_MAP = {
  'mac_mini_2018_intel.txt' => 'intel',
  'mac_mini_m1.txt' => 'm1',
  'mac_mini_m4_pro.txt' => 'm4 pro',
  'macbookpro_2018_intel.txt' => 'intel',
  'pi5.txt' => 'arm64',
  'pi4.txt' => 'arm64'
}

def check_block(filename, counter, block)
  errors = []

  unless block.select { |l| l == 'The server is running' }.any?
    errors << 'The server is not running'
  end

  if block.select { |l| l.include?('@@@') }.any?
    errors << 'Junk output generated @@@'
  end

  if block.select { |l| l.include?('"error"') }.any?
    errors << 'The server raised some errors'
  end

  if block.select { |l| l.include?('Process timed out after') }.any?
    errors << 'The curl request timed out'
  end

  if errors.any?
    puts "==> #{filename}"
    errors.each do |e|
      puts e
    end

    'Errors'
  else
    'Ok'
  end
end

def clean_name(filename)
  name = File.basename(filename, '.txt')
  name.split('_').reject { |i| %w[intel m1 m4 pro].include?(i) }.join(' ')
end

version = nil
md = ["|Machine|CPU|1|2|3|4|5|6|", "|---|--:|--:|--:|--:|--:|--:|--:|"]

ARGV.each do |filename|
  name = File.basename(filename)

  if FILENAME_MAP.key?(name)
    block = []
    collecting = false
    counter = -1

    report = Array.new(6)

    File.open(filename, 'r').each do |line|
      line.chomp!

      if line =~ /^eullm (.*) \((.*)\)$/
        if version.nil?
          version = $1
          puts "# #{version}"
          puts
        elsif version != $1
          puts "ERROR: Version #{version} does not match #{$1}"
        end

        cpu = $2
      end

      if line == 'TEST_START'
        collecting = true
        counter += 1
      elsif line == 'TEST_END'
        collecting = false
        report[counter] = check_block(filename, counter, block)
        block.clear
      elsif collecting
        block << line
      end
    end

    md << '|' + [clean_name(name), FILENAME_MAP[name], *report].join('|') + '|'
  else
    puts "==> Filename #{filename} not in the map"
  end
end

puts md
