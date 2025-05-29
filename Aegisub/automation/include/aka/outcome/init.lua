--- Outcome: Functional and composable option and result types for Lua.
--
--    local outcome = require "outcome"
--
-- @module outcome
local outcome = {
  _VERSION = "0.2.2",
  _DESCRIPTION = 'Functional and composable option and result types for Lua.',
  _URL = 'https://github.com/mtdowling/outcome',
  _LICENSE = [[
    MIT LICENSE
    Copyright (c) 2017 Michael Dowling

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
  ]]
}

local versioning = {}

versioning.name = "aka.outcome"
versioning.description = "Module aka.outcome"
versioning.version = "1.0.11"
versioning.author = "Michael Dowling, modified by Akatsumekusa"
versioning.namespace = "aka.outcome"

local version = require("l0.DependencyControl")({
  name = versioning.name,
  description = versioning.description,
  version = versioning.version,
  author = versioning.author,
  moduleName = versioning.namespace,
  url = "https://github.com/Akatmks/Akatsumekusa-Aegisub-Scripts",
  feed = "https://raw.githubusercontent.com/Akatmks/Akatsumekusa-Aegisub-Scripts/master/DependencyControl.json",
})

local type, error, pcall, xpcall, string = type, error, pcall, xpcall, string
local setmetatable, getmetatable = setmetatable, getmetatable

local OK, ERR = true, false
local OPTION_CLASS, RESULT_CLASS = "outcome.Option", "outcome.Result"

local function assertOption(value)
  if type(value) ~= "table" or value.class ~= OPTION_CLASS then
    error("[aka.outcome] Value must be an `Option<T>`. Found " .. value)
  end
  return value
end

-- Option
------------------------------------------------------------------------------

--- Option type.
--
-- The Option class is used as a functional replacement for null. Using Option
-- provides a composable mechanism for working with values that may or may not
-- be present. This Option implementation is heavily inspired by the Option
-- type in Rust, and somewhat by the Optional type in Java.
--
-- **Examples**
--
--    local outcome = require "outcome"
--
--    -- Options are either Some or None.
--    assert(outcome.none():isNone())
--    assert(outcome.some("foo"):isSome())
--
--    -- You can map over the value in an Option.
--    local result = outcome.some(1)
--        :map(function(value) return value + 1 end)
--        :unwrap()
--    assert(result == 2)
--
--    -- Raises an error with the message provided in expect.
--    outcome.none():expect("Expected a value"):
--
--    -- You can provide a default value when unwrapping an Option.
--    assert("foo" == outcome.none():unwrapOr("foo"))
--
-- @type Option
local Option = {} -- luacheck: ignore

--- Returns true if the option contains a value.
-- @treturn bool
function Option:isSome() end

--- Returns true if the option value is nil.
-- @treturn bool
function Option:isNone() end

--- Invokes a method with the value if Some. The return value of the
-- function is ignored.
--
--    local opt = outcome.some("abc")
--    opt:ifSome(function(value) print(value) end)
--
-- @tparam function consumer Consumer to invoke with a side effect.
-- @treturn Option Returns self.
function Option:ifSome(consumer) end

--- Invokes a method if the option value is None. The return value of the
-- function is ignored.
--
--    local opt = outcome.none()
--    opt:ifNone(function(value) print("It's None!") end)
--
-- @tparam function consumer Method to invoke if the value is None.
-- @treturn Option Returns self.
function Option:ifNone(consumer) end

--- Returns the value if Some, or throws an error.
-- @return T the wrapped option.
function Option:unwrap() end

--- Unwraps and returns the value if Some, or returns default value.
--
--    local opt = outcome.none()
--    assert("foo", opt:unwrapOr("foo"))
--
-- @param defaultValue Default value T to return.
-- @return T returns the wrapped value or the default.
function Option:unwrapOr(defaultValue) end

--- Unwraps and returns the value if Some, or returns the result of invoking
-- a function that when called returns a value.
--
--    local opt = outcome.none()
--    assert("foo", opt:unwrapOrElse(function() return "foo" end))
--
-- @tparam function valueProvider to invoke if the value is None.
-- @return T returns the wrapped value or the value returned from valueProvider.
function Option:unwrapOrElse(valueProvider) end

