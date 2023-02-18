# NNW
NNW.

You could imagine it stands for Nice Network Wrapper, or even just NickNetworks.

I really picked this name because its a short three letters, and its fast as shit to type out.

## Installation
    curl -kLSs  https://git.nicknet.works/NickNet.works/NNW/raw/branch/main/nnw.sh | bash

## What is this?
The goal of this is to be a consolidated bash program or wrapper per say, that uses this git repository as a 'package source' allowing easy access to the various collection of scripts that I use.

Easily and without the need for manually moving scripts via curl/wget, or needing them locally at all.

## Why?
Because loosing track of the snippets, and scripts I write sucks. This is an attempt to solve that problem.
> Ever had a script you lost that you made on a VPS, for a client, on a workstation, or otherwise 'somewhere'?
> > Yeah, thats why.

## How?
The script will detect it isn't installed and automatically request sudo perms to install itself.

After that you can simply call scripts via their relative names in the repo.

ie

To clear a git repos history:

    nnw fix git-clear-history

To update the system(apt based):

    nnw do update


# Things it do?

Every time it runs it will check itself for an update via gits sha, when a missmatch happens it will do a git diff to confirm, then pull any changes from the remote repo

sudo scripts at your own assertion. Its really depends on the script you're hotloading you should sudo.

> Self thought. Maybe scripts should be able to declare if they require sudo.

This wrapper offers two 'modes' as of conception.

First is to simply run a script once.
> As of right now this is the only mode. And it will not accept any varibles or input. Simply hotload the script.

Scripts that do this can expose varibles, that will be asked to the user for input, or will be parsed via arguments.

These are exposed by being placed before the line

    #END INPUT

in the top of the file.

The second 'mode' allows a script to opt itself for install.

These scripts allow the varibles in the top of the script to be re-written permanently via a one-time user prompting. 

These are exposed by being placed before the line

    #END SETUP

The re-written script can then be installed in one of two ways.
 - as a system command itself(replacing the /'s in its file path with -'s)
 - as a run on startup 'service' script. 
 - - 'service' scripts will only be run once at startup. If they wish to repeat a task, they must loop indefinately.
 >Please note these varibles will be stored in plain text via installation.
        Be mindful of the prompts you question for.

### Me?
Eventually, you, yes.
All you should need to do is simply change the repo url at the top of the 'nnw.sh' wrapper itself.
> What about github, gitlab, and others?

You'll need to change the 'rawViewPattern' underneath the repo url itself.
This pattern is responsible for building the gitea 'raw link' urls.

### Caveat Emptor
```curl -kLSs  https://git.nicknet.works/NickNet.works/NNW/raw/branch/main/nnw.sh | bash```

    This command downloads and executes a shell script from a remote server, which can pose a significant security risk. It's essential to understand that this command grants the remote server complete control over your computer and executes arbitrary code with elevated privileges.

    The remote server could, for instance, modify the script to install malware or steal sensitive data, including passwords or other confidential information. Therefore, before using this command, it's crucial to ensure that you trust the source of the script and that it's not been tampered with.

    It's also important to understand that the script could potentially modify or delete critical system files, leading to system instability or data loss. Therefore, it's essential to review the script's contents and ensure that you understand its intended purpose fully.

    In summary, using the curl -kLSs command to download and execute a shell script carries significant security risks. Use it with caution, only if you trust the source, and fully understand the implications of running arbitrary code on your computer