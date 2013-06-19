# run all tests

tests = ["functors", "vmap", "vbroadcast", "vreduce"]

for t in tests
	tf = joinpath("test", "test_$t.jl")
	println("Running $tf ...")
	include(tf)
end
