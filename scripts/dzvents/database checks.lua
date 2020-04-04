--[[ -- DB check
        
        Will give you a warning when something is wrong with the (domoticz) sqlite database
        requires sqlite3 
            install command on linux:    sudo apt install sqlite3 
            install command on openwrt:  opkg install sqlite3-cli
            install command on synology: sudo /opt/bin/opkg install sqlite3-cli
]]--
return {
            on =    {  
                        timer   =   { 
                                        "at 03:07"             -- change to a time that suits you
                                    },            
                    },
    
        logging =   {  
                        level     =   domoticz.LOG_DEBUG,       -- change to LOG_ERROR after you tested  the script
                        marker    =   "DB check" 
                    },

    execute = function(dz)
        -- =======================  Settings below this line =================
        local email                   = true                                -- set to false if you don't want an Email when something wromg with database
        local notify                  = true                                -- set to false if you don't want a notification when something wromg with database
        local subject                 = "Domoticz database check"           -- Free text
        local emailaddress            = "richard.rozema@gmail.com"          -- Your Email address
        local path                    = "/home/pi/domoticz/"                -- full qualified path to your database 
        local database                = "domoticz.db"                       -- database filename + extension
        -- local database             = "corrupt.db"                        -- test database filename + extension
                                                                            -- you can corrupt a test database by just load it in an edior
                                                                            -- and remove a couple of bytes
        local sqlite                  = "/usr/bin/sqlite3"                  -- location of your sqlite3 tool (use which sqlite3 to find location)
  
        local myNotificationTable     =     {
                                             -- table with one or more notification systems. 
                                             -- uncomment the notification systems that you want to be used
                                             -- Can be one or more of
                                             
                                             dz.NSS_GOOGLE_CLOUD_MESSAGING, 
                                             dz.NSS_PUSHOVER,               
                                             -- dz.NSS_HTTP, 
                                             -- dz.NSS_KODI, 
                                             -- dz.NSS_LOGITECH_MEDIASERVER, 
                                             -- dz.NSS_NMA,
                                             -- dz.NSS_PROWL, 
                                             -- dz.NSS_PUSHALOT, 
                                             -- dz.NSS_PUSHBULLET, 
                                             -- dz.NSS_PUSHOVER, 
                                             -- dz.NSS_PUSHSAFER,                        
                                            }
        -- =======================  No modification needed below this line ==================

         local function logWrite(str,level)             -- Support function for shorthand debug log statements
            dz.log(tostring(str),level or dz.LOG_DEBUG)
        end
    
        local space                   = " " 
        local baseCommand             = "sudo" .. space .. sqlite .. space .. path .. database .. space
        local checks                  = {} 
              checks                  = {
                                                  "\'select count(id) from deviceStatus;\'",
                                                   "\'.schema\'",
                                                  "\'pragma integrity_check;\'",
                                                  "\'pragma foreign_key_check;\'",
                                        }

        local function rc2Text(rc)
            local errorMessages =   {
                                          [1] = "Generic error",
                                          [2] = "Internal logic error in SQLite",
                                          [3] = "Access permission denied",
                                          [4] = "Callback routine requested an abort",
                                          [5] = "The database file is locked",
                                          [6] = "A table in the database is locked",
                                          [7] = "memory allocation failed",
                                          [8] = "Attempt to write a readonly database",
                                          [9] = "Operation terminated by sqlite3_interrupt",
                                         [10] = "Some kind of disk I/O error occurred",
                                         [11] = "The database disk image is malformed",
                                         [12] = "Unknown opcode in sqlite3_file_control",
                                         [13] = "Insertion failed because database is full",
                                         [14] = "Unable to open the database file",
                                         [15] = "Database lock protocol error",
                                         [16] = "Internal use only",
                                         [17] = "The database schema changed",
                                         [18] = "String or BLOB exceeds size limit",
                                         [19] = "Abort due to constraint violation",
                                         [20] = "Data type mismatch",
                                         [21] = "Library used incorrectly",
                                         [22] = "Uses OS features not supported on host",
                                         [23] = "Authorization denied",
                                         [24] = "Not used",
                                         [25] = "2nd parameter to sqlite3_bind out of range",
                                         [26] = "File opened that is not a database file",
                                     }
            return(errorMessages[rc] or "Unknown error")
        end

        local function osExecute(base,check)
            local fileHandle     = assert(io.popen(base .. check, 'r'))
            local commandOutput  = assert(fileHandle:read('*a'))
            local returnTable    = {fileHandle:close()}
            check = check:gsub("'","") .." result ==>> " ..  ( returnTable[3] ~= 0 and "Failed: " .. rc2Text(returnTable[3]) .. commandOutput .. " (".. returnTable[3] .. ")" or true and "OK" )
            logWrite("Command " .. check )
            return check,returnTable[3]            -- rc[3] contains returnCode
        end
        
        local function checkDatabase()
            if dz.utils.fileExists(path .. database) then
                if dz.utils.fileExists(sqlite) then
                    for _,check in ipairs (checks) do
                        local result,rc = osExecute(baseCommand,check)
                        if rc ~= 0 then 
                            return rc, result  
                        end
                    end
                else
                    return 1,"sqlite3 not installed"
                end
            else
                return 1,"wrong path to database"
            end
            return 0
        end

        -- main program
        local rc, result = checkDatabase()
        if rc ~= 0 then
            logWrite(result,dz.LOG_ERROR)
            if email then dz.email(subject,result,emailaddress) end
            if notify then dz.notify(subject, result, dz.PRIORITY_NORMAL, dz.SOUND_INTERMISSION,"",  myNotificationTable ) end
        end
    end
}