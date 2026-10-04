# A binary min-heap: push items with a priority, always pop the smallest first.
class MinHeap
  def initialize
    @items = []
  end

  def empty? = @items.empty?

  def push(priority, value)
    @items << [priority, value]
    sift_up(@items.size - 1)
  end

  def pop
    return if @items.empty?

    swap(0, @items.size - 1)
    top = @items.pop
    sift_down(0)
    top
  end

  private

  def sift_up(i)
    while i > 0
      parent = (i - 1) / 2
      break if @items[parent][0] <= @items[i][0]

      swap(i, parent)
      i = parent
    end
  end

  def sift_down(i)
    size = @items.size
    loop do
      left, right = 2 * i + 1, 2 * i + 2
      smallest = i
      smallest = left if left < size && @items[left][0] < @items[smallest][0]
      smallest = right if right < size && @items[right][0] < @items[smallest][0]
      break if smallest == i

      swap(i, smallest)
      i = smallest
    end
  end

  def swap(a, b)
    @items[a], @items[b] = @items[b], @items[a]
  end
end
