local TestService = {}

export type TestService = typeof(TestService)

function TestService.Init()
	print("This is a test")
end

function TestService.Start() end

return TestService
