#######################mkrobot.sh################################
_mkrobot_completions()
{
	if [ "${#COMP_WORDS[@]}" != "2" ]; then
		return;
	fi
	COMPREPLY=($(compgen -W "build checkout clone clean cleanlibs cleanros commit configurator deletetag deploy node node_python push rebuild rebuildlibs rebuildros reclone tag test update update_intellisense launch" "${COMP_WORDS[1]}"))
}
alias mkrobot="./ros2_dev/mkrobot.py"
complete -F _mkrobot_completions mkrobot.sh
# complete -F _mkrobot_completions mkrobot
#######################mkrobot.sh################################
