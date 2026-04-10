{
	tags: .format.tags // {}
	| del(
		.major_brand,
		.minor_version,
		.compatible_brands,
		.encoder
	),
	duration: [.streams[].duration | tonumber] | max * 1000000,
	video: (
		.streams[] | select(.codec_type == "video") | [
			"'\\(.codec_name)'",
			.bit_rate,
			"'\\(.avg_frame_rate)'",
			.width,
			.height,
			"'\\(.display_aspect_ratio // "n/a")'"
		] | join(",")
	) // "",
	audio: (
		.streams[] | select(.codec_type == "audio") | [
			"'\\(.codec_name)'",
			.bit_rate,
			.sample_rate,
			.channels,
			"'\\(.channel_layout)'"
		] | join(",")
	) // ""
}

