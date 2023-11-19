--// Variables
local class = {}
local empty = {}
local void = (function(...) return end)

local exceptions = {
    MODIFIED_READ_ONLY = "Unable to assign property %s. Property is read only.";
}

local coreConstructorProperties = {
    __properties = true;
    __getters = true;
    __setters = true;
    __createdScript = true;
    __index = true;
    __newindex = true;
}

--// Types
export type createArguments = {
    className: string?;
    properties: {[string]: property};
    methods: {[string]: (self: {[any]: any}, ...any) -> ...any}?;
    getters: {[string]: (self: {[any]: any}, value: any) -> any}?;
    setters: {[string]: (self: {[any]: any}, newValue: any) -> any}?;
    metamethods: {[string]: any}?;
    makeAsUserdata: boolean?;
}

export type property = {
    value: any;
    isReadOnly: boolean?;
}

type constructor = {
    new: () -> object;
}

type object = {
    Destroy: (self: object) -> ();
    Changed: RBXScriptSignal;
    GetPropertyChangedSignal: (self: object, property: string) -> RBXScriptSignal;
    [any]: any;
}

--// Functions
local function createSignal(object, property: string)
    local metatable = getmetatable(object)

    if not metatable.__propertyEvents[property] then
        metatable.__propertyEvents[property] = Instance.new("BindableEvent")
    end

    return metatable.__propertyEvents[property].Event
end

local function __index(object, key)
    local metatable = getmetatable(object)
    local constructor = metatable.__constructor
    local valueToReturn = rawget(metatable.__self, key)
    local isMethod = false
    
    if not valueToReturn then
        valueToReturn = (rawget(constructor.__properties, key) or empty).value
    end

    if not valueToReturn and not rawget(coreConstructorProperties, key) and rawget(constructor, key) and typeof(rawget(constructor, key)) == "function" then
        isMethod = true
        valueToReturn = rawget(constructor, key)
    end

    if not isMethod and not getfenv(2).__rawReturn and valueToReturn and rawget(constructor.__getters, key) then
        local getter = rawget(constructor.__getters, key)
        local env = setmetatable({__rawReturn = true}, {__index = getfenv(getter)})

        valueToReturn = setfenv(getter, env)(object, valueToReturn)
    end

    if not valueToReturn and constructor.__index then
        valueToReturn = constructor.__index(object, key)
    end

    if key == "className" then
        return metatable.__className
    end

    if key == "Destroy" then
        if typeof(object) ~= "userdata" then
            setmetatable(object, nil)
        end

        metatable.__modified:Destroy()

        for _, event in pairs(metatable.__propertyEvents) do
            event:Destroy()
        end

        table.clear(metatable.__propertyEvents)

        for Index, Value in pairs(metatable.__self) do
            rawset(metatable.__self, Index, nil)

            if typeof(Value) == "table" then
                setmetatable(Value, nil)
                table.clear(Value)
            end
        end

        table.clear(metatable)

        return void
    end

    if key == "Changed" then
        return metatable.__modified.Event
    end

    if key == "GetPropertyChangedSignal" then
        return createSignal
    end

    return valueToReturn
end

local function __newindex(object, key, newValue)
    local metatable = getmetatable(object)
    local constructor = metatable.__constructor
    local propertyInfo = rawget(constructor.__properties, key)

    if propertyInfo then
        if rawget(propertyInfo, "isReadOnly") and getfenv(2).script ~= constructor.__createdScript then
            return error(exceptions.MODIFIED_READ_ONLY:format(key), 3)
        end

        if rawget(constructor.__setters, key) then
            newValue = rawget(constructor.__setters, key)(object, newValue)
        end
    elseif key == "className" then
        return error(exceptions.MODIFIED_READ_ONLY:format(key), 3)
    end

    if constructor.__newindex then
        newValue = constructor.__newindex(object, key, newValue)
    end

    local oldValue = object[key] -- 이거는 메타테이블 일부로 호출 시킨거이빈다 :>

    rawset(metatable.__self, key, newValue)

    if newValue ~= oldValue then
        metatable.__modified:Fire(key, newValue, oldValue)

        if rawget(metatable.__propertyEvents, key) then
            rawget(metatable.__propertyEvents, key):Fire(newValue, oldValue)
        end
    end
end

function class.create(arguments: createArguments)
    local constructor = {}
    local arguments = table.clone(arguments)

    arguments.getters = arguments.getters or empty
    arguments.setters = arguments.setters or empty
    arguments.metamethods = arguments.metamethods or empty
    arguments.methods = arguments.methods or empty

    constructor.__properties = arguments.properties
    constructor.__getters = arguments.getters
    constructor.__setters = arguments.setters
    constructor.__createdScript = getfenv(2).script
    constructor.__index = arguments.metamethods.__index
    constructor.__newindex = arguments.metamethods.__newindex

    arguments.metamethods.__index = void()
    arguments.metamethods.__newindex = void()

    for method, worker in pairs(arguments.methods) do
        constructor[method] = worker
    end

    function constructor.new()
        local newValue = arguments.makeAsUserdata and newproxy(true) or setmetatable({}, {})
        local metatable = getmetatable(newValue)

        metatable.__className = arguments.className
        metatable.__constructor = constructor
        metatable.__tostring = function() return metatable.__className end
        metatable.__index = __index
        metatable.__newindex = __newindex
        metatable.__modified = Instance.new("BindableEvent")
        metatable.__propertyEvents = {}
        metatable.__self = {}

        for metamethod, value in pairs(arguments.metamethods) do
            metatable[metamethod] = value
        end

        return newValue
    end

    return table.freeze(constructor) :: constructor
end

return class