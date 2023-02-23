# NNW

You could imagine it stands for Nice Network Wrapper, or even just NickNetworks.

I really picked this name because its a short three letters, and its fast as shit to type out.

## Installation

[Caveat Emptor](#caveat-emptor)

    curl -kLSs  https://<raw url to wherever you host this script>/nnw.sh | bash
[Caveat Emptor](#caveat-emptor)

## What?

The goal of this is to be a consolidated bash wrapper, that uses a git repository as a 'package source', allowing easy access to the various collections of scripts that reside within it. Easily and without the need for manually moving scripts.

This repo specifically is a forkable repo 'template' if you will that way the 'core functionality' of the NNW-Wrapper can still recieve updates, whilst having different versions of it deployed and in use, side by side.

This main repo will only ever include things in the 'do' folder, primairly aimed at performing tasks universally across many linux distros/flavors/enviroments/configurations. 
    Please note that the 'do' folder may at somepoint soon, change to the 'sys' folder

## Why?

Because loosing track of the snippets, and scripts I write sucks. This is an attempt to solve that problem.
> Ever had a script you lost that you made on a VPS, for a client, on a workstation, or otherwise 'somewhere'?
> > Yeah, thats why.

## How?

The script will detect it isn't installed and automatically request sudo perms to install itself.

After that you can simply call scripts via their relative names in the repo, from anywhere in your terminal.

ie

To clear a git repos history:

    nnw git clear-history

To update the system(apt based):

    nnw do update

## By?

Every time it runs it will check itself for an update via gits sha, when a missmatch happens it will do a git diff to confirm, then pull any changes from the remote repo

it will then attempt to perform the relative command specificed from the repo (by calling its sh script)

sudo scripts at your own assertion. Its really depends on the script you're hotloading you should sudo.

## Me?

Yes. You.
All you should need to do is clone the repo, and simply change relevant configs at the top of the 'nnw.sh' wrapper itself.
Enjoy!

----------

## Caveat Emptor

```curl -kLSs  https://git.nicknet.works/NickNet.works/NNW/raw/branch/main/nnw.sh | bash```

    This command downloads and executes a shell script from a remote server, which can pose a significant security risk. It's essential to understand that this command grants the remote server complete control over your computer and executes arbitrary code with elevated privileges.

    The remote server could, for instance, modify the script to install malware or steal sensitive data, including passwords or other confidential information. Therefore, before using this command, it's crucial to ensure that you trust the source of the script and that it's not been tampered with.

    It's also important to understand that the script could potentially modify or delete critical system files, leading to system instability or data loss. Therefore, it's essential to review the script's contents and ensure that you understand its intended purpose fully.

    In summary, using the curl -kLSs command to download and execute a shell script carries significant security risks. Use it with caution, only if you trust the source, and fully understand the implications of running arbitrary code on your computer
