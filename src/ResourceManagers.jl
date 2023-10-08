module ResourceManagers

export @with, ResourceManager, __enter__, __exit__
export ManagedFile, open_file


"""
    abstract type ResourceManager end

An abstract type representing a resource that can be managed.
"""
abstract type ResourceManager end

"""
    __enter__(r::ResourceManager)

Enter a context for resource management. 
Override this function to define what happens when the resource is acquired.
"""
function __enter__(r::ResourceManager)
  @warn "No __enter__ method defined for $(typeof(r))"
  return r
end

"""
    __exit__(r::ResourceManager, exc::Union{Nothing,E}) where {E<:Exception}

Exit a context for resource management.
Override this function to define what happens when the resource is released.
"""
function __exit__(r::ResourceManager, exc::Union{Nothing,E}) where {E<:Exception}
  @warn "No __exit__ method defined for $(typeof(r))"
end


"""
    @with pairs block

A macro for simplified resource management.

# Examples
```julia
@with open_file("file.txt", "w") : f begin
    write(f, "Hello, world!")
end
```
"""
macro with(pairs, block)
  resource_pairs = []

  if pairs.head == :block  # Multiple resources
    for pair in filter(x -> isa(x, Expr), pairs.args)  # Only keep Expr objects
      if pair.head == :call && pair.args[1] == :(:)
        push!(resource_pairs, (pair.args[2], pair.args[3]))
      elseif pair.head == :symbol || pair.head == :call || pair.head == :macrocall
        push!(resource_pairs, (pair, nothing))
      else
        throw(ArgumentError("Invalid syntax. Expected assignments (resource : variable)"))
      end
    end
  else  # Single resource
    if pairs.head == :call && pairs.args[1] == :(:)
      push!(resource_pairs, (pairs.args[2], pairs.args[3]))
    elseif pairs.head == :symbol || pairs.head == :call || pairs.head == :macrocall
      push!(resource_pairs, (pairs, nothing))
    else
      throw(ArgumentError("Invalid syntax. Expected assignments (resource : variable)"))
    end
  end

  final_block = generate_with_block(resource_pairs, block)
  esc(final_block)
end

"""
    generate_with_block(resource_pairs, block)

Generates a code block for resource management.
This function is internal and used by the `@with` macro.
"""
function generate_with_block(resource_pairs, block)
  if isempty(resource_pairs)
    return block
  end

  (resource, as_var) = popfirst!(resource_pairs)
  resource_var = gensym()  # Generate a unique symbol for the resource
  inner_block = generate_with_block(resource_pairs, block)

  if as_var === nothing
    return quote
      local exc = nothing
      local $resource_var = $resource
      local entered_resource = __enter__($resource_var)
      try
        $inner_block
      catch e
        exc = e
      finally
        __exit__($resource_var, exc)
        if exc !== nothing
          throw(exc)
        end
      end
    end
  else
    return quote
      local exc = nothing
      local $resource_var = $resource
      local $as_var = __enter__($resource_var)
      try
        $inner_block
      catch e
        exc = e
      finally
        __exit__($resource_var, exc)
        if exc !== nothing
          throw(exc)
        end
      end
    end
  end
end



"""
    struct ManagedFile <: ResourceManager

A type representing a managed file, conforming to the `ResourceManager` interface.
"""
struct ManagedFile <: ResourceManager
  filename::AbstractString
  mode::AbstractString
  lock::Bool

  file::Ref{IO}
end

"""
    __enter__(m::ManagedFile)

Do open a file, as acquired resource.
"""
function __enter__(m::ManagedFile)
  m.file[] = open(m.filename, m.mode; lock=m.lock)
  return m.file[]
end

"""
    __exit__(m::ManagedFile, exc::Union{Nothing,Exception})

Release a file resource by closing it.
"""
function __exit__(m::ManagedFile, exc::Union{Nothing,Exception})
  close(m.file[])
end

"""
    open_file(filename::AbstractString, [mode::AbstractString]; lock = true)

Wrap a (to be opened) file in a `ManagedFile` object for resource management.
"""
function open_file(filename::AbstractString, mode::AbstractString="r"; lock=true)
  return ManagedFile(filename, mode, lock, Ref{IO}())
end


end # module ResourceManagers
