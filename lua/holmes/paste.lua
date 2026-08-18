-- Atomic pastes: never render the terminal stream chunk by chunk, and take
-- large clipboard pastes from pbpaste instead of the wire.
--
-- Pasting with Cmd+V goes Ghostty -> tmux -> pty -> nvim, and that path is a
-- keystroke simulation with no length, no ordering guarantee, no checksum.
-- nvim receives it as a stream of ~1 KB chunks and, by default, inserts and
-- redraws each chunk as it arrives — the characters-typing-themselves
-- "animation". That per-chunk processing is also timing-sensitive (redraws
-- and autocmds run between chunks), which is how large pastes came out
-- corrupted intermittently: a 427 KB transcript once arrived with a 14 KB
-- region relocated ~296 KB from where it belonged.
--
-- The clipboard itself is fine: `"+p`, `:Paste` and `:r !pbpaste` round-trip
-- byte-for-byte, because they read the pasteboard directly instead of the
-- wire. So the clipboard is the authority, and the wire is used only to
-- detect that a paste happened and to tell clipboard pastes apart from
-- other sources.
--
-- Method (streamed pastes only — phase 1..3; phase -1 is the nvim_paste API
-- path, which never crossed a pty and is left alone):
--
--   1. Swallow EVERY streamed paste: accumulate chunks, insert nothing
--      until the stream ends. (An earlier version decided at phase 1 based
--      on the first chunk's size — but chunk boundaries are pty read timing,
--      so a large paste whose first chunk happened to be tiny fell through
--      to the default chunk-by-chunk path. Never gate on chunking.)
--   2. At phase 3, classify the complete stream and insert exactly once:
--        small stream      -> insert as-is. Atomic, no clipboard involved.
--        resembles a large clipboard (shared prefix + suffix cover >= half,
--        or sampled slices of the stream are found in the clipboard)
--                          -> this was a clipboard paste. Discard the stream
--                             and insert the pbpaste copy, silently — same
--                             result as :Paste, whether or not the wire was
--                             faithful.
--        resembles but tiny -> ambiguous: could be a truncated paste or an
--                             intentional small prefix selection (e.g. from
--                             a tmux buffer). Keep the stream, mention
--                             :Paste in case it was Cmd+V.
--        unrelated         -> a genuine non-clipboard paste. Insert it
--                             untouched, silently.
--
-- Escape hatch: `:lua vim.g.holmes_safe_paste = false` for the session
-- (restores default streaming). `:Paste` / <leader>v insert the clipboard
-- via pbpaste directly, bypassing the wire entirely.
--
-- Diagnostics: `:PasteReport` shows what the last few streamed pastes did —
-- bytes streamed vs. clipboard and how each was classified.

local M = {}

-- Only clipboards at least this large can replace a stream; below it the
-- wire has never been observed to fail.
M.threshold = 16 * 1024

-- Streams below this are inserted as-is without forking pbpaste.
local MIN_CLASSIFY = 512

-- A clipboard-resembling stream at least this large is taken from the
-- clipboard; smaller ones are kept (more plausibly an intentional prefix
-- selection than a paste truncated this early).
local MIN_SUBSTITUTE = 4096

local function read_clipboard()
  if vim.fn.executable("pbpaste") == 0 then
    return nil
  end
  local ok, proc = pcall(vim.system, { "pbpaste" }, { text = false })
  if not ok then
    return nil
  end
  local res = proc:wait(2000)
  if not res or res.code ~= 0 or not res.stdout or res.stdout == "" then
    return nil
  end
  return res.stdout
end

