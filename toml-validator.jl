import TOML
import JSON
import Dates
using Test

ROOT="."

struct ExtendedSerialization <: JSON.CommonSerialization end
const ES = ExtendedSerialization
const SC = JSON.StructuralContext

function JSON.show_json(io::SC, s::ES, x::Integer)
    if isfinite(x)
        Base.print(io, """{"type": "integer", "value": "$x"}""")
    else
        show_null(io)
    end
end

function JSON.show_json(io::SC, s::ES, x::AbstractFloat)
    if isfinite(x)
        Base.print(io, """{"type": "float", "value": "$x"}""")
    else
        show_null(io)
    end
end

function JSON.show_json(io::SC, s::ES, x::String)
    Base.print(io, """{"type": "string", "value": """)
    JSON.show_string(io, x)
    Base.print(io, "}")
end

function JSON.show_json(io::SC, s::ES, x::Dates.DateTime)
    sdate = "$(x)Z"
    Base.print(io, "{\"type\": \"datetime\", \"value\": \"$sdate\"}")
end

function JSON.show_json(io::SC, s::ES, x::Bool)
    Base.print(io, "{\"type\": \"bool\", \"value\": \"$x\"}")
end

function JSON.show_json(io::SC, s::ES, x::Union{AbstractVector, Tuple})
    #isnotanyempty = eltype(x) != Any && length(x) > 0
    Base.print(io, "{\"type\": \"array\", \"value\": ")
    JSON.begin_array(io)
    for elt in x
        JSON.show_element(io, s, elt)
    end
    JSON.end_array(io)
    Base.print(io, "}")
end

# invalid
@testset "Validation" begin
    loc = joinpath(ROOT, "invalid")
    @testset "Invalid" for f in sort!(readdir(loc))
        @test_throws CompositeException TOML.parse(joinpath(loc, f))
    end

    loc = joinpath(ROOT, "valid")
    @testset "Valid" for f in unique(map(n -> n[1:end-5], readdir(loc)))
        res1 = TOML.parsefile(joinpath(loc, f*".toml"))
        # compare to json
        io = IOBuffer()
        JSON.show_json(io, ExtendedSerialization(), res1)
        seekstart(io)
        toml_json = JSON.parse(io)
        res2 = JSON.parsefile(joinpath(loc, f*".json"))        
        @test toml_json == res2
        # compare to self
        io = IOBuffer()
        TOML.print(io, res1)
        seekstart(io)
        res3 = TOML.parse(io)
        @test res3 == res1
    end
end
