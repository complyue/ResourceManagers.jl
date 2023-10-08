using Test
using ResourceManagers

# Define mock resource types for testing
struct DummyResource1
  name::String
end

struct DummyResource2
  name::String
end

# Define the __enter__ and __exit__ methods for these resources
function __enter__(resource::DummyResource1)
  println("Entering resource: ", resource.name)
  return "Resource 1"
end

function __exit__(resource::DummyResource1, exc::Union{Nothing,Exception})
  println("Exiting resource: ", resource.name)
end

function __enter__(resource::DummyResource2)
  println("Entering resource: ", resource.name)
  return "Resource 2"
end

function __exit__(resource::DummyResource2, exc::Union{Nothing,Exception})
  println("Exiting resource: ", resource.name)
end

# Tests

# Single resource, no naming
@testset "Single resource without naming" begin
  output = @with DummyResource1("Test1") begin
    println("Inside block")
  end
  @test output === nothing
end

# Single resource with naming
@testset "Single resource with naming" begin
  output = @with DummyResource1("Test1"):r1 begin
    @test r1 == "Resource 1"
  end
end

# Multiple resources without naming
@testset "Multiple resources without naming" begin
  output = @with begin
    DummyResource1("Test1")
    DummyResource2("Test2")
  end begin
    println("Inside block")
  end
  @test output === nothing
end

# Multiple resources with naming
@testset "Multiple resources with naming" begin
  output = @with begin
    DummyResource1("Test1"):r1
    DummyResource2("Test2"):r2
  end begin
    @test r1 == "Resource 1"
    @test r2 == "Resource 2"
  end
end

# Mixed resources with and without naming
@testset "Mixed named and unnamed resources" begin
  output = @with begin
    DummyResource1("Test1"):r1
    DummyResource2("Test2")
  end begin
    @test r1 == "Resource 1"
  end
end

@testset "Test resource acquisition/release order" begin
  resource_order = []

  struct DummyResource <: ResourceManager
    name::String
  end

  function __enter__(r::DummyResource)
    push!(resource_order, "Acquired: $(r.name)")
    return r
  end

  function __exit__(r::DummyResource, exc::Union{Nothing,Exception})
    push!(resource_order, "Released: $(r.name)")
  end

  r1 = DummyResource("Resource 1")
  r2 = DummyResource("Resource 2")

  @with begin
    r1:r1_handle
    r2:r2_handle
  end begin
    # Perform operations with resources if needed
  end

  @test resource_order == ["Acquired: Resource 1", "Acquired: Resource 2", "Released: Resource 2", "Released: Resource 1"]
end
