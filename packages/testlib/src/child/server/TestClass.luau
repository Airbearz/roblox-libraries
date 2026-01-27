--[=[
    Test class

    ```lua
    local myTestClass = TestClass.new(1, 2)
    print(myTestClass:sum()) -- 3
    ```

    @class TestClass
]=]

local TestClass = {}
TestClass.__index = TestClass

export type TestClass = typeof(setmetatable(
	{} :: {
		_a: number,
		_b: number,
	},
	TestClass
))

--[=[
	Constructs a new TestClass object.

	@param a number -- First number
	@param b number -- Second number
	@return TestClass
]=]

function TestClass.new(a: number, b: number): TestClass
	local self = setmetatable({}, TestClass)

	self._a = a
	self._b = a

	return self
end

--[=[
	Sums the two numbers

	@return number
]=]

function TestClass.sum(self: TestClass)
	return self._a + self._b
end

function TestClass:Destroy()
	self._janitor:Destroy()
end

return TestClass
