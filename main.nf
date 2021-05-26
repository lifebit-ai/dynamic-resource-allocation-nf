// If gs:// or s3:// or https://, else it's local
fileSystem = params.dataLocation.contains(':') ? params.dataLocation.split(':')[0] : 'local'

// Header log info
log.info "\nPARAMETERS SUMMARY"
log.info "mainScript                            : ${params.mainScript}"
log.info "config                                : ${params.config}"
log.info "fileSystem                            : ${fileSystem}"
log.info "dataLocation                          : ${params.dataLocation}"
log.info "fileSuffix                            : ${params.fileSuffix}"
log.info "repsProcessA                          : ${params.repsProcessA}"
log.info "processAWriteToDiskMb                 : ${params.processAWriteToDiskMb}"
log.info "processATimeRange                     : ${params.processATimeRange}"
log.info "filesProcessA                         : ${params.filesProcessA}"
log.info "processATimeBetweenFileCreationInSecs : ${params.processATimeBetweenFileCreationInSecs}"
log.info "output                                : ${params.output}"
log.info "echo                                  : ${params.echo}"
log.info "cpus                                  : ${params.cpus}"
log.info "processA_cpus                         : ${params.processA_cpus}"
log.info "errorStrategy                         : ${params.errorStrategy}"
log.info "container                             : ${params.container}"
log.info "maxForks                              : ${params.maxForks}"
log.info "queueSize                             : ${params.queueSize}"
log.info "executor                              : ${params.executor}"
if(params.executor == 'google-lifesciences') {
log.info "gls_bootDiskSize                      : ${params.gls_bootDiskSize}"
log.info "gls_preemptible                       : ${params.gls_preemptible}"
log.info "zone                                  : ${params.zone}"
log.info "network                               : ${params.network}"
log.info "subnetwork                                    : ${params.subnetwork}"
}
log.info ""

projectDir = workflow.projectDir
ch_utils = Channel.fromPath("${projectDir}/utils",  type: 'dir', followLinks: false)
ch_src   = Channel.fromPath("${projectDir}/src",  type: 'dir', followLinks: false)

numberRepetitionsForProcessA = params.repsProcessA
numberFilesForProcessA = params.filesProcessA
processAWriteToDiskMb = params.processAWriteToDiskMb
processAInput = Channel.from([1] * numberRepetitionsForProcessA)
processAInputFiles = Channel.fromPath("${params.dataLocation}/*${params.fileSuffix}").take( numberRepetitionsForProcessA )

process processA {
	publishDir "${params.output}/${task.hash}", mode: 'copy'
	tag "cpus: ${task.cpus}, cloud storage: ${cloud_storage_file}"

	input:
	val x from processAInput
	file(a_file) from processAInputFiles
	each file("*") from ch_utils
	each file("*") from ch_src

	output:
	val x into processAOutput
	file "*.txt"

	script:
	"""
	# Simulate the time the processes takes to finish
	pwd=`basename \${PWD} | cut -c1-6`
	echo \$pwd
	timeToWait=\$(shuf -i ${params.processATimeRange} -n 1)
	for i in {1..${numberFilesForProcessA}};
	do echo test > "\${pwd}"_file_\${i}.txt
	sleep ${params.processATimeBetweenFileCreationInSecs}
	done;
	sleep \$timeToWait
	echo "task cpus: ${task.cpus}"

	ls -l utils/
	ls -l src/
	ls -l src/nanocompare/

	python3 utils/print.py
	python3 utils/write.py
	python3 src/nanocompare/nanoscript.py
	"""
}
