using CSV, DataFrames
using TextAnalysis, Languages


########## FUNCTIONS ##########

#= Chargement des données
function LoadData(file, axes)
    df = CSV.read(file)
    tab = []
    for i in df[:, axes]
        if string(typeof(i)) != "Missing"
            push!(tab, StringDocument(remove_case(i)))
        end
    end
    return tab
end
=#


# Suppression des mots inutiles (trop courants, ponctuation, nombres...)
function StripUselessWords(DataSet)
    prepare!.(DataSet, strip_punctuation | strip_articles | strip_pronouns | strip_numbers | strip_non_letters)

    WordsDiff = Dict{String, Int64}()
    for i in tokens.(DataSet)
        for j in i
            if j in keys(WordsDiff)
                WordsDiff[j] += 1
            else
                WordsDiff[j] = 1
            end
        end
    end

    ArrangedWords = collect(zip(values(WordsDiff), keys(WordsDiff)))

    # mots trop courants
    UselessWords = sort(ArrangedWords, rev = true)
    UselessWords = last.(UselessWords[1:20])

    # mots peu courants
    LonelyWords = []
    for i in ArrangedWords
        if i[1] <= 3
            push!(LonelyWords, i)
        end
    end
    for i in 1:(500 - (length(LonelyWords) % 500))
        push!(LonelyWords, LonelyWords[end])
    end
    LonelyWords = last.(LonelyWords)

    # suppression de tout ça
    for i in DataSet
        remove_words!(i, UselessWords)
        for j in 1:500:length(LonelyWords) - 1
            remove_words!(i, LonelyWords[j : j + 499])
        end
    end

    prepare!.(DataSet, strip_whitespace)
    return DataSet
end

#= function PrepareData(DataSet)
    stem!.(DataSet)
    Tokens = tokens.(DataSet)
    return Tokens
end
=#


########## MAIN ##########

Premises = []
Weights = []
for i in 0:25
    tmp = CSV.read("votrepath/data/premises_kl" * string(i) *".csv")
    push!(Premises, tmp.premise)
    push!(Weights, collect(Iterators.flatten(tmp.weight)))
end

Premises = collect(Iterators.flatten(Premises))
Weights = collect(Iterators.flatten(Weights))

Premises = StringDocument.(Premises)
Premises = StripUselessWords(Premises)

stem!.(Premises)
Premises = text.(Premises)

Dataset = DataFrame(Any[Premises, Weights], [:Premise, :Weigths])

CSV.write("votrepath/PreparedData.csv", Dataset)
