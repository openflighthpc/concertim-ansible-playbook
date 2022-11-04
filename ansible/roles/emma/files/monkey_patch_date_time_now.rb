# Fix issue with DateTime.now returning a nonsense time.
def DateTime.now
  Date.current.to_datetime
end
