#!/usr/bin/env texlua
module = "beamer_testfiles"
checkruns    = 2
checkengines = { "pdftex" }

extracmds    = '\\input regression-test.tex \\loggingoutput \\START'

-- Hack to add extracmds
-- copy of runtest from l3build-check.lua, except for the marked lines
function runtest(name, engine, hide, ext, test_type, breakout)
  local lvtfile = name .. (ext or lvtext)
  cp(lvtfile, fileexists(testfiledir .. "/" .. lvtfile)
    and testfiledir or unpackdir, testdir)
  local checkopts = checkopts
  engine = engine or stdengine
  local binary = engine
  local format = string.gsub(engine,"tex$",checkformat)
  -- Special binary/format combos
  local special_check = specialformats[checkformat]
  if special_check and next(special_check) then
    local engine_info = special_check[engine]
    if engine_info then
      binary    = engine_info.binary  or binary
      format    = engine_info.format  or format
      checkopts = engine_info.options or checkopts
    end
  end
  -- Finalise format string
  if format ~= "" then
    format = " --fmt=" .. format
  end
  -- Special casing for XeTeX engine
  if string.match(engine, "xetex") and test_type.generated ~= pdfext then
    checkopts = checkopts .. " -no-pdf"
  end
  -- Special casing for ConTeXt
  local function setup(file)
    extracmds = extracmds or "" -- <<< Added extracmds here
    return " -jobname=" .. name .. " " .. ' "' .. extracmds .. '\\input ' .. file .. '" ' -- <<< Added extracmds here
  end
  if string.match(checkformat,"^context$") then
    function setup(file) return ' "' .. file .. '" '  end
  end
  local basename = testdir .. "/" .. name
  local gen_file = basename .. test_type.generated
  local new_file = basename .. "." .. engine .. test_type.generated
  local asciiopt = ""
  for _,i in ipairs(asciiengines) do
    if binary == i then
      asciiopt = "-translate-file ./ascii.tcx "
      break
    end
  end
  -- Clean out any dynamic files
  for _,filetype in pairs(dynamicfiles) do
    rm(testdir,filetype)
  end
  -- Ensure there is no stray .log file
  rmfile(testdir,name .. logext)
  local errlevels = {}
  local localtexmf = ""
  if texmfdir and texmfdir ~= "" and direxists(texmfdir) then
    localtexmf = os_pathsep .. abspath(texmfdir) .. "//"
  end
  for i = 1, checkruns do
    errlevels[i] = run(
      testdir,
      -- No use of localdir here as the files get copied to testdir:
      -- avoids any paths in the logs
      os_setenv .. " TEXINPUTS=." .. localtexmf
        .. (checksearch and os_pathsep or "")
        .. os_concat ..
      os_setenv .. " LUAINPUTS=." .. localtexmf
        .. (checksearch and os_pathsep or "")
        .. os_concat ..
      -- Avoid spurious output from (u)pTeX
      os_setenv .. " GUESS_INPUT_KANJI_ENCODING=0"
        .. os_concat ..
      -- Allow for local texmf files
      os_setenv .. " TEXMFCNF=." .. os_pathsep
        .. os_concat ..
      set_epoch_cmd(epoch, forcecheckepoch) ..
      -- Ensure lines are of a known length
      os_setenv .. " max_print_line=" .. maxprintline
        .. os_concat ..
      binary .. format
        .. " " .. asciiopt .. " " .. checkopts
        .. setup(lvtfile)
        .. (hide and (" > " .. os_null) or "")
        .. os_concat ..
      runtest_tasks(jobname(lvtfile),i)
    )
    -- Break the loop if the result is stable
    if breakout and i < checkruns then
      if test_type.generated == pdfext then
        if fileexists(testdir .. "/" .. name .. dviext) then
          dvitopdf(name, testdir, engine, hide)
        end
      end
      test_type.rewrite(gen_file,new_file,engine,errlevels)
      if base_compare(test_type,name,engine,true) == 0 then
        break
      end
    end
  end
  if test_type.generated == pdfext then
    if fileexists(testdir .. "/" .. name .. dviext) then
      dvitopdf(name, testdir, engine, hide)
    end
    cp(name .. pdfext,testdir,resultdir)
    ren(resultdir,name .. pdfext,name .. "." .. engine .. pdfext)
  end
  test_type.rewrite(gen_file,new_file,engine,errlevels)
  -- Store secondary files for this engine
  for _,filetype in pairs(auxfiles) do
    for _,file in pairs(filelist(testdir, filetype)) do
      if string.match(file,"^" .. name .. "%.[^.]+$") then
        local newname = string.gsub(file,"(%.[^.]+)$","." .. engine .. "%1")
        if fileexists(testdir .. "/" .. newname) then
          rmfile(testdir,newname)
        end
        ren(testdir,file,newname)
      end
    end
  end
  return 0
end

function save(names)
  checkinit()
  local engines = options["engine"] or {stdengine}
  if names == nil then
    print("Arguments are required for the save command")
    return 1
  end
  for _,name in pairs(names) do
    os.execute("cp ./" .. testfiledir .. "/" .. name .. ".tex ./" .. testfiledir .. "/" .. name .. ".lvt" )    -- hack to automatically copy .tex to .lvt
    local test_filename, kind = testexists(name)
    if not test_filename then
      print('Test "' .. name .. '" not found')
      return 1
    end
    local test_type = test_types[kind]
    if test_type.expectation and locate({unpackdir, testfiledir}, {name .. test_type.expectation}) then
      print("Saved " .. test_type.test .. " file would override a "
        .. test_type.expectation .. " file of the same name")
      return 1
    end
    for _,engine in pairs(engines) do
      local testengine = engine == stdengine and "" or ("." .. engine)
      local out_file = name .. testengine .. test_type.reference
      local gen_file = name .. "." .. engine .. test_type.generated
      print("Creating and copying " .. out_file)
      runtest(name, engine, false, test_type.test, test_type)
      ren(testdir, gen_file, out_file)
      cp(out_file, testdir, testfiledir) 
      cp(name .. ".pdf", testdir, testfiledir) --      <--- Added to copy the pdf to the test dir
      if fileexists(unpackdir .. "/" .. test_type.reference) then
        print("Saved " .. test_type.reference
          .. " file overrides unpacked version of the same name")
        return 1
      end
    end
  end
  return 0
end
target_list["save"].func = save -- Update save in the target_list


