###############################################################################
# Build all solutions in this directory, prompting for each one (default 'no').
###############################################################################
function build()
{
    $solutions = (get-childitem *.sln)
    
    if ($solutions -and ($solutions.gettype().BaseType.Name.tolower().trim() -eq "array"))
    {
        foreach ($item in $solutions)
        {
            build-item -item $item -defaultShouldBuild $FALSE
        }
    }
    elseif ($solutions)
    {
        $myArgs = join $args
        $buildArgs = $myArgs.ToString()
        `msbuild $solutions.Name $buildArgs`
    }
}

###############################################################################
# Concatenates the string representation of its arguments together.
###############################################################################
function join()
{
    $str = new-object -TypeName "System.Text.StringBuilder"
    foreach ($s in $args)
    {
        [void]$str.Append([String]$s)
    }
    return $str
}

###############################################################################
# Recusively build all solutions in and below this directory, prompting for
# each one (default 'yes'). Set the param to $FALSE to disable prompt.
###############################################################################
function build-all()
{
    build-all-internal $TRUE
}

###############################################################################
# Internal representation of build-all. In my own script, there are other 
# callers, which is why this is separate from the other function.
###############################################################################
function build-all-internal($interactive)
{
    try 
    {
        push-location
        $solutions = (get-childItem -Path . -Filter "*.sln" -Recurse)
        foreach ($item in $solutions)
        {
            try
            {
                $myArgs = join $args
                push-location $item.Directory
                build-item -item $item -defaultShouldBuild $TRUE -buildArgs $myArgs.ToString() -interactive $interactive
            }
            finally
            {
                pop-location
            }
        }
    }
    finally
    {
        pop-location
    }
}

###############################################################################
# Actually builds the solution. Fundamental to the other functions.
###############################################################################
function build-item
{
    param ($item, $defaultShouldBuild, $buildArgs, $interactive)
        
    if ($defaultShouldBuild)
    {
        $defaultStr = "y"
    }
    else 
    {
        $defaultStr = "n"
    }
    if ((test-path variable:\interactive) -and $interactive -eq $FALSE)
    {
        $bShouldBuild = $TRUE
    }
    else 
    {
        $shouldBuild = read-host "Build ${item}? [${defaultStr}]"
        $shouldBuild = $shouldBuild.toLower().trim()
        $bShouldBuild = $defaultShouldBuild
        if (($shouldBuild -eq "n") -or ($shouldBuild -eq "no") -or ($shouldBuild -eq "false"))
        {
            $bShouldBuild = $FALSE
        }
        elseif (($shouldBuild -eq "y") -or ($shouldBuild -eq "yes") -or ($shouldBuild -eq "true"))
        {
            $bShouldBuild = $TRUE
        }
    }
    if ($bShouldBuild)
    {
        `msbuild $item.Name $buildArgs`
    }
}