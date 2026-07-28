-- Safe large pastes: verify the terminal stream against the clipboard.
--
-- Pasting with Cmd+V goes Ghostty -> tmux -> pty -> nvim, and that path is a
-- keystroke simulation with no length, no ordering guarantee, no checksum. A
-- 427 KB transcript pasted this way arrived with a contiguous 14 KB region
-- relocated ~296 KB from where it belonged (bytes 130124-144237), severing a
-- line mid-token. Nothing was lost, so the file looked fine — the damage
-- surfaced days later when a parser disagreed with the source parquet.
--
-- The clipboard itself is fine: on the same 427331-byte file, `"+p` and
-- `:r !pbpaste` round-trip byte-for-byte, because they read the pasteboard
-- directly instead of the wire. So the clipboard is the authority, and the
-- wire is the thing to distrust.
--
-- Method (streamed pastes only — phase 1..3; phase -1 is the nvim_paste API
-- path, which never crossed a pty and is left alone):
--
--   1. At phase 1, if the clipboard holds >= `threshold` bytes and the first
--      chunk is a byte-prefix of it, engage: swallow the stream and
--      reconstruct it chunk by chunk (chunks split mid-line; the first line
--      of each chunk continues the last line of the previous one).
--   2. At phase 3, compare the reconstruction against the clipboard:
--        identical            -> insert it, silently. Zero behavior change.
--        differs, >= threshold -> the wire corrupted a large paste. Insert
--                                the clipboard copy and say so (sizes +
--                                first-divergence offset).
--        differs, <  threshold -> an intentional smaller paste that merely
--                                opens like the clipboard (e.g. a prefix
--                                selection from a tmux buffer). Keep it.
--   3. Any paste whose first chunk does not prefix-match streams through
--      untouched, so non-clipboard sources are never substituted.
--
-- Escape hatch: `:lua vim.g.holmes_safe_paste = false` for the session.
-- `:Paste` inserts the clipboard via pbpaste directly, bypassing the wire.

local M = {}

-- Below this the wire has never been observed to fail, and a deviating paste
-- is more plausibly an intentional prefix selection than corruption.
M.threshold = 16 * 1024

-- Don't bother forking pbpaste for a first chunk this small.
local MIN_FIRST_CHUNK = 64

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

-- Is this chunk (a line array whose last element may be a partial line — pty
-- chunks split anywhere, including mid-line) a prefix of the clipboard?
local function chunk_is_clip_prefix(clip_lines, chunk)
  if #chunk == 0 or #chunk > #clip_lines then
    return false
  end
  for i = 1, #chunk - 1 do
    if clip_lines[i] ~= chunk[i] then
      return false
    end
  end
  local last, ref = chunk[#chunk], clip_lines[#chunk]
  if #chunk == #clip_lines then
    return last == ref
  end
  return ref:sub(1, #last) == last
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
  local state = nil ---@type {clip_raw: string, clip_lines: string[], got: string[]}?

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.paste = function(lines, phase)
    -- phase -1: whole paste in one call — the nvim_paste API path. It never
    -- went through the pty, so there is nothing to verify.
    if phase == -1 then
      state = nil
      return stream_paste(lines, phase)
    end

    if phase == 1 then
      state = nil
      if vim.g.holmes_safe_paste
          -- cmdline-mode pastes have their own line-joining semantics; leave
          -- them to the default implementation.
          and vim.api.nvim_get_mode().mode:sub(1, 1) ~= "c"
          and #table.concat(lines, "\n") >= MIN_FIRST_CHUNK
      then
        local clip_raw = read_clipboard()
        if clip_raw and #clip_raw >= M.threshold then
          local clip_lines = vim.split(clip_raw, "\n", { plain = true })
          if chunk_is_clip_prefix(clip_lines, lines) then
            local got = {}
            for i, l in ipairs(lines) do
              got[i] = l
            end
            state = { clip_raw = clip_raw, clip_lines = clip_lines, got = got }
          end
        end
      end
      if not state then
        return stream_paste(lines, phase)
      end
      return true -- engaged: swallow; everything is inserted at phase 3
    end

    if not state then
      return stream_paste(lines, phase)
    end

    absorb(state.got, lines)
    if phase == 2 then
      return true
    end

    -- phase 3: stream complete. Verify, insert exactly once.
    local st = state
    state = nil
    local got_str = table.concat(st.got, "\n")
    if got_str == st.clip_raw then
      -- The wire delivered faithfully; insert what arrived. Silent.
      return stream_paste(st.got, -1)
    end
    if #got_str < M.threshold then
      -- Deviates but small: an intentional paste from another source that
      -- happens to open like the clipboard. Keep the streamed content.
      return stream_paste(st.got, -1)
    end
    local at = first_diff(got_str, st.clip_raw)
    local ok = stream_paste(st.clip_lines, -1)
    vim.schedule(function()
      vim.notify(
        ("Terminal paste stream was corrupt: %d bytes arrived, clipboard has %d "
          .. "(first difference at byte %d). Inserted the clipboard copy instead.")
        :format(#got_str, #st.clip_raw, at or 0),
        vim.log.levels.WARN
      )
    end)
    return ok
  end

  -- Explicit, always-safe paste: reads the pasteboard, never the wire.
  vim.api.nvim_create_user_command("Paste", function()
    local raw = read_clipboard()
    if not raw then
      vim.notify("pbpaste returned nothing", vim.log.levels.WARN)
      return
    end
    vim.api.nvim_put(vim.split(raw, "\n", { plain = true }), "c", true, true)
  end, { desc = "Paste the system clipboard via pbpaste (bypasses the terminal stream)" })
end

return M
