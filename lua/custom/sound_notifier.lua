---@class SoundNotifier
---@field augroup number Identifier of autocmd group used by notifier
---@field _is_focused boolean
---@field _is_active boolean
---@field _last_finished number
---@field _delay_ms number
---@field _sound_path string
---@field _play_sound function
local M = {}

local notifier_count = 0

---Creates new sound notifier
---@param sound_path string Path to sound file (default: vim.g.llm_message_sound)
---@param delay_ms? number Delay in milliseconds before playing sound (default: 3000)
---@return SoundNotifier
function M.new(sound_path, delay_ms)
    local self = setmetatable({}, { __index = M })
    self._is_focused = true
    self._is_active = false
    self._last_finished = 0
    self._delay_ms = delay_ms or 3000
    self._sound_path = sound_path

    notifier_count = notifier_count + 1
    self.augroup =
        vim.api.nvim_create_augroup('user.sound_notifier_' .. notifier_count, { clear = true })

    vim.api.nvim_create_autocmd('FocusGained', {
        group = self.augroup,
        callback = function()
            self._is_focused = true
        end,
    })
    vim.api.nvim_create_autocmd('FocusLost', {
        group = self.augroup,
        callback = function()
            self._is_focused = false
        end,
    })

    self._play_sound = function()
        local cmd = { 'play', '-q', self._sound_path }
        vim.fn.jobstart(cmd, { detach = true })
    end

    return self
end

---Mark task as started, preventing notifications until task_finished is called
function M:task_started()
    self._is_active = true
end

---Mark task as finished, schedules notification if window is not focused
function M:task_finished()
    self._is_active = false
    self._last_finished = vim.uv.now()

    vim.defer_fn(function()
        local elapsed = vim.uv.now() - self._last_finished
        if not self._is_focused and not self._is_active and elapsed >= self._delay_ms then
            self:_play_sound()
        end
    end, self._delay_ms)
end

---Returns callback function that marks task as started
---@return function
function M:task_started_callback()
    return function()
        self:task_started()
    end
end

---Returns callback function that marks task as finished
---@return function
function M:task_finished_callback()
    return function()
        self:task_finished()
    end
end

return M
