--!strict

-- Setup utility for rbx-wallstick
-- Installs Wally packages, generates sourcemaps with Rojo, and applies type metadata via wally-package-types
local fs = require("@lune/fs")
local stdio = require("@lune/stdio")
local process = require("@lune/process")

type Options = {
	cwd: string?,
	env: { [string]: string }?,
}

-- Runs a shell command and prints formatted output
local function run(program: string, params: { string }, options: Options?)
	stdio.write(stdio.style("bold"))
	print(`> {program} {table.concat(params, " ")}`)
	stdio.write(stdio.style("reset"))

	local child = process.create(program, params, {
		stdio = "inherit",
		shell = true,
		cwd = options and options.cwd or nil,
		env = options and options.env or nil,
	})

	local result = child:status()

	if result.code > 0 then
		print(`Command failed with exit code {result.code}`)
		process.exit(result.code)
	end

	local output = result.ok and child.stdout:readToEnd() or child.stderr:readToEnd()
	return output:gsub("\n$", "")
end

-- Step 1: Install dependencies
print("Installing Wally packages...")
run("wally", { "install" })

-- Step 2: Generate sourcemap for development tools and type indexing
print("Generating Rojo sourcemap...")
run("rojo", { "sourcemap", "default.project.json", "-o", "sourcemap.json" })

-- Step 3: Generate type metadata and ensure folders exist
local folderList = { "Packages", "DevPackages", "ServerPackages" }

for _, folderName in folderList do
	if fs.isDir(folderName) then
		print(`Generating type metadata for {folderName}...`)
		run("wally-package-types", { "--sourcemap", "sourcemap.json", folderName })
	else
		print(`Creating missing folder: {folderName}`)
		fs.writeDir(folderName)
	end
end

print("Setup complete.")
