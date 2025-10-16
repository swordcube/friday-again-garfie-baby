function onExecute(time, params)
    -- parse this shit {"duration":16,"ease":"expoOut","mode":"stage","zoom":1.05}
    local zoom = params.zoom
    if params.mode == "stage" then
        defaultCamZoom = stage.config.zoom * zoom
    elseif params.mode == "direct" then
        defaultCamZoom = zoom
    end
end