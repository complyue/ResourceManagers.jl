using ResourceManagers

@with open_file("/tmp/file.txt", "w"):f begin
  write(f, "Hello, world!")
end