--- Unwraps and returns the value if Some, or raises a specific error.
--
--    local option = outcome.some("foo")
--    local value = option:expect("Error message")
--
-- @tparam string message Message to raise.
-- @return T returns the wrapped value.
function Option:expect(message) end

--- Returns `other` if the option value is Some, otherwise returns self.
--
--    local optA = outcome.some("abc")
--    local optB = outcome.some("123")
--    assert(optB = optA:andOther(optB))
--
-- @tparam Option other Alternative `Option<T>` to return.
-- @treturn Option Returns `Option<T>`
function Option:andOther(other) end

--- Returns the result of f if the option value is Some, otherwise return self.
--
--    local optA = outcome.some("abc")
--    local optB = optA:orElseOther(function()
--      return outcome.some("123")
--    end)
--    assert(optB:unwrap() == "123")
--
-- @tparam function f Function that returns an `Option<T>`.
-- @treturn Option Returns `Option<T>`
function Option:andThen(f) end

--- Returns self if a value is Some, otherwise returns `other`.
--
--    local optA = outcome.none()
--    local optB = outcome.some("123")
--    assert(optB = optA:orOther(optB))
--
-- @tparam Option other Alternative `Option<T>` to return.
-- @treturn Option Returns `Option<T>`
function Option:orOther(other) end

--- Returns self if a value is Some, otherwise returns the result of f.
--
--    local optA = outcome.none()
--    local optB = optA:orElseOther(function()
--      return outcome.some("123")
--    end)
--    assert(optB:unwrap() == "123")
--
-- @tparam function f Function that returns an `Option<T>`.
-- @treturn Option Returns `Option<T>`
function Option:orElseOther(f) end

--- Maps an `Option<T>` to `Option<U>` by applying a function to the contained
-- value.
--
--    local value outcome.some(1)
--        :map(function(value) return value + 1 end)
--        :unwrap()
--
--    assert(value == 2)
--
-- @tparam function f Function that accepts T and returns U.
-- @treturn Option Returns `Option<U>`
function Option:map(f) end

--- Applies a function to the contained value (if any), or returns a default.
--
--    local value outcome.some("foo")
--        :mapOr("baz", function(value) return value .. " test" end)
--        :unwrap()
--
--    assert(value == "foo test")
--
--    value outcome.none()
--        :mapOr("baz", function(value) return value .. " test" end)
--        :unwrap()
--
--    assert(value == "baz")
--
-- @param defaultValue Value U to return if the option is None.
-- @tparam function f Function that accepts T and returns U.
-- @treturn Option Returns `Option<U>`
function Option:mapOr(defaultValue, f) end

--- Applies a function to the contained value (if any), or computes a default.
--
--    local mapFunction = function(value) return value .. "test" end)
--
--    local value outcome.some("foo")
--        :mapOr(function() return "baz" end), mapFunction)
--        :unwrap()
--
--    assert(value == "foo test")
--
--    value outcome.none()
--        :mapOr(function() return "baz" end), mapFunction)
--        :unwrap()
--
--    assert(value == "baz")
--
-- @tparam function defaultProvider Default function to invoke that returns U.
-- @tparam function mapFunction Function that accepts T and returns U.
-- @treturn Option Returns `Option<U>`
function Option:mapOrElse(defaultProvider, mapFunction) end

--- Returns an None option if the option value is not preset. Otherwise calls
-- f with the wrapped value and returns the result.
--
--    local value = outcome.some(1)
--        :flatmap(function(value) return outcome.some(value + 1) end)
--        :unwrap()
--
--    assert(value == 2)
--
-- @tparam function f Function that accepts T and returns `Option<U>`.
-- @treturn Option Returns `Option<U>`
function Option:flatmap(f) end

--- Filters a Some Option through `f` and if `f` returns false, creates a
-- None Option. None Option is returned as-is and not passed to `f`.
-- @tparam function f Filter function that receives a value and returns bool.
-- @treturn Option Returns `Option<T>`
function Option:filter(f) end

