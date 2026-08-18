-- Large pastes never trust the terminal stream: Cmd+V becomes :Paste.
--
-- Pasting with Cmd+V goes Ghostty -> tmux -> pty -> nvim, and that path is a
-- keystroke simulation with no length, no ordering guarantee, no checksum. A
-- 427 KB transcript pasted this way arrived with a contiguous 14 KB region
-- relocated ~296 KB from where it belonged; other pastes have arrived
-- truncated ("half the stuff"). Nothing warns you at paste time — the damage
-- surfaces later when a parser disagrees with the source.
--
-- The clipboard itself is fine: `"+p`, `:Paste` and `:r !pbpaste` round-trip
-- byte-for-byte, because they read the pasteboard directly instead of the
-- wire. So the clipboard is the authority, and the wire is retired: it is
-- used only to detect that a paste happened and to tell clipboard pastes
-- apart from other sources.
--
-- Method (streamed pastes only — phase 1..3; phase -1 is the nvim_paste API
-- path, which never crossed a pty and is left alone):
--
--   1. At phase 1, if the clipboard holds >= `threshold` bytes, engage:
--      swallow the stream and reconstruct it chunk by chunk. (No prefix
--      check here — corruption can hit the FIRST chunk too, and an early
--      prefix test would fail open exactly then.)
--   2. At phase 3, classify the reconstruction:
--        resembles the clipboard (shared prefix + suffix cover >= half of
--        the shorter of the two) and is reasonably large
--                         -> this was a clipboard paste. Discard the stream
--                            and insert the pbpaste copy, silently — exactly
--                            what :Paste does, whether or not the wire was
--                            faithful.
--        resembles but tiny -> ambiguous: could be a truncated paste or an
--                            intentional small prefix selection (e.g. from a
--                            tmux buffer). Keep the stream, but mention
--                            :Paste in case it was Cmd+V.
--        unrelated        -> a genuine non-clipboard paste (tmux buffer,
--                            another source). Insert it untouched, silently.
--
-- Escape hatch: `:lua vim.g.holmes_safe_paste = false` for the session.
-- `:Paste` / <leader>v insert the clipboard via pbpaste directly, bypassing
-- the wire entirely.
--
-- Diagnostics: `:PasteReport` shows what the last few streamed pastes did —
-- whether the wrapper engaged, how many bytes arrived vs. the clipboard,
-- and which way each paste was classified.

local M = {}

-- Only clipboards at least this large get the treatment; below it the wire
-- has never been observed to fail.
M.threshold = 16 * 1024

-- Don't bother forking pbpaste for a first chunk this small.
local MIN_FIRST_CHUNK = 64

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

-- Does `got` look like a damaged copy of `clip`? True when the shared
-- prefix plus shared suffix cover at least half of the shorter string —
-- which holds for truncation (prefix = everything that arrived), early
-- corruption (suffix = nearly everything), and mid-stream reordering
-- (both large), but not for a genuinely different paste.
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
  local state = nil ---@type {clip_raw: string, got: string[]}?
  local watch = nil ---@type {bytes: integer, why: string}? -- unengaged streams

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.paste = function(lines, phase)
    -- phase -1: whole paste in one call — the nvim_paste API path. It never
    -- went through the pty, so there is nothing to verify.
    if phase == -1 then
      state = nil
      return stream_paste(lines, phase)
    end

    if phase == 1 then
      state, watch = nil, nil
      local why
      if not vim.g.holmes_safe_paste then
        why = "safe_paste disabled"
      elseif vim.api.nvim_get_mode().mode:sub(1, 1) == "c" then
        -- cmdline-mode pastes have their own line-joining semantics; leave
        -- them to the default implementation.
        why = "cmdline mode"
      elseif #table.concat(lines, "\n") < MIN_FIRST_CHUNK then
        why = "first chunk under " .. MIN_FIRST_CHUNK .. "B"
      else
        local clip_raw = read_clipboard()
        if not clip_raw then
          why = "pbpaste unavailable/empty"
        elseif #clip_raw < M.threshold then
          why = ("clipboard %dB under %dB threshold"):format(#clip_raw, M.threshold)
        else
          local got = {}
          for i, l in ipairs(lines) do
            got[i] = l
          end
          state = { clip_raw = clip_raw, got = got }
        end
      end
      if not state then
        watch = { bytes = #table.concat(lines, "\n"), why = why }
        return stream_paste(lines, phase)
      end
      return true -- engaged: swallow; everything is inserted at phase 3
    end

    if not state then
      if watch then
        watch.bytes = watch.bytes + #table.concat(lines, "\n")
        if phase == 3 then
          record({ engaged = false, why = watch.why, stream = watch.bytes })
          watch = nil
        end
      end
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
    if not resembles(got_str, st.clip_raw) then
      -- A genuine non-clipboard paste (tmux buffer, another source). Silent.
      record({ engaged = true, decision = "kept: not the clipboard",
        stream = #got_str, clip = #st.clip_raw })
      return stream_paste(st.got, -1)
    end
    if #got_str < MIN_SUBSTITUTE then
      -- Opens/closes like the clipboard but tiny: plausibly an intentional
      -- prefix selection. Keep it, but leave a trail in case it wasn't.
      record({ engaged = true, decision = "kept: tiny clipboard fragment",
        stream = #got_str, clip = #st.clip_raw })
      local ok = stream_paste(st.got, -1)
      vim.schedule(function()
        vim.notify(
          ("Pasted %d bytes that look like a fragment of the %d-byte clipboard. "
            .. "If this was Cmd+V, the stream was truncated — use :Paste or <leader>v.")
          :format(#got_str, #st.clip_raw),
          vim.log.levels.INFO
        )
      end)
      return ok
    end

    -- A clipboard paste: discard the stream, insert the pbpaste copy.
    -- Silent — this is the normal path now, same as :Paste.
    record({
      engaged = true,
      decision = got_str == st.clip_raw
          and "clipboard inserted (stream was faithful)"
          or "clipboard inserted (stream was damaged)",
      stream = #got_str, clip = #st.clip_raw,
    })
    return stream_paste(vim.split(st.clip_raw, "\n", { plain = true }), -1)
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
      if e.engaged then
        print(("%s  %s — stream %dB, clipboard %dB")
          :format(e.at, e.decision, e.stream, e.clip))
      else
        print(("%s  not engaged (%s) — stream %dB inserted as-is")
          :format(e.at, e.why, e.stream))
      end
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
