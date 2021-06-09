#!/bin/bash

# isolateScript()
# {
# 
#     pathSoFar=""
#     pathAt=0
#     for w in "$@"; do
#         let pathAt++
#         pathSoFar="$pathSoFar/$w"
#         if [  -f "$pathSoFar.sh" ]; then
#             echo "Found @ $pathAt"
#             echo "$pathSoFar.sh"
#         fi
#         echo "Forward: $pathSoFar"
#         echo "Backward: ${@:$pathAt}"
#     done
# 
# }
# 
# isolateScript "$@"

isolateScript()
{

    pathSoFar="."
    pathAt=1
    for w in "$@"; do
        let pathAt++
        pathSoFar="$pathSoFar/$w"
        if [  -f "$pathSoFar.sh" ]; then
            echo "$pathSoFar.sh ${@:$pathAt}"
            return 0
        fi
    done
    echo "-1"
    return 1
}
# isolateScript "$@"
val=$(isolateScript "$@")
if [[ $? -eq 1 ]]; then
    echo "No valid script called"
else
    echo "Valid script: $val"
    $val
fi