--- Transforms the `Option<T>` into a `Result<T, E>`, mapping a Some value to
-- an Ok Result, and an None value to Result err.
--
--    local res = outcome.some(1):okOr("error data if None")
--    assert(res:isOk())
--    assert(res:unwrap() == 1)
--
-- @tparam function err Error to use in the Result if the value is None.
-- @treturn Result Returns `Result<T, E>`
function Option:okOr(err) end

--- Transforms the `Option<T>` into a `Result<T, E>`, mapping a Some value
-- to an Ok Result, and an None value to Result err.
--
--    local res = outcome.some(1):okOrElse(function()
--      return "error data if None"
--    end)
--    assert(res:isOk())
--    assert(res:unwrap() == 1)
--
-- @tparam function errorProvider Function that returns E.
-- @treturn Result Returns `Result<T, E>`
function Option:okOrElse(errorProvider) end

-- Option None implementation
------------------------------------------------------------------------------

--- Represents a None Option.
--
-- We use two different implementations of Option for both None and Some in
-- order to remove branching from the various methods.
local None = {}

local NoneMetatable = {
  __index = None,
  __lt = function (_, _) return true end,
  __le = function (_, _) return true end,
}

function None:isSome()
  return false
end

function None:isNone()
  return true
end

function None:unwrap()
  return self:expect()
end

function None:expect(message)
  error(message or "[aka.outcome] Call to unwrap on a nil value")
end

function None:unwrapOr(defaultValue)
  return defaultValue
end

function None:unwrapOrElse(valueProvider)
  return valueProvider(self._value)
end

function None:ifSome(_)
  return self
end

function None:ifNone(consumer)
  consumer(self._value)
  return self
end

function None:andOther(_)
  return self
end

function None:andThen(_)
  return self
end

function None:orOther(other)
  return assertOption(other)
end

function None:orElseOther(f)
  return assertOption(f())
end

function None:map(_)
  return self
end

function None:flatmap(_)
  return self
end

function None:mapOr(defaultValue, _)
  return outcome.some(defaultValue)
end

function None:mapOrElse(defaultProvider, _)
  return outcome.some(defaultProvider(self._value))
end

function None:filter(_)
  return self
end

function None:okOr(err)
  return outcome.err(err)
end

function None:okOrElse(errorProvider)
  return outcome.err(errorProvider(self._value))
end

-- Option Some implementation
------------------------------------------------------------------------------

--- Represents a Some Option.
local Some = {}

local SomeMetatable = {
  __index = Some,
  __lt = function (lhs, rhs) return lhs._value < rhs._value end,
  __le = function (lhs, rhs) return lhs._value <= rhs._value end,
  __eq = function(a, b) return a._value == b._value end
}

function Some:isSome()
  return true
end

function Some:isNone()
  return false
end

function Some:unwrap()
  return self._value
end

function Some:expect(_)
  return self._value
end

function Some:unwrapOr(_)
  return self._value
end

function Some:unwrapOrElse(_)
  return self._value
end

function Some:ifSome(consumer)
  consumer(self._value)
  return self
end

function Some:ifNone(_)
  return self
end

function Some:andOther(other)
  return assertOption(other)
end

function Some:andThen(f)
  return assertOption(f(self._value))
end

function Some:orOther(_)
  return self
end

function Some:orElseOther(_)
  return self
end

function Some:map(f)
  return outcome.some(f(self._value))
end

function Some:mapOr(_, f)
  return outcome.some(f(self._value))
end

function Some:mapOrElse(_, mapFunction)
  return outcome.some(mapFunction(self._value))
end

function Some:flatmap(f)
  return assertOption(f(self._value))
end

function Some:filter(f)
  if f(self._value) then
    return self
  else
    return outcome._NONE_OPTION
  end
end

function Some:okOr(_)
  return outcome.ok(self._value)
end

function Some:okOrElse(_)
  return outcome.ok(self._value)
end

-- Result
------------------------------------------------------------------------------

