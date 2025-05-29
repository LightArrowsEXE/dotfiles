import Util from require "ILL.ILL.Util"

json = require "json"

class Config

	getPath: (dir) -> Util.fixPath aegisub.decode_path("?user") .. dir

	getMacroPath: (dir, namespace = script_namespace) ->
		if namespace
			return "#{Config.getPath dir}#{namespace}"
		else
			error "Expected script_namespace"

	getElements: (gui) ->
		elements = {}
		for {:name, :value} in *gui
			elements[name] = value if name
		return elements

	getElement: (gui, name) ->
		if element = Config.getElements[name]
			return element
		else
			error "element not found"

	new: (@interface, @dir = "/config/") =>
		@setPath!
		@setJsonPath!

	setPath: (dir) => @path = Config.getPath dir or @dir

	setJsonPath: (namespace) => @jsonPath = Config.getMacroPath(@dir, namespace) .. ".json"

	reset: =>
		if Util.fileExist @jsonPath
			if jit.os == "Windows"
				os.execute "del #{@jsonPath}"
			else
				os.execute "rm -f #{@jsonPath}"
			return true
		return false

	save: (elements) =>
		unless script_version
			error "Expected script_version"
		elements.__VERSION__ = script_version
		unless Util.fileExist @path, true
			os.execute "mkdir #{@path}"
		success, code = pcall json.encode, elements
		if success
			file = io.open @jsonPath, "w"
			file\write code
			file\close!
		else
			error "could not save the config", 2
		return code

	getInterface: =>
		{:interface} = @
		if file = io.open @jsonPath, "r"
			if data = file\read "*a"
				success, obj = pcall json.decode, data
				if success
					file\close!
					unless script_version
						error "Expected script_version"
					if obj.__VERSION__ == script_version
						for objName, objValue in pairs obj
							for i = 1, #interface
								cfg = interface[i]
								if cfg.name == objName
									cfg.value = objValue
						return interface
				else
					error "could not get the config", 2
			else
				error "could not get file data", 2
		@save Config.getElements interface
		@getInterface interface

{:Config}