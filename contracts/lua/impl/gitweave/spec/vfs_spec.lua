local busted = require("busted")
local describe = busted.describe
local it = busted.it
local assert = busted.assert

local SimpleVFS = require("src.vfs.simple_vfs")
local SQLiteVFS = require("src.vfs.sqlite_vfs")

describe("VFS Implementations", function()
	local function test_vfs_implementation(vfs, name)
		describe(name .. " VFS", function()
			-- Reset state before each test
			before_each(function()
				if name == "Simple" then
					vfs.files = {}
					vfs.directories = { ["/"] = {} }
				end
			end)

			describe("Directory Operations", function()
				it("should create directories recursively", function()
					local result = vfs.mkdirp("/test/dir1/dir2")
					assert.is_true(result)

					-- Verify directory exists
					local entries = {}
					for entry in vfs.scandir("/test/dir1") do
						table.insert(entries, entry)
					end
					assert.equals(1, #entries)
					assert.equals("dir2", entries[1].name)
					assert.equals("directory", entries[1].type)
				end)
			end)

			describe("File Operations", function()
				it("should create and write to files", function()
					local fd = vfs.open("/test/file.txt", "w")
					assert.is_not_nil(fd)

					local write_result = vfs.write(fd, "Hello, World!")
					assert.is_true(write_result)

					local content, err = vfs.readFile(fd)
					assert.is_nil(err)
					assert.equals("Hello, World!", content)
				end)

				it("should handle non-existent files", function()
					local content, err = vfs.readFile("/nonexistent.txt")
					assert.is_nil(content)
					assert.equals("ENOENT: No such file", err)
				end)

				it("should delete files", function()
					local fd = vfs.open("/test/delete.txt", "w")
					vfs.write(fd, "test")

					local result = vfs.unlink(fd)
					assert.is_true(result)

					local content, err = vfs.readFile(fd)
					assert.is_nil(content)
					assert.equals("ENOENT: No such file", err)
				end)
			end)

			describe("Directory Listing", function()
				it("should list directory contents", function()
					vfs.mkdirp("/test/list")
					vfs.open("/test/list/file1.txt", "w")
					vfs.open("/test/list/file2.txt", "w")
					vfs.mkdirp("/test/list/subdir")

					local entries = {}
					for entry in vfs.scandir("/test/list") do
						table.insert(entries, entry)
					end

					assert.equals(3, #entries)

					-- Sort entries for consistent testing
					table.sort(entries, function(a, b)
						return a.name < b.name
					end)

					assert.equals("file1.txt", entries[1].name)
					assert.equals("file", entries[1].type)

					assert.equals("file2.txt", entries[2].name)
					assert.equals("file", entries[2].type)

					assert.equals("subdir", entries[3].name)
					assert.equals("directory", entries[3].type)
				end)
			end)

			describe("File Renaming", function()
				it("should rename files", function()
					local fd = vfs.open("/test/old.txt", "w")
					vfs.write(fd, "test content")

					local result = vfs.rename("/test/old.txt", "/test/new.txt")
					assert.is_true(result)

					local content, err = vfs.readFile("/test/new.txt")
					assert.is_nil(err)
					assert.equals("test content", content)

					local _, err = vfs.readFile("/test/old.txt")
					assert.equals("ENOENT: No such file", err)
				end)
			end)
		end)
	end

	-- Test both implementations
	test_vfs_implementation(SimpleVFS, "Simple")
	test_vfs_implementation(SQLiteVFS, "SQLite")
end)
