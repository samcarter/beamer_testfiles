-- converting data dumps from https://data.stackexchange.com/stackoverflow/query/1407420/download-all-codeblocks-as-file-with-an-cte into a collection of test files

-- steps to prepare the csv file:
-- 1. remove first line
-- 2. replace "," with ®
-- 3. repace first/last " with ®
-- 4. replace "\n" with ®
-- 5. replace &amp; with &
-- 6. replace &lt; with <
-- 7. replace &gt; with >


-- file name
--local filename = "QueryResults_SO.csv"
--local community = "stackoverflow.com"

local filename = "QueryResults_tex.csv"
local community = "tex.stackexchange.com"


-- opening file and string it in a string
local file = io.open(filename)
local string = file:read("*a")
local cells = {}

-- reading in the cells of the csv file
i=0
for token in string.gmatch(string, "[^®]+") do
    cells[i]= token
    i = i+1
end

-- processing
--    n: answer number
--  n+1: code block in answer
--  n+2: code
for n = 0,i-3,3
do
    
    -- writing to file
    texfile = io.open(cells[n] .. "_" .. cells[n+1] .. ".tex", "w")
    texfile:write("% https://" .. community .. "/a/" .. cells[n] .. "\n")    
    texfile:write(cells[n+2])
    texfile:close()
  
    print(cells[n])
end

print(i)

-- close file
file:close()