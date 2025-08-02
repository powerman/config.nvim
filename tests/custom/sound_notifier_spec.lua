local notify = require 'custom.sound_notifier'

describe('SoundNotifier', function()
    local notifier
    local play_called = false

    before_each(function()
        notifier = notify.new('test.wav', 100)
        play_called = false
        notifier._play_sound = function()
            play_called = true
        end
    end)

    it('should not play sound when focused', function()
        assert.is_true(notifier._is_focused)
        notifier:task_started()
        notifier:task_finished()

        vim.wait(150, function()
            return false
        end)
        assert.is_false(play_called)
    end)

    it('should play sound when not focused', function()
        notifier._is_focused = false
        notifier:task_started()
        notifier:task_finished()

        vim.wait(150, function()
            return false
        end)
        assert.is_true(play_called)
    end)

    it('should not play sound if new task started before delay', function()
        notifier._is_focused = false
        notifier:task_started()
        notifier:task_finished()

        notifier:task_started()

        vim.wait(150, function()
            return false
        end)
        assert.is_false(play_called)
    end)

    it('should play sound immediately when not focused', function()
        notifier._is_focused = false
        notifier:notify()
        assert.is_true(play_called)
    end)

    it('should not play sound immediately when focused', function()
        assert.is_true(notifier._is_focused)
        notifier:notify()
        assert.is_false(play_called)
    end)

    it('should have callback for immediate notification', function()
        notifier._is_focused = false
        local callback = notifier:notify_callback()
        callback()
        assert.is_true(play_called)
    end)
end)
