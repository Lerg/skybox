local _M = {}

local app = require('lib.app')

function _M:loadAudio()
    local stream = audio.loadStream('music/fire.mp3')
    local c = audio.play(stream, {loops = -1})
    audio.setVolume(0, {channel = c})
    audio.fade{channel = c, time = 3000, volume = 0.4}
end

return _M