require 'stdlib/event/event'

test_function = {f=function(x) someVariable = x end}
local function_a = function(arg) test_function.f(arg.tick) end
local function_b = function(arg) test_function.f(arg.player_index) end
local function_c = function() return true end

describe('Event', function()
    before_each(function()
        _G.someVariable = false
        _G.script = {on_event = function(id, callback) return end}
    end)

    after_each(function()
        Event._registry = {}
    end)

    it('.register should add multiple callbacks for the same event', function()
        Event.register( 0, function_a )
        Event.register( 0, function_b )
        assert.equals( function_a, Event._registry[0][1] )
        assert.equals( function_b, Event._registry[0][2] )
    end)

    it('.register should hook the event to script.on_event', function()
        local s = spy.on(script, "on_event")
        Event.register( 0, function_a )
        assert.spy(s).was_called_with(0, Event.dispatch)
    end)

    it('.register should return itself', function()
        assert.equals( Event, Event.register( 0, function_a ) )
        assert.equals( Event, Event.register( 0, function_b ).register( 0, function_c ) )

        assert.equals( function_a, Event._registry[0][1] )
        assert.equals( function_b, Event._registry[0][2] )
        assert.equals( function_c, Event._registry[0][3] )
    end)

    it('.dispatch should cascade through registered handlers', function()
        Event.register( 0, function_a )
        Event.register( 0, function_b )
        local event = {name = 0, tick = 9001, player_index = 1}
        local s = spy.on(test_function, "f")
        Event.dispatch(event)
        assert.spy(s).was_called_with(9001)
        assert.spy(s).was_called_with(1)
        assert.equals(1, someVariable)
    end)

    it('.dispatch should abort if a handler returns true', function()
        Event.register( 0, function_a )
        Event.register( 0, function_c )
        Event.register( 0, function_b )
        local event = {name = 0, tick = 9001, player_index = 1}
        local s = spy.on(test_function, "f")
        Event.dispatch(event)
        assert.spy(s).was_called_with(9001)
        assert.spy(s).was_not_called_with(1)
        assert.equals(9001, someVariable)
    end)
end)