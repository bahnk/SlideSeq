import java.nio.file.Paths

process mark_duplicates {

	//label "tagging"
	label "sequencing"
	time "10:00:00"

	tag { "${name}" }

	publishDir Paths.get( params.out_dir ),
		mode: "copy",
		overwrite: "true",
		saveAs: { filename ->
			if ( filename.indexOf(".txt") != -1 )
			{
				"qc/${filename}"
			}
			else
			{
				"files/${filename}"
			}
		}

	input:
		tuple val(metadata), path(bam)
	
	output:
		tuple val(metadata), path("${name}.dup.bam"), emit: bam
		tuple val(metadata), path("${name}.dup.txt"), emit: metrics
	
	script:
		
		name = metadata["name"]

		"""
		picard-tools \
			MarkDuplicates \
				I=$bam \
				O=${name}.dup.bam \
				M=${name}.dup.txt
		"""
}

process bam_tag {

	label "tagging"
	label "sequencing"
	
	tag { "${basename}" }

	input:
		tuple val(metadata), path(bam), val(suffix), path(script)

	output:
		tuple val(metadata), path("${basename}.bam"), path("${basename}.bam.bai")

	script:		
		
		name = metadata["name"]
		basename = "${name}.${suffix}"


		"""
		./$script $bam "${basename}.bam"
		echo "Indexing..."
		samtools index "${basename}.bam"
		"""
}

process bam_tag_hmem {

	label "tagging"
	label "sequencing"
	
	tag { "${basename}" }

	input:
		tuple val(metadata), path(bam), val(suffix), path(script)

	output:
		tuple val(metadata), path("${basename}.bam"), path("${basename}.bam.bai")

	script:		
		
		name = metadata["name"]
		basename = "${name}.${suffix}"


		"""
		./$script $bam "${basename}.bam"
		echo "Indexing..."
		samtools index "${basename}.bam"
		"""
}

process umis_per_barcode {

	label "tagging"
	label "sequencing"
	
	tag { "${name}" }

	input:
		tuple val(metadata), path(bam), path(bai), path(script)

	output:
		tuple val(metadata), path("${basename}.bam"), path("${basename}.bam.bai")

	script:		
		
		name = metadata["name"]
		suffix = "umis"
		basename = "${name}.${suffix}"
		threshold = params.umis_threshold

		"""
		./$script $bam "${basename}.bam" $threshold
		echo "Indexing..."
		samtools index "${basename}.bam"
		"""
}

process htseq {

	label "tagging"
	label "sequencing"

	tag { "${name}" }
	
	input:
		tuple val(metadata), path(bam), path(bai)

	output:
		tuple val(metadata), path("${out_bam}"), path("${out_bam}.bai"), emit: bam
		tuple val(metadata), path("${out_txt}"), emit: txt

	script:		
		
		name = metadata["name"]
		out_sam = "${name}.htseq.sam"
		out_bam = "${name}.htseq.bam"
		out_txt = "${name}.htseq.txt"
		gtf = metadata["gtf"]

		"""
		htseq-count --format bam --samout sample.sam $bam $gtf > $out_txt
		samtools view -H $bam > $out_sam
		cat sample.sam >> $out_sam
		samtools view -S -b $out_sam > $out_bam
		samtools index $out_bam
		"""
}

