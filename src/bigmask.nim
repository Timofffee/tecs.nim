type Bigmask* = object
  flags: seq[uint64]

proc initBigmask*(size: int = 2): Bigmask =
  result = Bigmask(flags: newSeq[uint64](size))

proc resize*(mask: var Bigmask, new_size: int) =
  mask.flags.setLen(new_size)

proc add*(mask: var Bigmask, flags: varargs[int]) =
  let flags_len = mask.flags.len
  for flag_idx in 0..flags.high():
    let pos = flags[flag_idx] div 64
    
    if (pos >= flags_len):
      echo "flag is too big"
      continue

    let idx = uint64(flags[flag_idx] mod 64)
    mask.flags[pos] = mask.flags[pos] or (1'u64 shl idx)

proc remove*(mask: var Bigmask, flags: varargs[int]) =
  let flags_len = mask.flags.len
  for flag_idx in 0..flags.high():
    let pos = flags[flag_idx] div 64
    
    if (pos >= flags_len):
      echo "flag is too big"
      continue

    let idx = uint64(flags[flag_idx] mod 64)
    mask.flags[pos] = mask.flags[pos] xor (1'u64 shl idx)

proc has*(mask: var Bigmask, flags: varargs[int]): bool =
  let flags_len = mask.flags.len
  var temp_mask = newSeq[uint64](flags_len)
  for flag_idx in 0..flags.high():
    let pos = flags[flag_idx] div 64
    
    if (pos >= flags_len):
      echo "flag is too big"
      return false

    let idx = uint64(flags[flag_idx] mod 64)
    temp_mask[pos] = mask.flags[pos] or (1'u64 shl idx)

  for idx in 0..<flags_len:
    if (temp_mask[idx] and mask.flags[idx]) != temp_mask[idx]:
      return false
  
  return true


proc clear*(mask: var Bigmask) =
  for idx in 0..<mask.flags.len:
    mask.flags[idx] = 0

# var b = initBigmask(2)
# b.add [129, 1, 64]
# echo b.flags
# echo b.has 1