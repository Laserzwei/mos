local config = {}
config.Author = "Laserzwei"
config.ModName = "Move Asteroids"
config.version = {
    major=0, minor=19, patch = 0,
    string = function()
        return  config.version.major .. '.' ..
                config.version.minor .. '.' ..
                config.version.patch
    end
}


config.MONEY_PER_JUMP = 500000          --change to your needs
config.CALLDISTANCE = 1500              --15Km is 1.500 not 15.000. Who made this up ?
config.MAXDISPERSION = 4000             --  +-40km dispersion for asteroid reentry
config.MAXTRANSFERRANGE = 1000          -- maximum Transfer range for Asteroids. Uses euclidian distance between current and target sector. Default 1000 (basically unlimited).


return config
