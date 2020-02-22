using CSV, DataFrames, TextAnalysis

########## FUNCTIONS ##########

# Load + Tokenization
function LoadData()
    Dataset = CSV.read(ARGS[1], types = [String, Float64])
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

# VocList = juste la liste des mots (unique)
# VocDict = associe chaque mot à son ID dans VocList (annuaire inversé)
function BowUnigParameters(Data)
    WordsList = collect(Iterators.flatten(Data))
    VocList = unique(WordsList)
    VocDict = Dict{String, Int64}()
    for (ind, val) in enumerate(VocList)
        VocDict[string(val)] = ind
    end
    return (VocList, length(VocList), VocDict)
end

# return probabilities for each words to occure in each classes, labels = (-1; 1)
function BowUnigTrain(TrainPremises, TrainWeights, VocDict)
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

function BowPredict(Distribution, Instance, CurrVocDict)
    PosChances = 0
    NegChances = 0
    for i in Instance
        PosChances += Distribution[1][CurrVocDict[i]]
        NegChances += Distribution[2][CurrVocDict[i]]
        #= résultats très très similaire avec : (parce que très petites probas)
        PosChances *= 1 + Distribution[1][CurrVocDict[i]]
        NegChances *= 1 + Distribution[2][CurrVocDict[i]]
        =#
    end
    return argmax([PosChances, NegChances]), abs(PosChances - NegChances)
end

# Premises = data
# Weights = labels
function BowUnigTest(Distribution, TestPremises, TestWeights)
    Success = zeros(2)
    Assignation = zeros(2)
    for (ind, val) in enumerate(TestPremises)
        Result = BowUnigPredict(Distribution, val)
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
    Recall = Success ./ NbClasses
    FMeasure = (2 .* Precision .* Recall) ./ (Precision .+ Recall)
    return Precision, Recall, FMeasure
end


function BowBigPreProc(Data)
    WordsList = collect(Iterators.flatten(Data))
    VocList = unique(WordsList)
    VocDict = Dict{String, Int64}()
    for (ind, val) in enumerate(VocList)
        VocDict[string(val)] = ind
    end
    return (VocList, length(VocList), VocDict)
end

function BowBigPreProc(Premises, Weights)
    Dataset = []
    for x in 1:length(Premises)
        CurrString = []
        for i in 2:length(Premises[x])
            push!(CurrString, Premises[x][i - 1] * " " * Premises[x][i])
        end
        push!(Dataset, CurrString)
    end

    (VocList, LengthVoc) = BowBigPreProc(Dataset)
    VocDict = Dict{String, Int64}()
    for (ind, val) in enumerate(VocList)
        VocDict[string(val)] = ind
    end
    return VocList, LengthVoc, VocDict, Dataset
end

function BowBigTrain(TrainPremises, TrainWeights, VocDict)
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

########## MAIN ##########

Premises, Weights = LoadData()

#= Approche BOW UNIGRAMME

(VocList, LengthVoc, VocDict) = BowUnigParameters(Premises)
TrainPremises, TrainWeights, TestPremises, TestWeights = DataSplitting(Premises, Weights)
Distribution = BowUnigTrain(TrainPremises, TrainWeights)
(Success, Assignation) = BowUnigTest(Distribution, TestPremises, TestWeights)
RelevantMeasures(Success, Assignation, TestWeights)
=#


#= Approche BOW BIGRAMME

(VocList, LengthVoc, VocDict) = BowBigPreProc(Premises, Weights)
TrainPremises, TrainWeights, TestPremises, TestWeights = DataSplitting(Text, Weights)
DistributionBowBig = BowBigTrain(TrainPremises, TrainWeights)
=#


### COMBINAISON DE TOUTES LES FEATURES ###

(VocList, LengthVoc, VocDict1) = BowUnigParameters(Premises)
TrainPremises, TrainWeights, TestPremisesBowUnig, TestWeightsBowUnig = DataSplitting(Premises, Weights)
DistributionBowUnig = BowUnigTrain(TrainPremises, TrainWeights, VocDict1)

(VocList, LengthVoc, VocDict2, Dataset) = BowBigPreProc(Premises, Weights)
TrainPremises, TrainWeights, TestPremisesBowBig, TestWeights = DataSplitting(Dataset, Weights)
DistributionBowBig = BowBigTrain(TrainPremises, TrainWeights, VocDict2)

function TestAllFeatures()
    Success = zeros(2)
    Assignation = zeros(2)
    for i in 1:length(TestPremisesBowUnig)
        BowUnigPred = BowPredict(DistributionBowUnig, TestPremisesBowUnig[i], VocDict1)
        BowBigPred = BowPredict(DistributionBowBig, TestPremisesBowBig[i], VocDict2)
        BowPred = [BowUnigPred, BowBigPred]
        # Si les predictions ne sont pas cohérentes, on choisit celle du modèle le plus sûr de lui (mesure de similarité)
        if BowUnigPred[1] != BowBigPred[1]
            Result = BowPred[argmax([BowUnigPred[2], BowBigPred[2]])][1]
        else
            Result = BowUnigPred[1]
        end
        Assignation[Result] += 1
        if Result == (TestWeights[i] + 3) ÷ 2
            Success[Result] += 1
        end
    end
    return Success, Assignation
end
(Success, Assignation) = TestAllFeatures()


RelevantMeasures(Success, Assignation, TestWeightsBowUnig)
