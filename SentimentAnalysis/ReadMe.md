## Prescriptum <br/>
il se peut que certaines parties du code soit coder de manière pas opti du tous, si vous voulez critiquer ça merci d'en faire part d'une manière constructive (ok Huto ?)<br/>
<br/>
Download Julia 1.3 : https://julialang.org/downloads/<br/>
<br/>
## Un IDE a considérer pour Julia : Atom avec le package "Juno" <br/>
Très pratique, permet d'executer instruction par instruction<br/>
pour installer un package avec Atom : File -> Settings -> click -> onglet Package<br/>
Sinon pour Arch Linux -> Jupyter<br/>
(enfin après vous faites comme vous voulez c'est juste a considérer)<br/>
<br/>
## Pour installer des packages Julia <br/>
Pkg.add("truc") -> pour installer le package "truc". A insérer directement dans le code (le package truc n'existe pas vraiment je crois)<br/>
ou depuis l'interface Julia tapez -> "] add truc" (sans guillemets bien sûr)<br/>
<br/>
## Quelques différences Python -> Julia qui pourront vous aider <br/>
import CSV ==> using CSV (même si import existe aussi en Julia)<br/>
pour déclarer une fct ==> function truc(a, b, c) # et "end" à la fin des fonctions ET des IF/WHILE/FOR/ETC<br/>
concaténation de string ==> * au lieu de +<br/>
Les fonctions peuvent être suivies d'un point (".") pour dire d'appliquer la fct à tous les elements du vecteur<br/>
Compilation "Just-in-time" donc la première éxecution d'un truc est plus lente que les suivantes<br/>
faites des fonctions parce que les variables ont une portée locale et ne peuvent pas passer du main à un "for" par exemple<br/>
Ah oui, les indices des tableaux commencent à 1 et non 0, pas d'inquiétude on s'y fait vite <br/>
j'espère que j'oublie rien d'important, sinon envoyez moi un mail<br/>
<br/>
## DataProcessing.jl <br/>
- En gros le code charge les données de l'extraction de pipo (que je remet pour pas que vous cherchiez)
	- les premisses sont dans un array et les poids dans un autre
	- transforme toutes les premisses dans un type batard "StringDocument" necessaire pour le stemming plus loin
- Enlève la ponctuation, les articles, les pronoms, les nombres et les caractères chelous (grâce au package Languages et TextAnalysis)
- Supprime les 20 mots les plus courants (il faut juste changer la ligne UselessWords = last.(UselessWords[1:20]) pour changer le nombre)
- Supprime les mots qui apparaissent moins de 4 fois (arbitraire aussi)
	- attention ça peut prendre plusieurs minutes ici, y'a sûrement mieux mais c'est à faire qu'une seule fois donc j'ai pas trop chercher à faire plus rapide
- Supprimer les double espaces créés par toutes ces suppressions
- Fais le stemming grâce à la fonction stem!() du package TextAnalysis 
- retransforme les premisses en text simple et met tout ça dans un DataFrame (il me semble que c'est la même chose que le dataframe de Pandas)
- ecrit tout ça dans un fichier "PreparedData.csv" pour pouvoir le lire et en faire sa lecture afin de le lire dans le prochain programme
	- changer le path sinon il s'écrira dans un endroit obscur de votre machine (tips : pareil pour quand il faudra le lire)

<br/>
## Baseline.jl <br/>
Très simple ici : <br/>
- Chargement des données
- "Train"
- Test
- Mesures de pertinence
<br/>
Voilà ! Si vous avez besoin de plus amples explications sur un truc, envoyez moi un mail !<br/>
