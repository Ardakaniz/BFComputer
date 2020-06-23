# BFComputer Specifications

BFComputer – abrégé BFCom, ou BFC – est un ordinateur 12-bits fonctionnant avec le langage hétéroclite Brainf*ck en guise de langage d’assembleur. Ainsi, il ne comprend que huit instructions basiques qui sont détaillés maintenant.

## Le Brainf*ck et les instructions

Le Brainf*ck est donc composé de huit instructions élémentaires permettant de manipuler une mémoire, effectuer des boucles et interagir avec des entrées/sorties.

| Instruction | Description                                              |
| :---------: | -------------------------------------------------------- |
|    **+**    | Incrémente la valeur de la cellule courante              |
|    **-**    | Décrémente la valeur de la cellule courante              |
|    **>**    | Incrémente le curseur de la mémoire                      |
|    **<**    | Décrémente le curseur de la mémoire                      |
|    **[**    | Début d’une boucle : y rentre si la valeur est non nulle |
|    **]**    | Fin d’une boucle : y sort si la valeur est nulle         |
|    **.**    | Envoie la valeur de la cellule courante à la sortie      |
|    **,**    | Écrit la valeur de l’entrée dans la cellule courante     |

## L’architecture de l’ordinateur

L’ordinateur doit donc avoir une architecture spécifique pour interpréter ce jeu d’instruction réduit. L’ALU – Arithmetic and Logic Unit – est assez simple car il se résume à incrémenter ou décrémenter la valeur des registres.  
Cependant, ce qui complexifie la tâche est la gestion des boucles. Dans un langage d’assembleur normal, il n’existe pas de boucle à proprement parlé mais des ‘sauts’ avec ainsi l’adresse d’arrivée indiquée dans l’instruction. Ici le challenge a été de trouver un mécanisme permettant à l’ordinateur d’aller chercher le début ou la fin de la boucle correspondante -- non connue d'avance sauf éventuellement en rajoutant des données aux instructions mais le but était vraiment que l'ordinateur puisse comprendre un code BF brut.    
De plus, chaque instruction de boucle va être stocké dans une mémoire cache parallèle à celle utilisable pour l’utilisateur pour être réutilisable si on rencontre de nouveau l'instruction correspondante.

L’architecture peut être décomposée en deux parties : la *logique de contrôle*,  qui permet de décoder l’instruction courante et de l’exécuter ; ainsi que la *logique de calcul*, qui contient les mémoires, la RAM, l’ALU et les entrées/sorties. Mais avant tout, parlons de l’horloge principale de l’ordinateur.

### L’horloge
Elle comporte deux modes : un mode manuel – permettant de debug – contrôlé par un bouton avec un circuit de debounce à base de timer 555 ; ainsi qu’un mode normal utilisant une oscillateur à quartz à une fréquence de 10 kHz.   
De plus, il n’y a pas de signal de contrôle permettant de stopper l’horloge, cela sera fait en créant une boucle infinie dans le code.

### La logique de calcul
#### Les registres

L’ordinateur est constitué de quatre registres :

| Nom                     | Sigle | Utilité                                                                                       |
| ----------------------- | ----- | --------------------------------------------------------------------------------------------- |
| Program Counter         | PC    | Registre contenant le pointeur permettant de garder une trace de l’instruction qui s’éxécute. |
| Memory Address Register | MAR   | Registre contenant le curseur/pointeur de la mémoire.                                         |
| Loop Address Register   | LAR   | Registre contenant le curseur de la mémoire servant de cache aux emplacements des boucles.    |
| Loop Counter            | LPC   | Permet de compter le nombre de boucle rencontrées lorsque l’on cherche l’instruction opposée. |

