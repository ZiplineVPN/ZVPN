
while [[ $# -gt 0 ]]; do
    case "$1" in
    "--verbose" | "--v")
        verbose=1
        ec green_bright "Verbosity enabled, will log lots of stuff!"
        shift
        ;;
    "--uninstall")
        uninstall=1
        ec red_bright "Uninstall flag detected, will uninstall $(c yellow "$displayName")"
        shift
        ;;
    "--reinstall")
        reinstall=1
        ec red_bright "Uninstall flag detected, will uninstall $(c yellow "$displayName")"
        shift
        ;;
    *)
        break
        ;;
    esac
done