-- Splice a continuation chunk onto the reconstruction: its first element
-- continues our last line, the rest are new lines (charwise put semantics,
-- matching what the default vim.paste would have inserted).
local function absorb(got, chunk)
  if #chunk == 0 then
    return
  end
  got[#got] = got[#got] .. chunk[1]
  for i = 2, #chunk do
    got[#got + 1] = chunk[i]
  end
end

-- 1-based byte offset of the first difference (nil when equal).
local function first_diff(a, b)
  local n = math.min(#a, #b)
  local i = 1
  while i <= n do
    local j = math.min(i + 4095, n)
    if a:sub(i, j) ~= b:sub(i, j) then
      for k = i, j do
        if a:byte(k) ~= b:byte(k) then
          return k
        end
      end
    end
    i = j + 1
  end
  return #a ~= #b and n + 1 or nil
end

-- Length of the longest common byte suffix.
local function common_suffix(a, b)
  local n = math.min(#a, #b)
  local s = 0
  while s < n do
    local step = math.min(4096, n - s)
    if a:sub(#a - s - step + 1, #a - s) == b:sub(#b - s - step + 1, #b - s) then
      s = s + step
    else
      for k = 1, step do
        if a:byte(#a - s - k + 1) ~= b:byte(#b - s - k + 1) then
          return s + k - 1
        end
      end
    end
  end
  return s
end

-- Does `got` look like a (possibly damaged) copy of `clip`?
local function resembles(got, clip)
  local n = math.min(#got, #clip)
  local diff_at = first_diff(got, clip)
  local prefix = diff_at and (diff_at - 1) or n
  local suffix = common_suffix(got, clip)
  if math.min(prefix + suffix, n) >= n / 2 then
    return true
  end
  -- Scattered damage (bytes dropped in many places) leaves both the shared
  -- prefix and suffix short. Sample slices of the stream instead: a stream
  -- that is mostly clipboard substrings is a damaged clipboard paste.
  local SLICES, LEN = 8, 64
  if #got < SLICES * LEN then
    return false
  end
  local hits = 0
  for i = 0, SLICES - 1 do
    local start = 1 + math.floor(i * (#got - LEN) / (SLICES - 1))
    if clip:find(got:sub(start, start + LEN - 1), 1, true) then
      hits = hits + 1
    end
  end
  return hits >= 6
end

-- Ring of the last few streamed pastes, for :PasteReport.
local history = {}
local function record(entry)
  entry.at = os.date("%H:%M:%S")
  table.insert(history, 1, entry)
  history[9] = nil
end

function M.setup()
  if vim.g.holmes_safe_paste == nil then
    vim.g.holmes_safe_paste = true
  end
  -- Re-sourcing the config must not wrap the wrapper.
  if M._wrapped then
    return
  end
  M._wrapped = true

  local stream_paste = vim.paste
  local state = nil ---@type {got: string[]}?

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.paste = function(lines, phase)
    -- phase -1: whole paste in one call — the nvim_paste API path. It never
    -- went through the pty, so there is nothing to fix.
    if phase == -1 then
      state = nil
      return stream_paste(lines, phase)
    end

    if phase == 1 then
      state = nil
      if not vim.g.holmes_safe_paste
          -- cmdline-mode pastes have their own line-joining semantics; leave
          -- them to the default implementation.
          or vim.api.nvim_get_mode().mode:sub(1, 1) == "c"
      then
        return stream_paste(lines, phase)
      end
      local got = {}
      for i, l in ipairs(lines) do
        got[i] = l
      end
      state = { got = got }
      return true -- swallow; everything is inserted at phase 3
    end

    if not state then
      return stream_paste(lines, phase)
    end

    absorb(state.got, lines)
    if phase == 2 then
      return true
    end

    -- phase 3: stream complete. Classify, insert exactly once.
    local st = state
    state = nil
    local got_str = table.concat(st.got, "\n")

    if #got_str >= MIN_CLASSIFY then
      local clip_raw = read_clipboard()
      if clip_raw and #clip_raw >= M.threshold and resembles(got_str, clip_raw) then
        if #got_str >= MIN_SUBSTITUTE then
          -- A clipboard paste: discard the stream, insert the pbpaste copy.
          -- Silent — this is the normal path, same as :Paste.
          record({
            decision = got_str == clip_raw
                and "clipboard inserted (stream was faithful)"
                or "clipboard inserted (stream was damaged)",
            stream = #got_str, clip = #clip_raw,
          })
          return stream_paste(vim.split(clip_raw, "\n", { plain = true }), -1)
        end
        -- Opens/closes like the clipboard but tiny: plausibly an intentional
        -- prefix selection. Keep it, but leave a trail in case it wasn't.
        record({ decision = "kept: tiny clipboard fragment",
          stream = #got_str, clip = #clip_raw })
        local ok = stream_paste(st.got, -1)
        vim.schedule(function()
          vim.notify(
            ("Pasted %d bytes that look like a fragment of the %d-byte clipboard. "
              .. "If this was Cmd+V, the stream was truncated — use :Paste or <leader>v.")
            :format(#got_str, #clip_raw),
            vim.log.levels.INFO
          )
        end)
        return ok
      end
      record({ decision = "kept: not the clipboard", stream = #got_str,
        clip = clip_raw and #clip_raw or 0 })
    else
      record({ decision = "kept: small paste", stream = #got_str })
    end
    -- Not a large clipboard paste: insert the stream itself — still in one
    -- atomic put, so even non-clipboard pastes never animate.
    return stream_paste(st.got, -1)
  end

  -- Explicit, always-safe paste: reads the pasteboard, never the wire.
  vim.api.nvim_create_user_command("Paste", function()
    M.paste_clipboard()
  end, { desc = "Paste the system clipboard via pbpaste (bypasses the terminal stream)" })

  -- What did recent streamed pastes (Cmd+V etc.) actually do?
  vim.api.nvim_create_user_command("PasteReport", function()
    if #history == 0 then
      print("No streamed pastes this session.")
      return
    end
    for _, e in ipairs(history) do
      print(("%s  %s — stream %dB%s"):format(e.at, e.decision, e.stream,
        e.clip and (", clipboard " .. e.clip .. "B") or ""))
    end
  end, { desc = "Show how recent streamed pastes were classified" })
end

-- Insert the clipboard at the cursor, charwise, byte-exact. Used by :Paste
-- and <leader>v.
function M.paste_clipboard()
  local raw = read_clipboard()
  if not raw then
    vim.notify("pbpaste returned nothing", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_put(vim.split(raw, "\n", { plain = true }), "c", true, true)
end

return M