Le `LAR` et le `MAR` sont reliés via un multiplexeur au bus d’adresse de la mémoire RAM elle-même reliée au bus de données.      
Tous les registres de cet ordinateur sont basés sur un circuit intégré de type 74LS169 avec trois différents signaux de contrôles :
- **CO** : permet d’activer le comptage, décrémentation par défaut
- **UP** : permet d’incrémenter lors d’un comptage
- **LO**/**RESET** : permet de mettre une valeur dans le registre. Cette valeur étant 0 lorsque le signal est nommé RESET

#### L’ALU
L’`ALU` n’est en réalité rien d’autre qu'un registre relié au bus de données et permet d’incrémenter ou décrémenter sa valeur interne. À des fins d’optimisation, la valeur en RAM y est stocké que lorsque nous cherchons à changer de cellule mémoire et que sa valeur a été modifiée entre-temps. De même, sa valeur est retournée en RAM seulement si il y a eu modification et que lorsque l’on modifie le curseur mémoire.

#### La RAM
La RAM a une organisation de 8k x 12. Cependant, seuls 4k sont adressables, en effet, la mémoire est séparée en deux entre la mémoire utilisable et la mémoire de cache pour l’optimisation des boucles.      
Actuellement, le circuit intégré retenu est le AS6C6264-55PIN, ayant une organisation de 8k x 8 donc devant être doublé pour atteindre les 12 bits de données. Ses signaux de contrôles sont les suivants :
- **OE** : permet de mettre la valeur de la cellule actuelle sur le bus de données
- **WE** : permet de stocker la valeur du bus de données dans la cellule actuelle

De plus, il existe deux registres d’adressage différent : un utilisé pour le curseur de l’utilisateur (`MAR`) et un utilisé pour le cache des boucles (`LAR`). Les deux permettent d’adresser la RAM successivement via un multiplexer. Le `MAR` est relié à l’adresse `0x00` du multiplexer et le `LAR` à l’adresse `0x01`.

#### Les entrées/sorties
Plusieurs périphériques peuvent faire office d’entrée/sortie, une seule et même interface est exposée, controlée par ces signaux:
- Pour la sortie :
  - **OUT** : transmet la valeur de la cellule actuelle
  - **S0**  : sélectionne soit la valeur de l'ALU (pour si la valeur a été changée), soit la valeur du bus (pour si la valeur a été inchangée)
- Pour l’entrée :
  - **S0** : Signal correspondant à la sélection via le multiplexer du bus de l’adresse `0x01`

#### Le bus de données
Le bus de données est relié à la RAM, l’ALU, le PC ainsi que les entrées/sorties. Il est par défaut reliée à la masse et est ainsi utilisé pour réinitialiser les registres et la RAM.
Il y a deux seuls moyens d’y mettre une valeur : soit par la sortie de la RAM soit par un multiplexer où sont reliés différents éléments de l’ordinateur à différentes adresses :
- `0x00` : **PC**
- `0x01` : **IO**
- `0x02` : **ALU**

#### Les Zero Checkers
Les "Zero Checkers" permettent de vérifier si une valeur est nulle ou pas.   
L’ordinateur en possède deux : un pour la valeur du bus, son résultat étant enregistré dans un registre de flag quand nécessaire et un deuxième pour la valeur du `LPC`, son résultat étant directement utilisé pour déterminer la micro-instruction.

### La logique de contrôle
La logique de contrôle réunit tous les éléments nécessaire à la détermination des opérations que la logique de calcul doit effectuer.   
Nous avons donc pour cela une ROM principale avec 1k cellules de 25 bits. 1k cellules, soit 10 bits, correspondent à quatre éléments résumé dans le tableau ci dessous :

| Element           | Bit Description            | Bit Index |
| :---------------: | -------------------------- | --------- |
| **Program ROM**   |                            | #0        |
|                   |                            | #1        |
|                   |                            | #2        |
| **Phase**         |                            | #3        |
|                   |                            | #4        |
| **Flag Register** | **SLF** : Start Loop Flag  | #5        |
|                   | **ELF** : End Loop Flag    | #6        |
|                   | **ACF** : ALU Changed Flag | #7        |
|                   | **BZF** : Bus Zero Hold    | #8        |
|                   | **RF** : Reset Flag        | #9        |
| **Zero Checker**  | **LFF** : Loop Found Flag  | #10       |

Voici une brève explication de chaque élément :

##### Program ROM
La ROM qui contient le programme à exécuter. Son contenu peut être changé via le programmateur de ROM dont une partie de ce projet est aussi dédié. Les instructions défilent suivant la valeur du PC.

##### Phase
Registre de 2-bit qui bascule entre les valeurs 0b00 et 0b10 pour les instructions nécessitant plusieurs cycles d’horloge : au maximum trois cycles sont utiles pour éxécuter n’importe quelle instruction.

##### Flag Register
Registre de flag indiquant certains états interne de l’ordinateur.
Voici une description de chaque flag :
- **`SLF`** : permet d’indiquer à l’ordinateur que nous sommes à la recherche du début d’une boucle, soit à une instruction BF '['
- **`ELF`** : inversement, permet d’indiquer que nous cherchons la fin d’une boucle, soit ']'
- **`ACF`** : permet d’indiquer quand la valeur de l’ALU a été changé et donc s’il est nécessaire de mettre à jour la valeur de l’ALU ou de la cellule en RAM
- **`BZF`** : permet d’indiquer à l’ordinateur si la valeur du bus est à zéro. Nécessite un signal de contrôle car ce flag est en réalité stocké dans un registre
- **`RF`** : permet d’indiquer à l’ordinateur que nous sommes en phase de (ré)initialisation. Il est activé lors de l’appuie d’un bouton et est réintialisé lorsque la valeur du `MAR` est à sa valeur max `0xFFF` (< TODO: Revoir ce fonctionnement, système plutôt chaotique sur Logisim pour réussir à le faire fonctionner correctement...)

##### Zero Checker 
Permet d’indiquer à l’ordinateur quand le LPC est à zéro. (Réalisé à partir de portes ET and d'un inverseur à la toute fin)

### Les séquences d’instruction
#### Fetch Cycle

Le « Fetch Cycle » est l’opération qui consiste à récupérer l’instruction suivante dans le but de la décoder puis l’exécuter. Elle est donc réalisée après chaque instruction et consiste à réinitialiser la phase, et incrémenter le `PC`.

#### La réinitialisation de l’ordinateur

La réinitialisation de l’ordinateur (qui est aussi son initialisation) consiste à mettre tous les registres ainsi que le contenu de la RAM à zéro.    
Cette réinitialisation est démarrée à l'appuie du bouton de reset : le flag **`RF`** est activé.   

La première étape consiste à initialiser le PC, le MAR, le LPC et le registre de Phase et de Flag à 0 via le signal de contrôle **`LO`**. Ensuite une séquence d'instruction est lancée:
1. **`PC`** → **`LAR`** et **`Bus`** → **`Regular RAM`**
2. **`Bus`** → **`Loop RAM`** et incrémenter **`MAR`**
   
Cette séquence s'arrête lorsque le **`MAR`** est à sa valeur maximale (4095) : le flag **`RF`** est désactivé et le **`MAR`** une dernière fois incrémenté pour revenir à 0.

(TODO: Revoir ce fonctionnement, système plutôt chaotique sur Logisim pour réussir à le faire fonctionner correctement...))

#### La gestion des boucles

La gestion des boucles n'est pas aussi triviale que le reste.
L'ordinateur réserve une partie de la mémoire vive comme cache pour enregistrer où sont placé les instructions de boucle.    

Chaque fois qu'une instruction de boucle (que ça soit `[` ou `]`), l'adresse de l'instruction courante est stockée dans le `LAR`.
Ensuite, en fonction de la valeur de la cellule courante, on continue l'exécution ou on cherche l'instruction de boucle opposé.
A partir de là, deux possibilités :     
* Il y a une adresse stockée dans la RAM à l'adresse du `LAR` : on la transmet au `PC` pour continuer l'éxécution à partir de là
* Il n'y a pas d'adresse stockée (la valeur est 0) : l'ordinateur va rentrer dans un mode permettant d'aller chercher l'instruction correspondante. Par exemple si `]` a été rencontré, la ROM va être parcourue à l'envers, chaque `]` supplémentaire rencontré va augmenter un compteur, mais à chaque `[` rencontré, soit le `LPC` est nul, on a trouvé la correspondance \o/ On stocke donc l'adresse de cette instruction dans la `Loop RAM` ; soit ce n'est pas le cas et on le décrémente puis on continue de chercher

> /!\ Cette gestion possède une limitation : le code BF ne peut pas commencer par une boucle dès la première instruction, pour cela il faut utiliser une instruction fantôme en premier lieu comme `><` (qui nécessitera moins de cycles d'horloges que `+-` par exemple)