#!/bin/bash
buildname=simple-test
quiet=no

[[ $1 == "-q" ]] && { quiet=; shift ;}

force_on=$1 # define a node name here if we need to

function red() { echo -e "\e[31m$@\e[0m"  ;}
function green() { echo -e "\e[32m$@\e[0m"  ;}

SED=sed
type -p gsed >/dev/null 2>/dev/null && SED=gsed

function run() {
    oc delete builds --all >/dev/null
    B=$(oc start-build ${buildname})
    BP=$(oc get pod|grep build|awk '{print $1}')
    Host=$(oc describe pod $BP|grep Node:|${SED} -r 's/Node:[ \t]*//;s,/.*,,')

    if [[ -n ${force_on} && ${force_on} != ${Host} ]];then
        oc cancel-build ${B} >/dev/null
        return 1
    fi
}

while true;do
    run
    if [[ $? != 0 ]];then
        run
    else
        break
    fi
done

if [[ -n ${quiet} ]];then
    echo "Started around: $(date)"
    echo "Running on ${Host}"

    echo -n "Waiting that the build ${BP} started: "
fi


while :;do
    running=$(oc get pod ${BP}|grep Running)
   [[ -n ${running} ]] && break
    sleep 2
   [[ -n ${quiet} ]] &&  echo -n "."
done
[[ -n ${quiet} ]] && echo ". success"

[[ -n ${quiet} ]] && echo "Wait that the build ${BP} has succeded":
while true;do
    OUTPUT=$(oc build-logs ${B} |tail -n1)
    if echo ${OUTPUT} | grep -q "Successfully pushed";then
        green "${Host}:Success: ${OUTPUT}"
        break
    elif echo ${OUTPUT} | grep -q "Build error";then
        red "${Host}: Failure ${OUTPUT}"
        break
    fi
    echo "Waiting: ${OUTPUT}"
    sleep 5
done

[[ -n ${quiet} ]] && echo "End at: $(date)"
