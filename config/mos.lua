local config = {}

config.MONEY_PER_JUMP = 500000          --change to your needs
config.CALLDISTANCE = 1500              --15Km is 1.500 not 15.000. Who made this up ?
config.MAXDISPERSION = 4000             --  +-40km dispersion for asteroid reentry
config.MAXTRANSFERRANGE = 50          -- maximum Transfer range for Asteroids. Uses euclidian distance between current and target sector. Default 50 (quite large).


return config
