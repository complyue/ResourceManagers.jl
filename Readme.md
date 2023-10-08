# ResourceManagers.jl

Resource management in Julia, inspired by Python's `with` statement for resource acquisition and release.

## Authors

- Compl Yue ([@complyue](https://github.com/complyue)), the designer.
- ChatGPT by OpenAI, contributed to the coding and documentation.

## Background

The `@with` macro in this package is influenced by Python's `with` statement, which simplifies the management of resources such as file handlers, network connections, and other custom resources. While Julia has native resource management through the `do` syntax, the `@with` macro offers unique features:

### Unique Features Compared to Julia's `do` Syntax

1. **Multiple Resources**: One of the key features is the ability to manage multiple resources in a single block, which can be cumbersome with the native `do` syntax.

   ```julia
   # Using @with for multiple resources
   @with begin
       open_file("file1.txt", "w"):f1
       open_file("file2.txt", "w"):f2
   end begin
       write(f1, "Writing to file 1")
       write(f2, "Writing to file 2")
   end
   ```

2. **Optional Naming**: The `@with` macro provides flexibility with optional naming of resources, enabling you to either use or omit names for the resources you are managing.

   ```julia
   # Without naming
   @with open_file("file.txt", "w") begin
       # Do something
   end
   ```

By introducing these features, the `@with` macro aims to make code more readable, maintainable, and less error-prone.

## Installation

To install ResourceManagers.jl, run the following command in your Julia REPL:

```julia
] add ResourceManagers
```

## Usage

Here is a quick example using `ManagedFile` and `open_file` from this package:

```julia
using ResourceManagers

@with open_file("file.txt", "w") : f begin
    write(f, "Hello, world!")
end
```

This ensures that `file.txt` is closed automatically after the block of code is executed.

### More Examples

For managing multiple resources:

```julia
@with begin
    open_file("file1.txt", "w"):f1
    open_file("file2.txt", "w"):f2
end begin
    write(f1, "Writing to file 1")
    write(f2, "Writing to file 2")
end
```

### Implementing Your Own `ResourceManagers`

Implementing your own `ResourceManagers` is straightforward:

1. Define your custom type.
2. Add methods for `__enter__` and `__exit__` that describe how to acquire and release the resource.

Here's a quick example:

```julia
struct MyManager
  resource
end

function __enter__(m::MyManager)
  println("Acquiring resource")
  return m.resource
end

function __exit__(m::MyManager, exc::Union{Nothing,Exception})
  println("Releasing resource")
end
```

To use your custom resource manager:

```julia
@with MyManager("some_resource") : r begin
    println("Using resource: ", r)
end
```

## Tests

To run tests for ResourceManagers.jl, execute the following command in your Julia REPL:

```julia
] test ResourceManagers
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
