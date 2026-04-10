def squeeze: to_entries
	| map(select(.value != null))
	| from_entries
	| if . == {} then "none" end;
group_by(.inode)
| map(
	foreach .[] as $file (
		{};
		. *= {
			key: $file.inode | tostring,
			value: {
				seconds: $file.micros / 1000000,
				files: (.value.files) + [$file.fullname],
				tags: { ($file.tagname): $file.tagvalue },
				video: {
					codec: $file.video_codec,
					bitrate: $file.video_bitrate,
					framerate: $file.framerate,
					width: $file.width,
					height: $file.height,
					aspect: $file.aspect
				},
				audio: {
					codec: $file.audio_codec,
					bitrate: $file.audio_bitrate,
					samplerate: $file.samplerate,
					channels: $file.channels,
					layout: $file.layout
				}
			}
		};
		{
			key: .key,
			value: {
				seconds: .value.seconds,
				files: .value.files | unique,
				tags: .value.tags,
				video: .value.video | squeeze,
				audio: .value.audio | squeeze
			}
		}
	)
)
| from_entries

