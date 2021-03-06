
class Ropy
  attr_accessor :silent

  def initialize source
    @stack = []
    @memory = {}
    @tokens = source.split("\n").map{|line| line.split // }
    @i, @j = 0, 0
    @done = false
    @silent = false
    @prev_direction = :east
    
    @operations = {
      '&' => :join,
      '+' => :add,
      '-' => :subtract,
      '*' => :multiply,
      '/' => :devide,
      '<' => :swap,
      '>' => :duplicate,
      '"' => :stringify_stack,
      '?' => :pop,
      '%' => :modulo,
      '!' => :not,
      '[' => :put,
      ']' => :get,
      '#' => :printit
    }

    seek_token while [' ', nil].include?(current) and not @done
  end
  
  def seek_token
    if @j < @tokens[@i].size
      move :east
    elsif @i < @tokens.size
      @i += 1
      @j = 0
    end
  end

  def current
    @tokens[@i][@j]
  rescue Exception
    @done = true # END OF ROPE
  end

  def move_next
    neighbors = [
      :east        , :south_east  , :south       , :south_west  , 
      :west        , :north_west  , :north       , :north_east  , 
    ].map {|d| [d, peek_token(d)]}

    @done = neighbors.count{|x| not x[1].nil? }.zero? # END OF ROPE
    
    unless @done
      came_from_index = neighbors.index{|x| x[0] == oposite(@prev_direction)}
      
      if result == 0
        enumerator = :reverse_each
        range = ((came_from_index - 1)..(came_from_index + 7))
      else
        enumerator = :each
        range = ((came_from_index + 1)..(came_from_index + 9))
      end

      range.send(enumerator) do |i|        
        i %= 8
        unless neighbors[i][1].nil?
          move neighbors[i][0]
          return
        end
      end
    end
  end

  def oposite direction
    return :east if direction == :west
    return :west if direction == :east
    return :south if direction == :north
    return :north if direction == :south
    return :south_east if direction == :north_west
    return :south_west if direction == :north_east
    return :north_east if direction == :south_west
    return :north_west if direction == :south_east
  end

  def peek_token direction
    coords = coords_for_direction direction
    return nil if direction == oposite(@prev_direction) 
    return nil unless valid_coords(coords)
    return nil if @tokens[coords[0]][coords[1]] == ' '
    return @tokens[coords[0]][coords[1]]
  end

  def valid_coords coords
    coords[0] >= 0 and 
    coords[1] >= 0 and 
    @tokens.size > coords[0] and 
    @tokens[coords[0]].size > coords[1] 
  end

  def coords_for_direction direction
    case direction
    when :east then       [@i,     @j + 1]
    when :west then       [@i,     @j - 1]
    when :north then      [@i - 1, @j    ]
    when :south then      [@i + 1, @j    ]
    when :north_east then [@i - 1, @j + 1]
    when :south_east then [@i + 1, @j + 1]
    when :north_west then [@i - 1, @j - 1]
    when :south_west then [@i + 1, @j - 1]
    end
  end

  def move direction
    @i, @j = *(coords_for_direction direction)
    @prev_direction = direction
  end

  def execute
    evaluate until @done
  end

  def digit? token
    token.ord >= 48 and token.ord <= 57
  rescue
    false
  end

  def evaluate
    token = current
    if digit? token
      push
    elsif @operations.include? token
      self.send @operations[token]
    end
    debug token unless @silent
    move_next
  end

  def debug txt ; puts " #{txt} => [#{@stack.join(",")}"      ; end

  def push      ; @stack << current.to_i                      ; end
  def pop       ; @stack.pop                                  ; end
  def put       ; data,loc = pop,pop ; @memory[loc] = data    ; end
  def get       ; @stack << @memory[pop]                      ; end
  def add       ; @stack << pop + pop                         ; end
  def multiply  ; @stack << pop * pop                         ; end
  def subtract  ; @stack << pop - pop                         ; end
  def modulo    ; @stack << pop % pop                         ; end
  def devide    ; @stack << pop / pop                         ; end
  def join      ; @stack << "#{pop}#{pop}".to_i               ; end
  def swap      ; a,b = pop,pop ; @stack << a ; @stack << b   ; end
  def duplicate ; x = pop ; @stack << x ; @stack << x         ; end
  def result    ; @stack.last                                 ; end
  def not       ; @stack << (if pop > 0 then 0 else 1 end)    ; end
  def printit   ; print @stack.pop ; $stdout.flush            ; end

  def stringify_stack
    @stack = [@stack.map{|x| x.chr }.join.reverse]
  end
end

if __FILE__ == $PROGRAM_NAME
  STDERR.puts "Ropy version 0.2"
  source_file = ARGV.pop
  if source_file
    STDERR.puts "Executing file #{source_file}"
    ropy = Ropy.new File.read source_file
    ropy.silent = not(ARGV.include? "-v")
    ropy.execute
    STDERR.puts "Result => #{ropy.result}"
    puts ropy.result
  else
    puts "\nUsage:\n\tropy.rb [options] source_file\n\n"
    puts "  -v\tVerbose - display stack for each step in program"
    puts
  end
end

