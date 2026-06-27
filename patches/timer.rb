class Timer
  attr_accessor :start, :end

  def initialize
    @start = Hokusai.monotonic
    @end = @start
  end

  def elapsed?(seconds)
    return true if @end - @start > seconds
    
    false
  end

  def restart
    @start = Hokusai.monotonic
    @end = @start
  end

  def elapsed
    @end - @start
  end

  def next
    @end = Hokusai.monotonic
  end
end
