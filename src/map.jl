# map operations to elements

#################################################
#
#   Generic functor based mapping
#
#################################################

# the macro to generate functor-based mapping functions 
# for various number of arguments

function code_mapfuns(nargs::Int)
	asyms = [symbol("a$(d)") for d = 1 : nargs]
	params = [Expr(:(::), a, :ArrOrNum) for a in asyms]
    sargs = [:(getvalue($a, i)) for a in asyms]
    sargs1 = [:(getvalue($a, 1)) for a in asyms]
    kernel = 

    quote
    	function map!(f::Functor{$nargs}, dst::NumericArray, $(params...))
            n = length(dst)
            n == maplength($(asyms...)) || error("Inconsistent argument dimensions.")
            for i = 1 : n
                @inbounds dst[i] = evaluate(f, $(sargs...))
            end
            dst
        end

    	map1!(f::Functor{$nargs}, a1::NumericArray, $(params[2:end]...)) = map!(f, a1, $(asyms...))

    	function map(f::Functor{$nargs}, $(params...))
    		shp = mapshape($(asyms...))
    		n::Int = prod(shp)
    		reshape([(@inbounds y = evaluate(f, $(sargs...)); y) for i = 1 : n], shp)
    	end
    end
end
 
macro mapfuns(nargs)
    esc(code_mapfuns(nargs))
end

@mapfuns 1
@mapfuns 2
@mapfuns 3
@mapfuns 4
@mapfuns 5

function mapdiff!(f::Functor{1}, dst::NumericArray, a1::ArrOrNum, a2::ArrOrNum)
    n = length(dst)
    n == maplength(a1, a2) || error("Inconsistent argument dimensions.")
	for i = 1 : n
		@inbounds dst[i] = evaluate(f, getvalue(a1, i) - getvalue(a2, i))
	end
	return dst
end

function mapdiff(f::Functor{1}, a1::ArrOrNum, a2::ArrOrNum)
	shp = mapshape(a1, a2)
	n::Int = prod(shp)
	reshape([(@inbounds y = getvalue(a1, i) - getvalue(a2, i); evaluate(f, y)) for i = 1 : n], shp)
end	


#################################################
#
#   Some inplace mapping functions
#
#################################################

add!(x::NumericArray, y::ArrOrNum) = map1!(Add(), x, y)
subtract!(x::NumericArray, y::ArrOrNum) = map1!(Subtract(), x, y)
multiply!(x::NumericArray, y::ArrOrNum) = map1!(Multiply(), x, y)
divide!(x::NumericArray, y::ArrOrNum) = map1!(Divide(), x, y)

negate!(x::NumericArray) = map1!(Negate(), x)
abs!(x::NumericArray) = map1!(AbsFun(), x)
abs2!(x::NumericArray) = map1!(Abs2Fun(), x)
sqr!(x::NumericArray) = map1!(Abs2Fun(), x)
rcp!(x::NumericArray) = map1!(RcpFun(), x)
sqrt!(x::NumericArray) = map1!(SqrtFun(), x)
pow!(x::NumericArray, p::ArrOrNum) = map1!(Pow(), x, p)

floor!(x::NumericArray) = map1!(FloorFun(), x)
ceil!(x::NumericArray) = map1!(CeilFun(), x)
round!(x::NumericArray) = map1!(RoundFun(), x)
trunc!(x::NumericArray) = map1!(TruncFun(), x)

exp!(x::NumericArray) = map1!(ExpFun(), x)
log!(x::NumericArray) = map1!(LogFun(), x)

# extensions

absdiff(x::NumericArray, y::NumericArray) = mapdiff(AbsFun(), x, y)
sqrdiff(x::NumericArray, y::NumericArray) = mapdiff(Abs2Fun(), x, y)

fma!(a::NumericArray, b::ArrOrNum, c::ArrOrNum) = map1!(FMA(), a, b, c)
fma(a::ArrOrNum, b::ArrOrNum, c::ArrOrNum) = map(FMA(), a, b, c)