--- `Result<T, E>` is a type used for returning and propagating errors.
--
-- There are two kinds of Result objects:
--
-- * Ok: the result contains a successful value.
-- * Err: The result contains an error value.
--
-- **Examples**
--
--    local outcome = require "outcome"
--    local Result = outcome.Result
--
--    -- Results are either Ok or Err.
--    assert(outcome.ok("ok value"):isOk())
--    assert(outcome.err("error value"):isErr())
--
--    -- You can map over the Ok value in a Result.
--    local result = outcome.ok(1)
--        :map(function(value) return value + 1 end)
--        :unwrap()
--
--    assert(result == 2)
--
--    -- Raises an error with the message provided in expect.
--    outcome.err("error value"):expect("Result was not Ok"):
--
--    -- You can provide a default value when unwrapping a Result.
--    assert("foo" == outcome.err("error value"):unwrapOr("foo"))
--
-- @type Result
local Result = {} -- luacheck: ignore

local function assertResult(value)
  if type(value) ~= "table" or value.class ~= RESULT_CLASS then
    error("[aka.outcome] Value must be a `Result<T, E>`. Found " .. type(value))
  end
  return value
end

local function errorToString(value)
  local valueType = type(value)
  if valueType == "string" then
    return "[aka.outcome] " .. value
  elseif valueType == "table" then
    local mt = getmetatable(value)
    return "[aka.outcome] " .. (mt and mt.__tostring and string(value) or "table error")
  elseif valueType == "nil" then
    return "[aka.outcome] nil error"
  elseif valueType == "boolean" then
    return "[aka.outcome] boolean error (" .. value .. ")"
  elseif valueType == "number" then
    return "[aka.outcome] number error (" .. value .. ")"
  else
    return "[aka.outcome] error of type " .. valueType
  end
end

local function resultLt(lhs, rhs)
  return lhs._kind == rhs._kind
      and lhs._value ~= nil and rhs._value ~= nil
      and lhs._value < rhs._value
end

local function resultLte(lhs, rhs)
  return lhs._kind == rhs._kind
      and lhs._value ~= nil and rhs._value ~= nil
      and lhs._value <= rhs._value
end

local function resultEq(lhs, rhs)
  return lhs._kind == rhs._kind and lhs._value == rhs._value
end

--- Returns true if the result is Ok.
-- @treturn bool
function Result:isOk() end

--- Returns true if the result is an error.
-- @treturn bool
function Result:isErr() end

--- Invokes a method with the value if the Result is Ok. The return value of
-- the function is ignored.
-- @tparam function consumer Consumer to invoke with a side effect.
-- @treturn Option Returns self.
function Result:ifOk(consumer) end

--- Invokes a method if the Result is an Err and passes the error to consumer.
-- The return value of the function is ignored.
-- @tparam function consumer Method to invoke if the value is error.
-- @treturn Option Returns self.
function Result:ifErr(consumer) end

--- Returns the value if Ok, or raises an error using the error value.
-- @return T the wrapped result value.
-- @raise Errors with if the result is Err.
function Result:unwrap() end

--- Unwraps a result, yielding the content of an Err.
-- @return E the error value.
-- @raise Errors if the value is Ok.
function Result:unwrapErr() end

--- Unwraps and returns the value if Ok, or returns default value.
-- @param defaultValue Default value T to return.
-- @return T returns the wrapped value or the default.
function Result:unwrapOr(defaultValue) end

--- Unwraps and returns the value if Ok, or returns the result of invoking
-- a method that when called returns a value.
-- @tparam function valueProvider Function to invoke if the value is an error.
-- @return T returns the Ok value or the value returned from valueProvider.
function Result:unwrapOrElse(valueProvider) end

--- Unwraps and returns the value if Ok, or errors with a message.
-- @tparam string message Message to include in the error.
-- @return T returns the wrapped value.
function Result:expect(message) end

--- Returns other if the result is Ok, otherwise returns the Err value of self.
-- @tparam Result other `Result<T, E>` other Alternative Result to return.
-- @treturn Result Returns `Result<T, E>`
function Result:andOther(other) end

--- Calls resultProvider if the result is Ok, otherwise returns self.
--
-- This function can be used for control flow based on result values.
--
--    local value = outcome.ok(1)
--        :orElseOther(function(v) return outcome.ok(2) end)
--        :unwrap()
--
--    assert(value == 2)
--
-- @tparam function resultProvider Function that returns `Result<T, E>`.
-- @treturn Result Returns `Result<T, E>`
function Result:andThen(resultProvider) end

