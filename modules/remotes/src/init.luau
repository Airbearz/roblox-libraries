local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Janitor = require(script.Parent.Janitor)
local Promise = require(script.Parent.Promise)
local WaitFor = require(script.Parent.WaitFor)

--[=[
Wrapper for RemoteEvents and RemoteFunctions

@class Remotes
]=]

local Remotes = {}
Remotes.__index = Remotes

export type Remotes = typeof(setmetatable(
	{} :: {
		_janitor: any,
		_parent: Instance,
		_group: string,
	},
	Remotes
))

local function getRemoteEventName(name: string)
	return `{name}_REMOTEEVENT`
end

local function getFolderName(name: string)
	return `{name}_REMOTESFOLDER`
end

local function getRemoteFunctionName(name: string)
	return `{name}_REMOTEFUNCTION`
end

--[=[
	@return Remotes
	Construct a new Remotes instance.
	If `parent` is not specified, it will default to `ReplicatedStorage`.
]=]
function Remotes.new(group: string, parent: Instance?): Remotes
	local self = setmetatable({}, Remotes)

	self._janitor = Janitor.new()
	self._parent = parent or ReplicatedStorage
	self._group = group

	return self
end

--[=[
	On the client this returns a RemoteEvent if there is one

	On the server, this checks if a RemoteEvent already exists and returns it if it does. If it does not it will create it first then return it.
]=]

function Remotes.remoteEvent(self: Remotes, name: string): RemoteEvent?
	if RunService:IsClient() then
		local remoteEvent = self._parent:FindFirstChild(getRemoteEventName(name)) :: RemoteEvent?
		return remoteEvent
	else
		local groupFolder = self._parent:FindFirstChild(getFolderName(self._group))
		if not groupFolder then
			groupFolder = Instance.new("Folder")
			groupFolder.Name = getFolderName(self._group)
			groupFolder.Parent = self._parent
			self._janitor:Add(groupFolder)
		end

		local remoteEventName = getRemoteEventName(name)
		if groupFolder:FindFirstChild(remoteEventName) then
			return groupFolder:FindFirstChild(remoteEventName) :: RemoteEvent
		end

		local remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = remoteEventName
		remoteEvent.Parent = groupFolder
		self._janitor:Add(remoteEvent)

		return remoteEvent
	end
end

--[=[
	On the client this returns a RemoteFunction if there is one

	On the server, this checks if a RemoteFunction already exists and returns it if it does. If it does not it will create it first then return it.
]=]

function Remotes.remoteFunction(self: Remotes, name: string): RemoteFunction?
	if RunService:IsClient() then
		local remoteFunction = self._parent:FindFirstChild(getRemoteFunctionName(name)) :: RemoteFunction?
		return remoteFunction
	else
		local groupFolder = self._parent:FindFirstChild(getFolderName(self._group))
		if not groupFolder then
			groupFolder = Instance.new("Folder")
			groupFolder.Name = getFolderName(self._group)
			groupFolder.Parent = self._parent
			self._janitor:Add(groupFolder)
		end

		local remoteFunctionName = getRemoteFunctionName(name)
		if groupFolder:FindFirstChild(remoteFunctionName) then
			return groupFolder:FindFirstChild(remoteFunctionName) :: RemoteFunction
		end

		local remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = remoteFunctionName
		remoteFunction.Parent = groupFolder
		self._janitor:Add(remoteFunction)

		return remoteFunction
	end
end

--[=[
	@return Promise<RemoteEvent>

	Waits for the RemoteEvent to exist. Will timeout after `timeout`.
	This will NOT create a RemoteEvent if it doesn't already exist.

	```lua
	local remotes = Remotes.new("REMOTES")
	remotes:promiseRemoteEvent("RemoteEvent", 5):andThen(function(remoteEvent)
		remoteEvent:FireServer("Hello, Server!")
	end)
	```
]=]

function Remotes.promiseRemoteEvent(self: Remotes, name: string, timeout: number?)
	local overrideTimeout: number = timeout or 5

	return Promise.new(function(resolve, _, _)
		local remoteEventName = getRemoteEventName(name)
		local folderName = getFolderName(self._group)

		local folder = self._parent:FindFirstChild(folderName)
		if folder and folder:FindFirstChild(remoteEventName) then
			resolve(folder:FindFirstChild(remoteEventName) :: RemoteEvent)
		end

		if folder then
			resolve(WaitFor.Child(folder, remoteEventName))
		else
			resolve(WaitFor.Child(self._parent, folderName):andThen(function(addedFolder: Folder)
				return WaitFor.Child(addedFolder, remoteEventName)
			end))
		end
	end):timeout(overrideTimeout)
end

--[=[
	@return Promise<RemoteFunction>

	Waits for the RemoteFunction to exist. Will timeout after `timeout`.
	This will NOT create a RemoteFunction if it doesn't already exist.

	```lua
	local remotes = Remotes.new("REMOTES")
	remotes:promiseRemoteFunction("RemoteFunction", 5):andThen(function(remoteFunction)
		local data = remoteFunction:InvokeServer()
		print(data)
	end)
	```
]=]

function Remotes.promiseRemoteFunction(self: Remotes, name: string, timeout: number?)
	local overrideTimeout: number = timeout or 5

	return Promise.new(function(resolve, _, _)
		local remoteFunctionName = getRemoteFunctionName(name)
		local folderName = getFolderName(self._group)

		local folder = self._parent:FindFirstChild(folderName)
		if folder and folder:FindFirstChild(remoteFunctionName) then
			resolve(folder:FindFirstChild(remoteFunctionName) :: RemoteFunction)
		end

		if folder then
			resolve(WaitFor.Child(folder, remoteFunctionName))
		else
			resolve(WaitFor.Child(self._parent, folderName):andThen(function(addedFolder: Folder)
				return WaitFor.Child(addedFolder, remoteFunctionName)
			end))
		end
	end):timeout(overrideTimeout)
end

function Remotes:Destroy()
	self._janitor:Destroy()
end

return Remotes
