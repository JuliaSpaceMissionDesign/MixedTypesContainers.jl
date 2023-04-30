function _replace_iter(idx::Int, forexpr::Expr, itname::Symbol)
    return MacroTools.postwalk(x -> x == :($itname) ? :($idx) : x, forexpr)
end

function unwrap_iterator(expr::Expr, itname::Symbol, niter)
    # get for expression and remove non used lines
    forexpr = Base.remove_linenums!(expr.args[2])

    # unwrap for loop expression
    unwrap_expr = quote end
    for it in 1:niter
        append!(unwrap_expr.args, _replace_iter(it, forexpr, itname).args)
    end
    return unwrap_expr
end

function generate_unwrappable!(argi)
    # Find for blocks that shall be unwrapped (i.e. depends on the container) and 
    # transform the iterator in an interpolated expression
    if argi isa Expr && argi.head === :macrocall && argi.args[1] == Symbol("@unwrap")
        tmp = argi.args[3]
        if tmp.head === :for
            # The iterator shall be in the form `i in 1:N` where `N` is the container 
            # dimension and `i` the iteration variable
            iter_spec = tmp.args[1]
            if iter_spec.head === Symbol("=")
                iter_spec.args[2].args[3] = Expr(:$, iter_spec.args[2].args[3])
            else
                error(
                    "invalid iterator; @iterated allows only iterators in the form `for i in 1:M`",
                )
            end
        else
            error("invalid body; @unwrap requires a for loop within its body")
        end
        return argi, 1
    end
    return argi, 0
end

"""
    @unwrap

Unwrap `for` loop `Container` iterator.
"""
macro unwrap(expr)
    niter = 0
    if expr.args[1].args[2].args[1] == :eachindex
        # eachindex($ctname)
        ctname = expr.args[1].args[2].args[2]
        itname = expr.args[1].args[1]

    elseif expr.args[1].args[2].args[1] == :(:)
        # 1:length($ctname)
        itname = expr.args[1].args[1]
        if expr.args[1].args[2].args[3] isa Expr
            ctname = expr.args[1].args[2].args[3].args[2]
        else
            ctname = nothing
            niter = expr.args[1].args[2].args[3]
        end

    else
        throw(error("invalid syntax; Container iterator format not defined"))
    end

    return esc(unwrap_iterator(expr, itname, niter))
end

"""
    @iterated

Create an _unwrappable_ function. See [`unwrap`](@ref) for details of how `Container` loops 
are efficiently treated.
"""
macro iterated(f)
    if isa(f, Expr) && (f.head === :function || Base.is_short_function_def(f))
        sign, body = f.args

        iterblocks = 0
        # Loop over each block of the function
        for (i, argi) in enumerate(body.args)
            body.args[i], itblk = generate_unwrappable!(argi)
            iterblocks += itblk
        end

        if iterblocks == 0
            @warn "@iterated used in a context where no Containers iterations are present; " *
                "consider to remove it for efficiency"
        end

        return Expr(
            :escape,
            Expr(
                f.head,
                sign,
                Expr(
                    :block,
                    Expr(
                        :if,
                        Expr(:generated),
                        Expr(:quote, body),
                        Expr(:block, Expr(:meta, :generated_only), Expr(:return, nothing)),
                    ),
                ),
            ),
        )

    else
        error("invalid syntax; @iterated must be used with a function definition")
    end
end
