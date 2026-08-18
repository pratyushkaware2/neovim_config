-- Cmd+V is retired. The terminal wire (Ghostty -> tmux -> pty -> nvim)
-- streams a paste as ~1 KB chunks with no integrity guarantee, and large
-- pastes arrived corrupted often enough that it can't be trusted. The
-- clipboard read directly via pbpaste is byte-exact every time.
--
-- So streamed pastes into buffers are a NO-OP: the stream is swallowed and
-- discarded, with a reminder to use <leader>v or :Paste (both read pbpaste
-- directly). Cmdline-mode pastes (e.g. into `:` or `/`) still work — they
-- are tiny and never corrupted.
--
-- Escape hatch: `:lua vim.g.holmes_safe_paste = false` restores default
-- streamed pasting for the session.

local M = {}

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
  local swallowing = nil ---@type {bytes: integer}?

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.paste = function(lines, phase)
    -- phase -1: whole paste in one call — the nvim_paste API path. It never
    -- went through the pty; leave it alone.
    if phase == -1 then
      swallowing = nil
      return stream_paste(lines, phase)
    end

    if phase == 1 then
      swallowing = nil
      if not vim.g.holmes_safe_paste
          or vim.api.nvim_get_mode().mode:sub(1, 1) == "c"
      then
        return stream_paste(lines, phase)
      end
      swallowing = { bytes = 0 }
    elseif not swallowing then
      return stream_paste(lines, phase)
    end

    for _, l in ipairs(lines) do
      swallowing.bytes = swallowing.bytes + #l + 1
    end

    if phase == 3 then
      local bytes = math.max(swallowing.bytes - 1, 0)
      swallowing = nil
      vim.schedule(function()
        vim.notify(
          ("Ignored a %d-byte terminal paste — Cmd+V is disabled. "
            .. "Use <leader>v or :Paste."):format(bytes),
          vim.log.levels.WARN
        )
      end)
    end
    return true -- swallow
  end

  -- Explicit, always-safe paste: reads the pasteboard, never the wire.
  vim.api.nvim_create_user_command("Paste", function()
    M.paste_clipboard()
  end, { desc = "Paste the system clipboard via pbpaste (bypasses the terminal stream)" })
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