--- Returns other if the result is Err, otherwise returns self.
--
--    local value = outcome.err("error!")
--        :orOther(outcome.ok(1))
--        :unwrap()
--
--    assert(value == 1)
--
--    value = outcome.ok(1)
--        :orOther(outcome.ok(999))
--        :unwrap()
--
--    assert(value == 1)
--
-- @tparam Result other `Result<T, E>` other Alternative Result to return.
-- @treturn Result Returns `Result<T, E>`
function Result:orOther(other) end

--- Calls resultProvider if the result is Err, otherwise returns self.
--
-- This function can be used for control flow based on result values.
--
--    local value = outcome.err("error!")
--        :orElseOther(function(v) return outcome.ok(1) end)
--        :unwrap()
--
--    assert(value == 1)
--
--    value = outcome.ok(1)
--        :orElseOther(function(v) return outcome.ok(999) end)
--        :unwrap()
--
--    assert(value == 1)
--
-- @tparam function resultProvider Function that returns `Result<T, E>`.
-- @treturn Result Returns `Result<T, E>`
function Result:orElseOther(resultProvider) end

--- Maps a `Result<T, E>` to `Result<U, E>` by applying a function to a
-- contained Ok value, leaving an Err value untouched.
--
-- This function can be used to compose the results of two functions.
--
--    local value = outcome.ok(1)
--        :map(function(v) return v + 1 end)
--        :unwrap()
--
--    assert(value == 2)
--
-- @tparam function f Function that accepts `T` and returns `U`.
-- @treturn Result Returns `Result<U, E>`
function Result:map(f) end

--- Maps a `Result<T, E>` to `Result<T, F>` by applying a function to a
-- contained Err value, leaving an Ok value untouched.
--
-- This function can be used to pass through a successful result while handling
-- an error.
--
--    local value = outcome.err(1)
--        :mapErr(function(v) return v + 1 end)
--        :unwrapErr()
--
--    assert(value == 2)
--
-- @tparam function f Function that accepts `E` and returns `U`.
-- @treturn Result Returns `Result<T, F>`
function Result:mapErr(f) end

--- Calls f if the result is Ok, otherwise returns the Err value of self.
--
-- This function can be used for control flow based on Result values.
--
--    local value = outcome.ok(1)
--        :flatmap(function(v) return outcome.ok(v + 1) end)
--        :unwrap()
--
--    assert(value == 2)
--
-- @tparam function f Function that accepts T and returns `Result<T. E>`.
-- @treturn Result Returns `Result<T, E>`
function Result:flatmap(f) end

--- Converts from `Result<T, E>` to `Option<T>`.
-- Converts self into an `Option<T>`, consuming self, and discarding the error,
-- if any.
-- @treturn Result Returns `Result<T, E>`
function Result:okOption() end

--- Converts from `Result<T, E>` to `Option<E>`.
-- Converts self into an `Option<E>`, consuming self, and discarding the
-- success value, if any.
-- @treturn Result Returns `Result<T, E>`
function Result:errOption() end

-- Result Ok implementation
------------------------------------------------------------------------------

--- Similarly to Some/None, we use two classes in order to remove branching
-- from the underlying Ok/Err Result implementations.
local Ok = {} -- luacheck: ignore

local OkMetatable = {
  __index = Ok,
  __lt = resultLt,
  __le = resultLte,
  __eq = resultEq,
}

function Ok:isOk()
  return true
end

function Ok:isErr()
  return false
end

function Ok:unwrap()
  return self._value
end

function Ok:unwrapErr()
  return self._value
end

function Ok:expect(_)
  return self._value
end

function Ok:unwrapOr(_)
  return self._value
end

function Ok:unwrapOrElse(_)
  return self._value
end

function Ok:ifOk(consumer)
  consumer(self._value)
  return self
end

function Ok:ifErr(_)
  return self
end

function Ok:okOption()
  return outcome.some(self._value)
end

function Ok:errOption()
  return outcome.none()
end

function Ok:andOther(other)
  return assertResult(other)
end

