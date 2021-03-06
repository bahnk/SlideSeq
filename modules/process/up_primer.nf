import java.nio.file.Paths

process extract_barcode {

	label "sequencing"
	
	tag { "${name}" }

	publishDir Paths.get( params.out_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename ->
			if ( filename.indexOf(".csv") != -1 )
			{
				"qc/${filename}"
			}
			else
			{
				"files/${filename}"
			}
		}

	input:
		tuple val(metadata), path(read1), path(read2), path(script)

	output:
		tuple val(metadata), path("${name}.fastq.gz"), emit: fastq
		tuple val(metadata), path("${name}.extract_barcode.csv"), emit: metrics
		tuple \
			val(metadata),
			path("${name}.extract_barcode.up_distances.csv"),
			emit: distances

	script:		
		
		name = metadata["name"]
		read_structure = metadata["read_structure"]

		"""
		./$script \
			--sample "${name}" \
			--fastq "${name}.fastq.gz" \
			--read-structure "${read_structure}" \
			--max-distance ${params.up_errors_threshold} \
			$read1 $read2
		"""
}

