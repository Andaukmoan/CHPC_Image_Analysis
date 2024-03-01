-- -*- lua -*-
--Modified from CHPC-UofU
--https://github.com/CHPC-UofU/anaconda-modules/blob/master/miniconda3/latest.lua

help([[Module which sets the PATH variable for user instaled miniconda 
       To check the available packages: conda list
]])
-- change myanapath if the installation is in a different place in your home
-- note that this is a relative path from the base of your home directory
local myanapath = "software/pkg/miniconda3"
-- if you want to share this miniconda installation with others, use the full
-- path
--local myanapath = "/uufs/chpc.utah.edu/common/home/u0123456/software/pkg/miniconda3"

-- optionally modify the module metadata 
local version = myModuleVersion ()
whatis("Name         : Miniconda " .. version .. " Python 3")
whatis("Version      : " .. version .. " & Python 3")
whatis("Category     : Compiler")
whatis("Description  : Python environment")
whatis("URL          : https://conda.io/miniconda")
whatis("Installed on : --- ")
whatis("Modified on  : --- ")
whatis("Installed by : ---")

-- don't change anything below
if (string.find(myanapath,"uufs") == nil) then
  myana = pathJoin(os.getenv("HOME"),myanapath)
else
  myana = myanapath
end
setenv("PYTHONPREFIX",myana)
prepend_path("PATH",pathJoin(myana,"bin"))

-- Jul19 conda change - to enable virtual environments, we need to source conda.sh, and unset all that conda.sh sets at module unload
if (mode() == "load") then
  io.stdout:write("source "..myana.."/etc/profile.d/conda."..myShellType().."\n")
end
-- this happens at unload
-- could also do "conda deactivate; " but that should be part of independent VE module
if (myShellType() == "csh") then
  -- csh sets these environment variables and an alias for conda
  cmd = "unsetenv CONDA_EXE; unsetenv _CONDA_ROOT; unsetenv _CONDA_EXE; " ..
        "unsetenv CONDA_SHLVL; unalias conda"
  execute{cmd=cmd, modeA={"unload"}}
end
if (myShellType() == "sh") then
  -- bash sets environment variables, shell functions and path to condabin
  if (mode() == "unload") then
    remove_path("PATH", pathJoin(myana,"condabin"))
  end
  cmd = "unset CONDA_EXE; unset _CE_CONDA; unset _CE_M; " ..
        "unset -f __conda_activate; unset -f __conda_reactivate; " ..
        "unset -f __conda_hashr; unset CONDA_SHLVL; unset _CONDA_EXE; " ..
        "unset _CONDA_ROOT; unset -f conda"
  execute{cmd=cmd, modeA={"unload"}}
end


family("python")