function Ok:andThen(resultProvider)
  return assertResult(resultProvider(self._value))
end

function Ok:orOther(_)
  return self
end

function Ok:orElseOther(_)
  return self
end

function Ok:map(f)
  return outcome.ok(f(self._value))
end

function Ok:mapErr(_)
  return self
end

function Ok:flatmap(f)
  return assertResult(f(self._value))
end

-- Result Err implementation
------------------------------------------------------------------------------

--- Err Result implementation.
local Err = {}

local ErrMetatable = {
  __index = Err,
  __lt = resultLt,
  __le = resultLte,
  __eq = resultEq,
}

function Err:isOk()
  return false
end

function Err:isErr()
  return true
end

function Err:unwrap()
  error(errorToString(self._value))
end

function Err:unwrapErr()
  return self._value
end

function Err:expect(message)
  error(message)
end

function Err:unwrapOr(defaultValue)
  return defaultValue
end

function Err:unwrapOrElse(valueProvider)
  return valueProvider(self._value)
end

function Err:ifOk(_)
  return self
end

function Err:ifErr(consumer)
  consumer(self._value)
  return self
end

function Err:okOption()
  return outcome.none()
end

function Err:errOption()
  return outcome.some(self._value)
end

function Err:andOther(_)
  return self
end

function Err:andThen(_)
  return self
end

function Err:orOther(other)
  return assertResult(other)
end

function Err:orElseOther(resultProvider)
  return assertResult(resultProvider(self._value))
end

function Err:map(_)
  return self
end

function Err:mapErr(f)
  return outcome.err(f(self._value))
end

function Err:flatmap(_)
  return self
end

outcome._NONE_OPTION = setmetatable({class = OPTION_CLASS}, NoneMetatable)

-- Public functions
------------------------------------------------------------------------------

--- Returns either a None or Some Option based on if the value == nil.
--
--    local opt = outcome.option(nil)
--    assert(opt:isNone())
--
--    local opt = outcome.option("foo")
--    assert(opt:isSome())
--
-- @treturn Option Returns `Option<T>`
-- @within Option functions
function outcome.option(value)
  if value == nil then
    return outcome._NONE_OPTION
  else
    return outcome.some(value)
  end
end

--- Create a new Option, wrapping a value.
-- If the provided value is nil, then the Option is considered None.
--
--    local opt = outcome.some("abc")
--    assert(opt:isSome())
--    assert("abc" == opt:unwrap())
--
-- @param value Value T to wrap.
-- @treturn Option `Option<T>`
-- @within Option functions
function outcome.some(value)
  if value == nil then error("[aka.outcome] A Some Option value may not be nil") end
  return setmetatable({_value = value, class = OPTION_CLASS}, SomeMetatable)
end

--- Returns a None Option.
--
--    local opt = outcome.none()
--    assert(opt:isNone())
--
-- @treturn Option Returns `Option<T>`
-- @within Option functions
function outcome.none()
  return outcome._NONE_OPTION
end

--- Create a new Ok Result.
--
--    local res = outcome.ok("foo")
--    assert(res:isOk())
--    assert(res:unwrap() == "foo")
--
-- @tparam T value Ok value to wrap.
-- @treturn Result Returns `Result<T, E>`
-- @within Result functions
function outcome.ok(value)
  return setmetatable({
    _value = value,
    _kind = OK,
    class = RESULT_CLASS,
  }, OkMetatable)
end

--- Create a new Err Result.
--
--    local res = outcome.err("error message")
--    assert(res:isErr())
--    assert(res:unwrapErr() == "message")
--
--    -- Err values can be of any type.
--    local resWithComplexErr = outcome.err({foo = true})
--    assert(resWithComplexErr:isErr())
--    assert(resWithComplexErr:unwrapErr().foo == true)
--
-- @tparam T value Error value to wrap.
-- @treturn Result Returns `Result<T, E>`
-- @within Result functions
function outcome.err(value)
  return setmetatable({
    _value = value,
    _kind = ERR,
    class = RESULT_CLASS,
  }, ErrMetatable)
end

