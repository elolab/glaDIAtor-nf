process GeneratePseudoSpectra  {
    cpus { task.executor == 'local' ? Runtime.runtime.availableProcessors() / sample_count : Runtime.runtime.availableProcessors() }
    memory { task.executor == 'local' ? params.memory_ceiling as MemoryUnit / sample_count : params.memory_ceiling }

    input:
    file diafile
    path diaumpireconfig
    val sample_count

    output:
    file "*.mgf"

    script:
    thread_count = Runtime.runtime.availableProcessors()

    """
    cat "${diaumpireconfig}" | sed "s/@PROCESS_THREAD_COUNT@/${thread_count}/g" > diaumpire.params.altered

    diaumpire-se -Xmx${task.memory.toGiga()}g "${diafile}" diaumpire.params.altered
    """
}
