local json = require(_CHARTY_PARENT .. ".lib.json") --- @type charty.lib.Json
local Class = require(_CHARTY_PARENT .. ".lib.middleclass") --- @type charty.lib.MiddleClass

--- @class charty.Format
local Format = Class("Format", ...)

function Format:__init__()
    self.chart = nil
    self.meta = nil

    --- Whether or not this format requires multiple charts per difficulty
    self.requiresMultipleCharts = false

    --- Whether or not this format requires a metadata file
    self.requiresMetaFile = false
end

--- @param chartPath string
--- @param metaPath string
--- @param diff string|string[]?
--- @return charty.Format
function Format:fromFile(chartPath, metaPath, diff)
    error("You must override this method (Format:fromFile()) in a subclass!")
end

--- @param format charty.Format
--- @return charty.Format
function Format:fromFormat(format, diff)
    self:fromBasicFormat(format:toBasicFormat(), diff)
    return self
end

--- @param basicFormat {chart: any, meta: any}
--- @param diff string|string[]?
function Format:fromBasicFormat(basicFormat, diff)
    error("You must override this method (Format:fromBasicFormat()) in a subclass!")
end

--- @return {chart: any, meta: any}
function Format:toBasicFormat()
    error("You must override this method (Format:toBasicFormat()) in a subclass!")
end

--- @return {chart: string, meta: string}
function Format:stringify()
    return {
        chart = self.chart and json.encode(self.chart) or nil,
        meta = self.meta and json.beautify(self.meta, {newline = "\n", indent = "\t", depth = 0}) or nil
    }
end

return Format