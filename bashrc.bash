# Just call a ruby script which will create the resources file without the
# agony that is bash. Then source it.

GEN_SCRIPT="${HOME}/rubyrc/rubyrc.rb"

GENRC="${HOME}/.bashrc-autogen.bash"
SRC_ERR="${HOME}/.source-errors"
TRY_SOURCE=0

gen_bashrc() {
    RUBY_ERR="${HOME}/.rubyrc-errors"

    log() {
        TOLOG="${1}"
        PREFIX='.bashrc: '
        echo "${PREFIX} ${TOLOG}"
    }

    fail() {
        if [ "${#}" -gt 0 ]; then log "${1}"; fi
        if [ -r "${GENRC}" ]
        then
            log 'trying to source old copy'
            TRY_SOURCE=1
        else
            log "found nothing to source. you have no resources :("
        fi
    }

    RUBY_CMD='ruby'

    if [ ! `command -v ${RUBY_CMD} | wc -l` -gt 0 ]
    then
        fail "new ${GENRC} not created, as ${RUBY_CMD} command not found"
    elif [ ! -e "${GEN_SCRIPT}" ]
    then
        fail "new ${GENRC} not created, as ${GEN_SCRIPT} was not found"
    elif [ ! -r "${GEN_SCRIPT}" ]
    then
        fail "new ${GENRC} not created, as you lack read permission"
    else
        "${RUBY_CMD}" "${GEN_SCRIPT}" "${GENRC}" #2> "${RUBY_ERR}"
        RET="${?}"
        if [ "${RET}" -eq 0 ]
        then TRY_SOURCE=2
        else
            log "${RUBY_CMD} returned with exit code ${RET}"
            # log "see ${RUBY_ERR} for errors"
            fail
        fi
    fi
}

gen_bashrc

if [ ! "${TRY_SOURCE}" = 0 ]
then
    source "${GENRC}" 2> "${SRC_ERR}"
    if [ ! "${?}" -eq 0 ]
    then
        log "unable to source ${GENRC}, at least not completely"
        log "see ${SRC_ERR} for sourcing errors"
    else
        if [ "${TRY_SOURCE}" = 1 ]
        then
            log "successfully sourced ${GENRC}"
        fi
    fi
fi