--- Invokes a function and returns a `Result<T, E>`.
-- If the function errors, an Err Result is returned.
--
--    local res = Result.pcall(error, "oh no!")
--    assert(res:isErr())
--    assert(res:unwrapErr() == "oh no!")
--
-- @tparam function f Function to invoke that returns T or raises E.
-- @tparam ... Arguments to pass to the function.
-- @treturn Result Returns `Result<T, E>`
-- @within Result functions
function outcome.pcall(f, ...)
  local ok, result = pcall(f, ...)
  if ok then
    return outcome.ok(result)
  else
    return outcome.err(result)
  end
end

--- Invokes a function and returns a `Result<T, E>`.
-- If the function errors, an Err Result is returned.
--
--    local res = Result.pcall(error, "oh no!")
--    assert(res:isErr())
--    assert(res:unwrapErr() == "oh no!")
--
-- @tparam function f Function to invoke that returns T or raises E.
-- @tparam ... Arguments to pass to the function.
-- @treturn Result Returns `Result<T, E>`
-- @within Result functions
function outcome.xpcall(f, err, ...)
  local ok, result = xpcall(f, err, ...)
  if ok then
    return outcome.ok(result)
  else
    return outcome.err(result)
  end
end

--- Invokes a function and returns a `Result<T, E>`.
-- Compared to outcome.pcall, outcome.multi_pcall is able to receive
-- multiple returns from function and pack returns into a table.
-- If the function errors, an Err Result is returned.
--
--    local res = Result.multi_pcall(error, "oh no!")
--    assert(res:isErr())
--    assert(res:unwrapErr() == "oh no!")
--
-- @tparam function f Function to invoke that returns T or raises E.
-- @tparam ... Arguments to pass to the function.
-- @treturn Result Returns `Result<T, E>`
-- @within Result functions
function outcome.multi_pcall(f, ...)
  local result = table.pack(pcall(f, ...))
  if result[1] == true then
    table.remove(result, 1)
    return outcome.ok(result)
  else
    return outcome.err(result[2])
  end
end

--- Invokes a function and returns a `Result<T, E>`.
-- Compared to outcome.xpcall, outcome.multi_xpcall is able to receive
-- multiple returns from function and pack returns into a table.
-- If the function errors, an Err Result is returned.
--
--    local res = Result.multi_pcall(error, "oh no!")
--    assert(res:isErr())
--    assert(res:unwrapErr() == "oh no!")
--
-- @tparam function f Function to invoke that returns T or raises E.
-- @tparam ... Arguments to pass to the function.
-- @treturn Result Returns `Result<T, E>`
-- @within Result functions
function outcome.multi_xpcall(f, err, ...)
  local result = table.pack(xpcall(f, err, ...))
  if result[1] == true then
    table.remove(result, 1)
    return outcome.ok(result)
  else
    return outcome.err(result[2])
  end
end

--- Pack returns from a function into a `Result<T, E>`.
-- Some Lua functions return a the result when success, and return nil
-- or false with an error message on error. outcome.o packs such
-- returns into a `Result<T, E>`.
--
--    local res = Result.o(io.open("/invalid/path"))
--    assert(res:isErr())
--
--    local res = Result.o(io.open("/valid/path")):unwrap()
--    assert(type(res) == "userdata")
--
-- @tparam returns from functions
-- @treturn Result Returns `Result<T, E>`
-- @within Result functions
function outcome.o(...)
  local result

  result = table.pack(...)
  if result[1] == true and #result == 1 then
    return outcome.ok(result[1])
  elseif result[1] == true and #result == 2 then
    return outcome.ok(result[2])
  elseif result[1] == true then
    table.remove(result, 1)
    return outcome.ok(result)
  elseif (result[1] == false or result[1] == nil) and #result == 1 then
    return outcome.err("[aka.outcome] Error message not provided")
  elseif (result[1] == false or result[1] == nil) and (#result == 2 or type(result[2]) == "string") then
    return outcome.err(result[2])
  elseif (result[1] == false or result[1] == nil) then
    table.remove(result, 1)
    return outcome.err(result)
  elseif #result == 1 then
    return outcome.ok(result[1])
  else
    return outcome.ok(result)
  end
end

outcome.version = version
outcome.versioning = versioning

return version:register(outcome)
