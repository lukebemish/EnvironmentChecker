using ArgParse

struct Data
    classes::Vector{String}
    methods::Vector{String}
    fields::Vector{String}
end

function process(file)
    classes = String[]
    methods = String[]
    fields = String[]

    for line ∈ readlines(file)
        if startswith(line, "class: ")
            push!(classes, line[(length("class: ")+1):end])
        elseif startswith(line, "method: ")
            push!(methods, line[(length("method: ")+1):end])
        elseif startswith(line, "field: ")
            push!(fields, line[(length("field: ")+1):end])
        end
    end

    return Data(classes, methods, fields)
end

# Various heuristics

function ismethodlambda(method)
    return startswith(split(method, ".")[2], "lambda\$")
end

function isnestaccess(method)
    return startswith(split(method, ".")[2], "access\$")
end

function iscapturedargfield(field)
    return startswith(split(field, ".")[2], "val\$")
end

function lengthandnames(collection; truncate = false)
    cutoff = 3
    return "$(length(collection))$((length(collection) > 0 && (truncate || length(collection) < cutoff)) ? " ($(length(collection) < cutoff ? join(collection, ", ") : "$(join([collection...][1:cutoff], ", ")), ..."))" : "")"
end

function main()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "production"
            help = "Environment Checker file from production"
            required = true
        "development"
            help = "Environment Checker file from development"
            required = true
    end

    args = parse_args(s)

    production = process(args["production"])
    development = process(args["development"])

    println("Development classes: ", length(development.classes))
    missingdevclasses = setdiff(development.classes, production.classes)
    println(" - Missing from production: ", length(missingdevclasses))
    for missingdevclass ∈ missingdevclasses
        println("   - ", missingdevclass)
    end
    println()
    println("Development methods: ", length(development.methods))
    missingdevmethods = Set(setdiff(development.methods, production.methods))
    println(" - Missing from production: ", length(missingdevmethods))
    if length(missingdevmethods) > 0
        lambdanames = filter(ismethodlambda, missingdevmethods)
        for lambda ∈ lambdanames
            delete!(missingdevmethods, lambda)
        end
        accessnames = filter(isnestaccess, missingdevmethods)
        for accessname ∈ accessnames
            delete!(missingdevmethods, accessname)
        end
        println("   - Lambdas: ", length(lambdanames))
        println("   - Nest access: ", length(accessnames))
        println("   - Other: ", length(missingdevmethods))
        for missingdevmethod ∈ missingdevmethods
            println("     - ", missingdevmethod)
        end
    end
    println()
    println("Development fields: ", length(development.fields))
    missingdevfields = Set(setdiff(development.fields, production.fields))
    println(" - Missing from production: ", length(missingdevfields))
    if length(missingdevfields) > 0
        capturedargfields = filter(iscapturedargfield, missingdevfields)
        for capturedargfield ∈ capturedargfields
            delete!(missingdevfields, capturedargfield)
        end
        println("   - Captured arg fields: ", length(capturedargfields))
        println("   - Other: ", length(missingdevfields))
        for missingdevfield ∈ missingdevfields
            println("     - ", missingdevfield)
        end
    end

    print("\n\n")
    
    println("Production classes: ", length(production.classes))
    missingprodclasses = setdiff(production.classes, development.classes)
    println(" - Missing from development: ", length(missingprodclasses))
    for missingprodclass ∈ missingprodclasses
        println("   - ", missingprodclass)
    end
    println()
    println("Production methods: ", length(production.methods))
    missingprodmethods = Set(setdiff(production.methods, development.methods))
    println(" - Missing from development: ", length(missingprodmethods))
    if length(missingprodmethods) > 0
        lambdanames = filter(ismethodlambda, missingprodmethods)
        for lambda ∈ lambdanames
            delete!(missingprodmethods, lambda)
        end
        accessnames = filter(isnestaccess, missingprodmethods)
        for accessname ∈ accessnames
            delete!(missingprodmethods, accessname)
        end
        println("   - Lambdas: ", length(lambdanames))
        println("   - Nest access: ", length(accessnames))
        println("   - Other: ", length(missingprodmethods))
        for missingprodmethod ∈ missingprodmethods
            println("     - ", missingprodmethod)
        end
    end
    println()
    println("Production fields: ", length(production.fields))
    missingprodfields = Set(setdiff(production.fields, development.fields))
    println(" - Missing from development: ", length(missingprodfields))
    if length(missingprodfields) > 0
        capturedargfields = filter(iscapturedargfield, missingprodfields)
        for capturedargfield ∈ capturedargfields
            delete!(missingprodfields, capturedargfield)
        end
        println("   - Captured arg fields: ", length(capturedargfields))
        println("   - Other: ", length(missingprodfields))
        for missingprodfield ∈ missingprodfields
            println("     - ", missingprodfield)
        end
    end
end
 
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end