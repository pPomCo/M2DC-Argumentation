using CSV, DataFrames, TextAnalysis

########## FUNCTIONS ##########

# Load + Tokenization
function LoadData()
    Dataset = CSV.read("PreparedData.csv", types = [String, Float64])
    Premises = []
    Weights = []
    for (ind, val) in enumerate(Dataset[:, 1])
        if string(typeof(val)) != "Missing"
            push!(Premises, remove_case(val))
            push!(Weights, Dataset[ind, 2])
        end
    end
    Premises = tokens.(StringDocument.(Premises))

    return Premises, Weights
end

# Split train / test
function DataSplitting(Premises, Weights)
    Ratio = 5 # nbr de fois que le train est plus grand que le test

    TrainPremises = Premises[1:(length(Premises) ÷ (Ratio + 1) * Ratio)]
    TestPremises = Premises[(length(Premises) ÷ (Ratio + 1) * Ratio) + 1:end]
    TrainWeights = Weights[1:(length(Premises) ÷ (Ratio + 1) * Ratio)]
    TestWeights = Weights[(length(Premises) ÷ (Ratio + 1) * Ratio) + 1:end]

    return TrainPremises, TrainWeights, TestPremises, TestWeights
end

# Extraction des paramètres du corpus nettoyé
function CorpusParameters(Data)
    WordsList = collect(Iterators.flatten(Data))
    VocList = unique(WordsList)
    return (VocList, length(VocList))
end

#= similarité/distance entre vecteurs
function MinkowskiDistance(vec1, vec2, dim)
    Dist = 0
    for i in 1:LengthVoc
        Dist += abs(vec1[i] - vec2[i]) ^ dim
    end
    return Dist ^ (1 / dim)
end
=#

#= Retourne une liste de mots proches selon une fct de similarité
function ClosestWords(vec1, vecsToCompare, FunSim)
    scores = []
    for (ind, vec2) in enumerate(vecsToCompare)
        push!(scores, (MinkowskiDistance(vec1, vec2, 2), ind))
    end
    scores = sort(scores)[1:20]
    words = VocList[last.(scores)]

    return scores, words
end
=#

# return probabilities for each words to occure in each classes, labels = (-1; 1)
function BowUnigTrain(TrainPremises, TrainWeights)
    Positive = zeros(LengthVoc)
    Negative = zeros(LengthVoc)
    Distribution = [Positive, Negative]

    # Counting Bag of Words
    for (ind, val) in enumerate(TrainPremises)
        for i in val
            Distribution[Int(TrainWeights[ind] + 3) ÷ 2][VocDict[i]] += 1
        end
    end

    # Transformer en proba (qu'un mot soit de classe positive ou negative)
    Distribution[1] /= sum(Distribution[1])
    Distribution[2] /= sum(Distribution[2])
    return Distribution
end

# Premises = data
# Weights = labels
function BowUnigTest(Distribution, TestPremises, TestWeights)
    Success = zeros(2)
    Assignation = zeros(2)
    for (ind, val) in enumerate(TestPremises)
        PosChances = 1
        NegChances = 1
        for i in val
            PosChances += Distribution[1][VocDict[i]]
            NegChances += Distribution[2][VocDict[i]]
            #= résultats très très similaire avec : (parce que très petites probas)
            PosChances *= 1 + Distribution[1][VocDict[i]]
            NegChances *= 1 + Distribution[2][VocDict[i]]
            =#
        end
        Result = argmax([PosChances, NegChances])
        Assignation[Result] += 1
        if Result == (TestWeights[ind] + 3) ÷ 2
            Success[Result] += 1
        end
    end
    return Success, Assignation
end

# return measures (Precision, Recall, FMeasure in this order) for positive class and negative class separately
function RelevantMeasures(Success, Assignation, TestWeights)
    NbClassPos = sum(x-> x > 0, TestWeights)
    NbClassNeg = sum(x-> x < 0, TestWeights)
    NbClasses = [NbClassPos, NbClassNeg]

    Precision = Success ./ Assignation
    Recall = Success
    Recall[1] /= NbClassPos
    Recall[2] /= NbClassNeg
    FMeasure = (2 .* precision .* Recall) ./ (precision .+ Recall)
    return Precision, Recall, FMeasure
end

########## MAIN ##########

Premises, Weights = LoadData()
TrainPremises, TrainWeights, TestPremises, TestWeights = DataSplitting(Premises, Weights)

### Initialisation d'objets utiles ###
# VocList = juste la liste des mots (unique)
# VocDict = associe chaque mot à son ID dans VocList (annuaire inversé)
(VocList, LengthVoc) = CorpusParameters(Premises)
VocDict = Dict{String, Int64}()
for (ind, val) in enumerate(VocList)
    VocDict[string(val)] = ind
end

### Approche BOW UNIG
Distribution = BowUnigTrain(TrainPremises, TrainWeights)
(Success, Assignation) = BowUnigTest(Distribution, TestPremises, TestWeights)
RelevantMeasures(Success, Assignation, TestWeights)
