local ClientPresentation = {}

function ClientPresentation.new(camera)
	return {
		camera = camera,
		fade = 0,
		local_ui = {},
	}
end

function ClientPresentation.bind_camera(presentation, camera)
	assert(type(presentation) == "table", "presentation must be a table")
	assert(type(camera) == "table", "camera must be a table")
	presentation.camera = camera
	return presentation
end

return ClientPresentation
