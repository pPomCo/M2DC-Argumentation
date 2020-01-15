# Extraction

## Usage

Le contenu de ce dossier permet d'extraire le graphe d'argumentation de :

 - Wikidebats
 - Argüman

Pour cela, ouvrez un terminal unix dans ce dossier et tapez :

	# Wikidebats
	./wd_extract.sh
	
	# Argüman
	./am_extract.sh [fr|en|es|pl|tr]

Cela produit deux fichiers *xxx_nodes.csv* et *xxx_edges.csv* représentant le graphe. Ils peuvent être importés avec *Neo4j* ou *Gephi* par exemple (*cf.* bas de page).

Il est possible de tout télécharger d'un coup :

	# Download all and move it to the 'out' directory
	mkdir -p out
	./wd_extract.sh
	for lg in fr en es pl tr
	do
		./am_extract.sh $lg
	done
	mv *_nodes.csv *_edges.csv *_insertion.cql out


## Description

### Modèle(s)

On considère que les débats, arguments, sous-arguments, objections, etc. sont tous des arguments au sens large.

Le graphe d'argumentation est un graphe étiqueté :

 - Les sommets ont un *label* (le texte de l'argument) et une *url* (pour les besoins de l'extraction : la page de l'argument)
 - Les arcs représentent les relations de soutien (*resp.* d'attaque) ont un poids égal à 1 (*resp. -1).

### Procédure

 1. On télécharge et simplifie les pages du site, de façon à ne garder que la structure du graphe sous forme d'une collection de fichiers CSV.
  Chaque fichier *xxx.csv* contient des lignes *a1;b1;c1*, *a2;b2;c2*, etc. Cela signifie que l'argument *xxx* à pour parents les arguments d'url *ai*, de label *bi* avec un poids *ci*.
 2. On parse cette collection de fichiers pour reconstruire le graphe, sous forme de deux CSVs listant les sommets et les arcs.
 3. On utilise un outil tel que Neo4j pour importer le graphe, le requêter et le visualiser.
 
 Les scripts *xxx_extract.sh* effectuent ce travail

#### Données brutes (WikiDebats)

Sur WikiDebats, les arguments ont une page dédiée (sauf les arguments terminaux). Ainsi les liens HTML de WikiDebats couvrent les arcs du graphe.

On a trois cas :

1. Les débats sont les puits du graphe, ils ont une page dédiée, accessible depuis la *sitemap*.
2. Les arguments et sous-arguments étayés sont les sommets intermédiaires, ils ont une page dédiée accessible depuis la page de l'argument soutenu/attaqué.
3. Les arguments terminaux (feuilles) sont les sources du graphe, ils n'ont pas de page dédiée et sont représentés uniquement dans la page de l'argument soutenu/attaqué.

Les pages sont téléchargées et transformées en CSV avec XSLT. Le traitement commence après le téléchargement de la sitemap, et est effectué en boucle jusqu'à ce qu'il ne produise plus de nouveaux fichieris : toutes les pages sont alors téléchargées et converties.


#### Données brutes (Argüman)

Sur Argüman, les choses sont plus compliquées. En effet :

 - Le HTML n'est pas valide, XSLT le refuse
 - Les arguments n'ont pas réellement de page dédiée
 - Certains arguments sont chargés dynamiquement en Javascript
 - Les urls sont parfois trop longues pour servir de nom de fichier.
 - Les arguments ne sont pas *Pour* ou *Contre*, mais sont annotés *Parce que*, *Mais* et *Cependant*

Nous utilisons plusieurs *astuces*, ainsi le traitement devient similaire à celui pour WikiDebats.

1. Le HTML est parsé avec *sed*, ou nettoyé avec *sed* puis parsé avec XSLT.
2. La requête AJAX permettant de charger dynamiquement un argument (et son sous-arbre) produit un fragment HTML qui constitue pour nous la "page dédiée" de l'argument
3. Les urls sont conservées dans une table dont les numeros de lignes permettent de nommer les fichiers
4. Les arguments *Parce que* sont positifs (+1), les autres sont négatifs. On utilise -1 pour *Mais* et -0.5 pour *Cependant*

Nous produisons donc une collection de fichiers CSV, comme pour WikiDebats. La suite du traitement est similaire.
 

## Interrogation et visualisation

### Neo4j

Après avoir copié les fichiers *xxx_nodes.csv* et *xxx_edges.csv* dans le dossier *import* de la base, il faut exécuter le script d'insertion *xxx_insertion.cql*.

Une fois cela fait, nous pouvons interroger la base et visualiser le résultat des requêtes dans le navigateur :


	// Get debate list (nodes without outgoing edges)
	MATCH (a:Argument {origin:"wd"}) WHERE NOT (a)-[]->(:Argument) 
		  RETURN a.n, a.label

	//a.n	a.label
	//17	"Faut-il supprimer les notes à l'école ?"
	//158	"Faut-il préserver les Murs à pêches de Montreuil ?"
	//159	""
	//160	"Le réchauffement climatique est-il dû à l'activité humaine ?"
	//161	"Faut-il arrêter de manger des animaux ?"
	//162	"Faut-il instaurer un revenu de base ?"
	//163	"Faut-il instaurer un salaire à vie ?"
	//[...]

	// Get the #192 debate
	MATCH (a:Argument)-[*]->(b:Argument {n: 192, origin: "wd"})
	  RETURN a, b
	  
![Neo4j viz](images/n4j_example.svg  "Neo4j visualization")

Le système de requêtage permet aussi de détecter des problèmes dans le graphe d'argumentation.

	// Cycles
	MATCH (n)-[*]->(m) WHERE n = m RETURN n, m

![Cycles](images/n4j_cycles.svg  "Cycles in the argumentation graph")

### Gephi

Gephi permet la visualisation de la totalité du graphe.

![Gephi viz](images/gephi_example.png  "Gephi visualization")
Spatialisation (OpenOrd + Yifan Hu proportionnel) du graphe non pondéré (tous les arcs sont de poids égal à 1)

