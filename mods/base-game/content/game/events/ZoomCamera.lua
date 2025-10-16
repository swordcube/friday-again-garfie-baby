function onExecute(time, params)
    -- parse this shit {"duration":16,"ease":"expoOut","mode":"stage","zoom":1.05}
    local zoom = params.zoom
    defaultCamZoom = stage.config.zoom * zoom
end